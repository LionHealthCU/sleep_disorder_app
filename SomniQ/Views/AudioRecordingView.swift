import SwiftUI
import AVFoundation

struct AudioRecordingView: View {
    @ObservedObject var dataManager: DataManager
    @StateObject private var audioManager = AudioManager()
    @Environment(\.dismiss) private var dismiss
    @State private var showingPermissionAlert = false
    @State private var showingSaveAlert = false
    @State private var recordingName = ""
    @State private var showingSummary = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: audioManager.isRecording ? "mic.fill" : "mic")
                        .font(.system(size: 60))
                        .foregroundColor(audioManager.isRecording ? .red : .blue)
                        .scaleEffect(audioManager.isRecording ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: audioManager.isRecording)
                    
                    Text(audioManager.isRecording ? "Recording..." : "Ready to Record")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    if audioManager.isRecording {
                        Text(audioManager.formatDuration(audioManager.recordingDuration))
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                }
                
                // Instructions
                VStack(spacing: 12) {
                    Text("Sleep Audio Recording")
                        .font(.headline)
                    
                    Text("Place your device near your bed to capture sleep sounds. The app will automatically detect and classify sounds like snoring, breathing, and other sleep-related audio.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Real-time Sound Detection
                if audioManager.isRecording {
                    RealTimeSoundDetectionView(audioManager: audioManager)
                }
                
                Spacer()
                
                // Recording controls
                VStack(spacing: 20) {
                    if !audioManager.hasPermission {
                        VStack(spacing: 12) {
                            Text("Microphone Permission Required")
                                .font(.headline)
                                .foregroundColor(.red)
                            
                            Text("SomniQ needs access to your microphone to record and analyze sleep sounds.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Button("Grant Permission") {
                                audioManager.requestPermission()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    } else {
                        HStack(spacing: 30) {
                            if !audioManager.isRecording {
                                Button(action: startRecording) {
                                    VStack(spacing: 8) {
                                        Image(systemName: "record.circle")
                                            .font(.system(size: 50))
                                            .foregroundColor(.red)
                                        
                                        Text("Start Recording")
                                            .font(.headline)
                                            .foregroundColor(.red)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            } else {
                                Button(action: stopRecording) {
                                    VStack(spacing: 8) {
                                        Image(systemName: "stop.circle")
                                            .font(.system(size: 50))
                                            .foregroundColor(.red)
                                        
                                        Text("Stop Recording")
                                            .font(.headline)
                                            .foregroundColor(.red)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                
                // Show summary button if recording is complete
                if let summary = audioManager.recordingSummary {
                    Button("View Recording Summary") {
                        showingSummary = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .navigationTitle("Audio Recording")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Microphone Permission", isPresented: $showingPermissionAlert) {
                Button("Settings") {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Please enable microphone access in Settings to record sleep sounds.")
            }
            .alert("Save Recording", isPresented: $showingSaveAlert) {
                TextField("Recording Name", text: $recordingName)
                Button("Save") {
                    saveRecording()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Enter a name for your sleep recording.")
            }
            .sheet(isPresented: $showingSummary) {
                if let summary = audioManager.recordingSummary {
                    RecordingSummaryView(summary: summary)
                }
            }
        }
    }
    
    private func startRecording() {
        if audioManager.hasPermission {
            audioManager.startRecording()
        } else {
            showingPermissionAlert = true
        }
    }
    
    private func stopRecording() {
        if let recordingURL = audioManager.stopRecording() {
            recordingName = "Sleep Recording \(Date().formatted(date: .abbreviated, time: .shortened))"
            showingSaveAlert = true
        }
    }
    
    private func saveRecording() {
        guard let recordingSummary = audioManager.recordingSummary else { 
            print("❌ No recording summary found")
            return 
        }
        
        // Create AudioRecording from RecordingSummary (this has all the final data)
        let recording = AudioRecording(from: recordingSummary)
        
        print("💾 Saving recording from summary: \(recording.duration)s duration, \(recording.totalDetections) sounds detected")
        dataManager.addAudioRecording(recording)
        dismiss()
    }
}

// MARK: - Real-time Sound Detection View
struct RealTimeSoundDetectionView: View {
    @ObservedObject var audioManager: AudioManager
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Live Sound Detection")
                .font(.headline)
                .foregroundColor(.primary)
            
            if audioManager.detectedSounds.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "ear")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("Listening for sounds...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                // Current detections
                VStack(spacing: 12) {
                    ForEach(audioManager.detectedSounds.suffix(3)) { sound in
                        HStack {
                            Image(systemName: soundIcon(for: sound.soundName))
                                .foregroundColor(soundColor(for: sound.soundName))
                                .font(.title3)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(sound.soundName.capitalized)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text("\(Int(sound.confidence * 100))% confidence")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(sound.timestamp, style: .time)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    private func soundIcon(for soundName: String) -> String {
        let lowercased = soundName.lowercased()
        if lowercased.contains("snore") || lowercased.contains("breathing") {
            return "lungs.fill"
        } else if lowercased.contains("speech") || lowercased.contains("talk") {
            return "person.wave.2"
        } else if lowercased.contains("music") {
            return "music.note"
        } else if lowercased.contains("silence") {
            return "speaker.slash"
        } else {
            return "waveform"
        }
    }
    
    private func soundColor(for soundName: String) -> Color {
        let lowercased = soundName.lowercased()
        if lowercased.contains("snore") || lowercased.contains("breathing") {
            return .orange
        } else if lowercased.contains("speech") || lowercased.contains("talk") {
            return .blue
        } else if lowercased.contains("music") {
            return .purple
        } else if lowercased.contains("silence") {
            return .gray
        } else {
            return .green
        }
    }
}

// MARK: - Recording Summary View
struct RecordingSummaryView: View {
    let summary: RecordingSummary
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Recording Summary")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(summary.recordingDate, style: .date)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Statistics
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatCard(title: "Duration", value: formatDuration(summary.duration), icon: "clock", color: .blue)
                        StatCard(title: "Detections", value: "\(summary.totalDetections)", icon: "waveform", color: .green)
                        StatCard(title: "Most Common", value: summary.mostCommonSound?.capitalized ?? "None", icon: "chart.bar", color: .orange)
                        StatCard(title: "Unique Sounds", value: "\(Set(summary.detectedSounds.map { $0.soundName }).count)", icon: "list.bullet", color: .purple)
                    }
                    
                    // Sound Timeline
                    if !summary.detectedSounds.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Detected Sounds")
                                .font(.headline)
                            
                            LazyVStack(spacing: 8) {
                                ForEach(summary.detectedSounds.suffix(20)) { sound in
                                    HStack {
                                        Image(systemName: soundIcon(for: sound.soundName))
                                            .foregroundColor(soundColor(for: sound.soundName))
                                            .font(.title3)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(sound.soundName.capitalized)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            
                                            Text("\(Int(sound.confidence * 100))% confidence")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Text(sound.timestamp, style: .time)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else {
            return String(format: "%dm %ds", minutes, seconds)
        }
    }
    
    private func soundIcon(for soundName: String) -> String {
        let lowercased = soundName.lowercased()
        if lowercased.contains("snore") || lowercased.contains("breathing") {
            return "lungs.fill"
        } else if lowercased.contains("speech") || lowercased.contains("talk") {
            return "person.wave.2"
        } else if lowercased.contains("music") {
            return "music.note"
        } else if lowercased.contains("silence") {
            return "speaker.slash"
        } else {
            return "waveform"
        }
    }
    
    private func soundColor(for soundName: String) -> Color {
        let lowercased = soundName.lowercased()
        if lowercased.contains("snore") || lowercased.contains("breathing") {
            return .orange
        } else if lowercased.contains("speech") || lowercased.contains("talk") {
            return .blue
        } else if lowercased.contains("music") {
            return .purple
        } else if lowercased.contains("silence") {
            return .gray
        } else {
            return .green
        }
    }
}




#Preview {
    AudioRecordingView(dataManager: DataManager())
} 