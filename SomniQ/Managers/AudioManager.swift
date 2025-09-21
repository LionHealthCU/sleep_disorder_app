import Foundation
import AVFoundation
import SwiftUI
import SoundAnalysis
import Combine
import FirebaseStorage
import FirebaseAuth

// MARK: - Sleep Sound Detection Models
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
    
    // MARK: - Alert Processing Data
    @Published var lastFrameData: (time: TimeInterval, probs: [String: Double], top2: (String, Double, String, Double))?
    
    override init() {
        super.init()
        setupSoundClassifier()
    }
    
    private func setupSoundClassifier() {
        do {
            // Use Apple's built-in sound classifier
            print("Setting up sound classifier...")
            classifySoundRequest = try SNClassifySoundRequest(classifierIdentifier: .version1)
            
            // Configure the request
            classifySoundRequest?.windowDuration = CMTime(seconds: 1.0, preferredTimescale: 1000)
            classifySoundRequest?.overlapFactor = 0.5
            
            print("Sound classifier setup successful")
            print("📋 Available sound classifications: \(classifySoundRequest?.knownClassifications ?? [])")
            print("📋 Window duration: \(classifySoundRequest?.windowDuration ?? CMTime.zero)")
            print("📋 Overlap factor: \(classifySoundRequest?.overlapFactor ?? 0)")
            print("📋 Classifier identifier: \(SNClassifierIdentifier.version1)")
        } catch {
            print("Failed to setup sound classifier: \(error)")
            print("Error details: \(error.localizedDescription)")
        }
    }
    
    func startAnalysis(with audioEngine: AVAudioEngine) {
        guard let request = classifySoundRequest else {
            print("Sound classifier not available")
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
            
            print("Sound analysis started successfully")
            print("📋 Available classifications: \(request.knownClassifications)")
            print("📋 Request type: \(type(of: request))")
            print("📋 Observer set: \(self)")
        } catch {
            print("Failed to start sound analysis: \(error)")
            print("Error details: \(error.localizedDescription)")
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
            print("Received non-classification result: \(type(of: result))")
            return 
        }
        
        let timestamp = classificationResult.timeRange.start.seconds
        print("Received classification result at timestamp: \(timestamp)")
        
        // Get ALL classifications for alert processing (not just high confidence ones)
        let allClassifications = classificationResult.classifications
            .sorted { $0.confidence > $1.confidence }
        
        // Convert to probability dictionary for alert processing
        var probs: [String: Double] = [:]
        for classification in allClassifications {
            probs[classification.identifier] = Double(classification.confidence)
        }
        
        // Get top 2 classifications for uncertainty calculation
        let top2 = allClassifications.count >= 2 ? 
            (allClassifications[0].identifier, Double(allClassifications[0].confidence),
             allClassifications[1].identifier, Double(allClassifications[1].confidence)) :
            (allClassifications[0].identifier, Double(allClassifications[0].confidence),
             "unknown", 0.0)
        
        // Store frame data for alert processing
        DispatchQueue.main.async {
            self.lastFrameData = (time: timestamp, probs: probs, top2: top2)
        }
        
        // Continue with existing sound detection logic (for UI display)
        // Get top classifications with confidence > 0.5 (50% threshold)
        let topClassifications = allClassifications
            .filter { $0.confidence > 0.5 }
            .prefix(3)
        
        print("Found \(topClassifications.count) classifications above threshold")
        
        for classification in topClassifications {
            print("Detected: \(classification.identifier) with confidence: \(classification.confidence)")
            
            let detectedSound = DetectedSound(
                soundName: classification.identifier,
                confidence: Float(classification.confidence),
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
        print("Sound analysis failed: \(error)")
        print("❌ Error details: \(error.localizedDescription)")
    }
    
    func requestDidComplete(_ request: SNRequest) {
        print("Sound analysis completed")
    }
}

// MARK: - Audio Manager
class AudioManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var hasPermission = false
    @Published var detectedSounds: [DetectedSound] = []
    @Published var recordingSummary: RecordingSummary?
    @Published var uploadProgress: Double = 0.0
    @Published var isUploading = false
    @Published var uploadError: String?
    
    // MARK: - Alert System Properties
    @Published var activeAlerts: [AlertEvent] = []
    @Published var alertHistory: [AlertEvent] = []
    
    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var recordingTimer: Timer?
    private var recordingStartTime: Date?
    private var outputFileURL: URL?
    private let soundAnalysisManager = SoundAnalysisManager()
    private let alertProcessor = AlertProcessor(profile: .balanced)
    private let storage = Storage.storage()
    
    override init() {
        super.init()
        checkPermission()
        setupSoundAnalysisObserver()
        setupAlertObserver()
    }
    
    private func setupSoundAnalysisObserver() {
        soundAnalysisManager.$currentDetections
            .receive(on: DispatchQueue.main)
            .assign(to: &$detectedSounds)
    }
    
    private func setupAlertObserver() {
        alertProcessor.$activeAlerts
            .receive(on: DispatchQueue.main)
            .assign(to: &$activeAlerts)
        
        alertProcessor.$alertHistory
            .receive(on: DispatchQueue.main)
            .assign(to: &$alertHistory)
        
        // Observe frame data from SoundAnalysisManager and process alerts
        soundAnalysisManager.$lastFrameData
            .receive(on: DispatchQueue.main)
            .compactMap { $0 } // Only process non-nil frame data
            .sink { [weak self] frameData in
                let firedAlerts = self?.alertProcessor.processFrame(
                    time: frameData.time,
                    probs: frameData.probs,
                    top2: frameData.top2
                ) ?? []
                
                if !firedAlerts.isEmpty {
                    print("🚨 Alerts fired: \(firedAlerts)")
                }
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
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
            
            // Reset alerts for new recording session
            resetAlerts()
            
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
                    print("Failed to write buffer: \(error)")
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
    
    // MARK: - Firebase Storage Upload
    func uploadAudioToFirebase(localFileURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "AudioManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        isUploading = true
        uploadProgress = 0.0
        uploadError = nil
        
        // Create a unique filename with timestamp and user ID
        let timestamp = Int(Date().timeIntervalSince1970)
        let fileName = "sleep_recording_\(user.uid)_\(timestamp).caf"
        let storageRef = storage.reference().child("audio_recordings/\(user.uid)/\(fileName)")
        
        // Create metadata for the file
        let metadata = StorageMetadata()
        metadata.contentType = "audio/x-caf"
        metadata.customMetadata = [
            "recordingDate": ISO8601DateFormatter().string(from: Date()),
            "userId": user.uid,
            "duration": String(recordingDuration)
        ]
        
        // Upload the file
        let uploadTask = storageRef.putFile(from: localFileURL, metadata: metadata) { [weak self] metadata, error in
            DispatchQueue.main.async {
                self?.isUploading = false
                
                if let error = error {
                    self?.uploadError = error.localizedDescription
                    completion(.failure(error))
                    return
                }
                
                // Get the download URL
                storageRef.downloadURL { url, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            self?.uploadError = error.localizedDescription
                            completion(.failure(error))
                        } else if let downloadURL = url {
                            print("Audio file uploaded successfully to Firebase Storage")
                            print("Download URL: \(downloadURL.absoluteString)")
                            completion(.success(downloadURL.absoluteString))
                        }
                    }
                }
            }
        }
        
        // Monitor upload progress
        uploadTask.observe(.progress) { [weak self] snapshot in
            DispatchQueue.main.async {
                if let progress = snapshot.progress {
                    self?.uploadProgress = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                    print("Upload progress: \(Int(self?.uploadProgress ?? 0 * 100))%")
                }
            }
        }
        
        // Handle upload state changes
        uploadTask.observe(.success) { [weak self] snapshot in
            DispatchQueue.main.async {
                print("Upload completed successfully")
            }
        }
        
        uploadTask.observe(.failure) { [weak self] snapshot in
            DispatchQueue.main.async {
                if let error = snapshot.error {
                    self?.uploadError = error.localizedDescription
                    print("Upload failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Combined Recording and Upload
    func stopRecordingAndUpload(completion: @escaping (Result<String, Error>) -> Void) {
        guard let localFileURL = stopRecording() else {
            completion(.failure(NSError(domain: "AudioManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to stop recording"])))
            return
        }
        
        // Upload to Firebase Storage while keeping local file
        uploadAudioToFirebase(localFileURL: localFileURL) { result in
            switch result {
            case .success(let downloadURL):
                print("Recording saved locally and uploaded to Firebase Storage")
                print("Local file: \(localFileURL.path)")
                print("Firebase URL: \(downloadURL)")
                
                // Update the recording summary with Firebase URL
                if var summary = self.recordingSummary {
                    // Create a new summary with Firebase URL instead of local URL
                    let firebaseURL = URL(string: downloadURL)!
                    summary = RecordingSummary(
                        recordingDate: summary.recordingDate,
                        duration: summary.duration,
                        detectedSounds: summary.detectedSounds,
                        fileURL: firebaseURL
                    )
                    self.recordingSummary = summary
                }
                
                completion(.success(downloadURL))
            case .failure(let error):
                print("Failed to upload to Firebase Storage: \(error.localizedDescription)")
                print("Local file still available at: \(localFileURL.path)")
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Alert Management
    /// Clear a specific alert from active alerts
    /// - Parameter alertId: UUID of the alert to clear
    func clearAlert(_ alertId: UUID) {
        alertProcessor.clearAlert(alertId)
    }
    
    /// Clear all active alerts
    func clearAllAlerts() {
        alertProcessor.clearAllAlerts()
    }
    
    /// Get the highest priority active alert
    /// - Returns: The most important active alert, or nil if none
    func getTopActiveAlert() -> AlertEvent? {
        return alertProcessor.getTopActiveAlert()
    }
    
    /// Update the alert rule for a specific sound class
    /// - Parameter rule: The new AlertRule to use
    func updateAlertRule(_ rule: AlertRule) {
        alertProcessor.updateRule(rule)
    }
    
    /// Get current statistics about the alert processor
    /// - Returns: Dictionary with alert processor statistics
    func getAlertStats() -> [String: Any] {
        return alertProcessor.getStats()
    }
    
    /// Reset the alert processor (useful for starting a new recording session)
    func resetAlerts() {
        alertProcessor.reset()
    }
    
    // MARK: - Profile Management
    /// Change the sensitivity profile for the alert system
    /// - Parameter profile: The new sensitivity profile to use
    func changeSensitivityProfile(to profile: SensitivityProfile) {
        alertProcessor.changeProfile(to: profile)
        print("🎛️ [AudioManager] Sensitivity profile changed to \(profile.rawValue)")
    }
    
    /// Get the current sensitivity profile
    /// - Returns: The current sensitivity profile
    func getCurrentSensitivityProfile() -> SensitivityProfile {
        return alertProcessor.getCurrentProfile()
    }
    
    /// Get the current profile configuration
    /// - Returns: The current AlertProfile configuration
    func getCurrentProfileConfig() -> AlertProfile {
        return alertProcessor.getCurrentProfileConfig()
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
