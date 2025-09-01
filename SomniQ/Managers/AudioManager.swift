import Foundation
import AVFoundation
import SwiftUI
import SoundAnalysis
import Combine

// MARK: - Sleep Sound Detection Models
struct DetectedSound: Identifiable, Codable {
    let id = UUID()
    let soundName: String
    let confidence: Double
    let timestamp: Date
    
    init(soundName: String, confidence: Double, timestamp: Date = Date()) {
        self.soundName = soundName
        self.confidence = confidence
        self.timestamp = timestamp
    }
}

struct RecordingSummary: Codable {
    let recordingDate: Date
    let duration: TimeInterval
    let detectedSounds: [DetectedSound]
    let fileURL: URL
    
    var mostCommonSound: String? {
        let soundCounts = Dictionary(grouping: detectedSounds, by: { $0.soundName })
            .mapValues { $0.count }
        return soundCounts.max(by: { $0.value < $1.value })?.key
    }
    
    var totalDetections: Int {
        detectedSounds.count
    }
}

// MARK: - Sound Analysis Manager
class SoundAnalysisManager: NSObject, ObservableObject {
    @Published var currentDetections: [DetectedSound] = []
    @Published var isAnalyzing = false
    
    var streamAnalyzer: SNAudioStreamAnalyzer?
    private var classifySoundRequest: SNClassifySoundRequest?
    private var allDetections: [DetectedSound] = []
    
    override init() {
        super.init()
        setupSoundClassifier()
    }
    
    private func setupSoundClassifier() {
        do {
            // Use Apple's built-in sound classifier
            print("🔧 Setting up sound classifier...")
            classifySoundRequest = try SNClassifySoundRequest(classifierIdentifier: .version1)
            
            // Configure the request
            classifySoundRequest?.windowDuration = CMTime(seconds: 1.0, preferredTimescale: 1000)
            classifySoundRequest?.overlapFactor = 0.5
            
            print("✅ Sound classifier setup successful")
            print("📋 Available sound classifications: \(classifySoundRequest?.knownClassifications ?? [])")
            print("📋 Window duration: \(classifySoundRequest?.windowDuration ?? CMTime.zero)")
            print("📋 Overlap factor: \(classifySoundRequest?.overlapFactor ?? 0)")
            print("📋 Classifier identifier: \(SNClassifierIdentifier.version1)")
        } catch {
            print("❌ Failed to setup sound classifier: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
        }
    }
    
    func startAnalysis(with audioEngine: AVAudioEngine) {
        guard let request = classifySoundRequest else {
            print("❌ Sound classifier not available")
            return
        }
        
        do {
            let format = audioEngine.inputNode.outputFormat(forBus: 0)
            print("🎵 Audio format: \(format)")
            print("🎵 Sample rate: \(format.sampleRate)")
            print("🎵 Channel count: \(format.channelCount)")
            
            streamAnalyzer = SNAudioStreamAnalyzer(format: format)
            try streamAnalyzer?.add(request, withObserver: self)
            
            isAnalyzing = true
            allDetections.removeAll()
            currentDetections.removeAll()
            
            print("✅ Sound analysis started successfully")
            print("📋 Available classifications: \(request.knownClassifications)")
            print("📋 Request type: \(type(of: request))")
            print("📋 Observer set: \(self)")
        } catch {
            print("❌ Failed to start sound analysis: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
        }
    }
    
    func stopAnalysis() {
        streamAnalyzer = nil
        isAnalyzing = false
        print("Sound analysis stopped")
    }
    
    func getRecordingSummary(duration: TimeInterval, fileURL: URL) -> RecordingSummary {
        return RecordingSummary(
            recordingDate: Date(),
            duration: duration,
            detectedSounds: allDetections,
            fileURL: fileURL
        )
    }
}

// MARK: - Sound Analysis Observer
extension SoundAnalysisManager: SNResultsObserving {
    func request(_ request: SNRequest, didProduce result: SNResult) {
        print("🔍 Observer called with result type: \(type(of: result))")
        
        guard let classificationResult = result as? SNClassificationResult else { 
            print("❌ Received non-classification result: \(type(of: result))")
            return 
        }
        
        let timestamp = classificationResult.timeRange.start.seconds
        print("Received classification result at timestamp: \(timestamp)")
        
        // Get top classifications with confidence > 0.5 (50% threshold)
        let topClassifications = classificationResult.classifications
            .filter { $0.confidence > 0.5 }
            .sorted { $0.confidence > $1.confidence }
            .prefix(3)
        
        print("Found \(topClassifications.count) classifications above threshold")
        
        for classification in topClassifications {
            print("Detected: \(classification.identifier) with confidence: \(classification.confidence)")
            
            let detectedSound = DetectedSound(
                soundName: classification.identifier,
                confidence: Double(classification.confidence),
                timestamp: Date().addingTimeInterval(timestamp)
            )
            
            DispatchQueue.main.async {
                self.allDetections.append(detectedSound)
                
                // Update current detections (keep last 10)
                self.currentDetections.append(detectedSound)
                if self.currentDetections.count > 10 {
                    self.currentDetections.removeFirst()
                }
                
                print("Updated detections. Total: \(self.allDetections.count), Current: \(self.currentDetections.count)")
            }
        }
    }
    
    func request(_ request: SNRequest, didFailWithError error: Error) {
        print("❌ Sound analysis failed: \(error)")
        print("❌ Error details: \(error.localizedDescription)")
    }
    
    func requestDidComplete(_ request: SNRequest) {
        print("✅ Sound analysis completed")
    }
}

// MARK: - Audio Manager
class AudioManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var hasPermission = false
    @Published var detectedSounds: [DetectedSound] = []
    @Published var recordingSummary: RecordingSummary?
    
    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var recordingTimer: Timer?
    private var recordingStartTime: Date?
    private var outputFileURL: URL?
    private let soundAnalysisManager = SoundAnalysisManager()
    
    override init() {
        super.init()
        checkPermission()
        setupSoundAnalysisObserver()
    }
    
    private func setupSoundAnalysisObserver() {
        soundAnalysisManager.$currentDetections
            .receive(on: DispatchQueue.main)
            .assign(to: &$detectedSounds)
    }
    
    // MARK: - Permission
    func checkPermission() {
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .granted:
                hasPermission = true
            case .denied:
                hasPermission = false
            case .undetermined:
                requestPermission()
            @unknown default:
                hasPermission = false
            }
        } else {
            switch AVAudioSession.sharedInstance().recordPermission {
            case .granted:
                hasPermission = true
            case .denied:
                hasPermission = false
            case .undetermined:
                requestPermission()
            @unknown default:
                hasPermission = false
            }
        }
    }
    
    func requestPermission() {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    self?.hasPermission = granted
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    self?.hasPermission = granted
                }
            }
        }
    }
    
    // MARK: - Recording
    func startRecording() {
        guard hasPermission else {
            requestPermission()
            return
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            
            let engine = AVAudioEngine()
            let inputNode = engine.inputNode
            let format = inputNode.outputFormat(forBus: 0)
            
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let recordingName = "sleep_recording_\(Date().timeIntervalSince1970).caf"
            let recordingURL = documentsPath.appendingPathComponent(recordingName)
            outputFileURL = recordingURL
            audioFile = try AVAudioFile(forWriting: recordingURL, settings: format.settings)
            
            // Start sound analysis
            soundAnalysisManager.startAnalysis(with: engine)
            
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] (buffer, time) in
                guard let self = self else { return }
                do {
                    try self.audioFile?.write(from: buffer)
                    
                    // Feed audio to sound analysis
                    try self.soundAnalysisManager.streamAnalyzer?.analyze(buffer, atAudioFramePosition: time.sampleTime)
                    
                    // Debug: Check if we're getting audio data
                    if let channelData = buffer.floatChannelData?[0] {
                        let frameLength = Int(buffer.frameLength)
                        let audioData = Array(UnsafeBufferPointer(start: channelData, count: frameLength))
                        let rms = sqrt(audioData.reduce(0) { $0 + $1 * $1 } / Float(audioData.count))
                        
                        if rms > 0.01 { // Only print when there's significant audio
                            print("🎤 Audio level: \(rms)")
                        }
                    }
                } catch {
                    print("❌ Failed to write buffer: \(error)")
                }
            }
            
            engine.prepare()
            try engine.start()
            
            audioEngine = engine
            isRecording = true
            recordingStartTime = Date()
            startTimer()
        } catch {
            print("Failed to start AVAudioEngine recording: \(error)")
        }
    }
    
    func stopRecording() -> URL? {
        guard let engine = audioEngine else { return nil }
        
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        
        let url = outputFileURL
        let duration = recordingDuration
        
        // Stop sound analysis and get final summary
        soundAnalysisManager.stopAnalysis()
        
        // Create recording summary with final data
        if let fileURL = url {
            recordingSummary = soundAnalysisManager.getRecordingSummary(duration: duration, fileURL: fileURL)
            print("Created recording summary with \(recordingSummary?.detectedSounds.count ?? 0) detections")
        }
        
        isRecording = false
        stopTimer()
        
        audioFile = nil
        outputFileURL = nil
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
        
        return url
    }
    
    // MARK: - Timer
    private func startTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.recordingStartTime else { return }
            self.recordingDuration = Date().timeIntervalSince(startTime)
        }
    }
    
    private func stopTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        recordingDuration = 0
        recordingStartTime = nil
    }
    
    // MARK: - Playback
    func playRecording(url: URL) {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
            
            let player = try AVAudioPlayer(contentsOf: url)
            player.play()
        } catch {
            print("Failed to play recording: \(error)")
        }
    }
    
    // MARK: - Formatting
    func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
} 
