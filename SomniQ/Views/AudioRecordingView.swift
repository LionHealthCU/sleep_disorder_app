import SwiftUI
import AVFoundation

struct AudioRecordingView: View {
    @ObservedObject var dataManager: DataManager
    @StateObject private var audioManager = AudioManager()
    @Environment(\.dismiss) private var dismiss
    @State private var showingPermissionAlert = false
    @State private var showingSaveAlert = false
    @State private var recordingName = ""
    
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
                    
                    Text("Place your device near your bed to capture sleep sounds. This can help identify patterns like snoring, gasping, or other sleep-related sounds.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Recording controls
                VStack(spacing: 20) {
                    if !audioManager.hasPermission {
                        VStack(spacing: 12) {
                            Text("Microphone Permission Required")
                                .font(.headline)
                                .foregroundColor(.red)
                            
                            Text("SomniQ needs access to your microphone to record sleep sounds.")
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
                
                // Recent recordings
                if !dataManager.audioRecordings.isEmpty {
                    VStack(spacing: 16) {
                        Text("Recent Recordings")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(dataManager.audioRecordings.prefix(5)) { recording in
                                    RecordingRow(recording: recording, audioManager: audioManager)
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                    }
                }
            }
            .padding()
            .navigationTitle("Audio Recording")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Save Recording", isPresented: $showingSaveAlert) {
            TextField("Recording name", text: $recordingName)
            Button("Save") {
                saveRecording()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter a name for this recording")
        }
        .alert("Microphone Permission", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable microphone access in Settings to record audio.")
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
        guard let recordingURL = audioManager.stopRecording() else { return }
        
        let recording = AudioRecording(
            date: Date(),
            duration: audioManager.recordingDuration,
            fileURL: recordingURL
        )
        
        dataManager.addAudioRecording(recording)
        dismiss()
    }
}

struct RecordingRow: View {
    let recording: AudioRecording
    let audioManager: AudioManager
    @State private var isPlaying = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(recording.date, formatter: dateFormatter)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(audioManager.formatDuration(recording.duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: playRecording) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func playRecording() {
        if isPlaying {
            isPlaying = false
            // Stop playback logic would go here
        } else {
            isPlaying = true
            audioManager.playRecording(url: recording.fileURL)
            
            // Simulate playback ending
            DispatchQueue.main.asyncAfter(deadline: .now() + recording.duration) {
                isPlaying = false
            }
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

#Preview {
    AudioRecordingView(dataManager: DataManager())
} 