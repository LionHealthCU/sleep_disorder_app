import Foundation
import AVFoundation
import SwiftUI

class AudioManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var hasPermission = false
    
    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var recordingTimer: Timer?
    private var recordingStartTime: Date?
    private var outputFileURL: URL?
    
    // Placeholder for SAudioStreamAnalyzer
    // var streamAnalyzer: SAudioStreamAnalyzer?
    var onBuffer: ((AVAudioPCMBuffer, AVAudioTime) -> Void)?
    
    override init() {
        super.init()
        checkPermission()
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
            
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] (buffer, time) in
                guard let self = self else { return }
                do {
                    try self.audioFile?.write(from: buffer)
                } catch {
                    print("Failed to write buffer: \(error)")
                }
                // Real-time analysis placeholder
                self.onBuffer?(buffer, time)
                // self.streamAnalyzer?.analyze(buffer: buffer, at: time)
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
        isRecording = false
        stopTimer()
        let url = outputFileURL
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
