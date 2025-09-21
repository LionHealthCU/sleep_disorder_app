import SwiftUI

// MARK: - Dark Mode Color Extensions
extension Color {
    static let sleepPrimary = Color(red: 0.29, green: 0.29, blue: 0.54) // #4A4A8A
    static let sleepSecondary = Color(red: 0.42, green: 0.45, blue: 1.0) // #6B73FF
    static let sleepDark = Color(red: 0.10, green: 0.10, blue: 0.10) // #1A1A1A
    static let sleepDarkGray = Color(red: 0.18, green: 0.18, blue: 0.18) // #2D3436
    static let sleepAccent = Color(red: 0.45, green: 0.73, blue: 1.0) // #74B9FF
    static let sleepPurple = Color(red: 0.64, green: 0.61, blue: 1.0) // #A29BFE
}

struct DashboardView: View { 
    @ObservedObject var dataManager: DataManager
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var audioManager = AudioManager()
    @State private var showingRecordAudio = false
    @State private var showingSelfReport = false
    @State private var showingHealthKit = false
    @State private var showSignOutAlert = false
    
    // MARK: - Sensitivity Profile State
    @State private var currentSensitivityProfile: SensitivityProfile = .balanced
    @State private var sensitivitySliderValue: Double = 0.5
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Custom SomniQ Title with Gradient
                    customTitleSection
                    
                    // Header with user info
                    headerSection
                    
                    // Quick stats
                    quickStatsSection
                    
                    // Central recording section (primary focus)
                    centralRecordingSection
                    
                    // Alert Sensitivity Controls
                    alertSensitivitySection
                    
                    // History access
                    historyAccessSection
                }
                .padding()
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.sleepDark, Color.sleepDarkGray]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset Setup") {
                        dataManager.resetSetup()
                    }
                    .font(.caption)
                    .foregroundColor(Color.sleepAccent)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button("Sign Out") {
                            showSignOutAlert = true
                        }
                        .font(.caption)
                        .foregroundColor(Color.sleepSecondary)
                        
                        NavigationLink(destination: DataView(dataManager: dataManager)) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundColor(Color.sleepAccent)
                        }
                    }
                }
            }
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Sign Out", role: .destructive) {
                    authManager.signOut()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
        .sheet(isPresented: $showingRecordAudio) {
            AudioRecordingView(dataManager: dataManager, audioManager: audioManager)
        }
        .sheet(isPresented: $showingSelfReport) {
            SelfReportView(dataManager: dataManager)
        }
        .sheet(isPresented: $showingHealthKit) {
            HealthKitView(dataManager: dataManager)
        }
    }
    
    private var customTitleSection: some View {
        VStack(spacing: 8) {
            HStack {
                // Moon icon with gradient
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.sleepSecondary, Color.sleepPurple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.sleepSecondary.opacity(0.4), radius: 8, x: 0, y: 4)
                
                // SomniQ text with gradient
                Text("SomniQ")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.sleepSecondary, Color.sleepPurple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: Color.sleepSecondary.opacity(0.3), radius: 6, x: 0, y: 3)
                
                Spacer()
            }
            
            // Subtitle
            Text("Sleep Sound Analytics")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 40) // Align with the text above
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Good \(timeOfDay)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    if let preferences = dataManager.userPreferences {
                        Text("Your usual sleep time: \(preferences.usualBedtime, formatter: timeFormatter) - \(preferences.usualWakeTime, formatter: timeFormatter)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                Spacer()
                
                Image(systemName: "moon.zzz.fill")
                    .font(.title)
                    .foregroundColor(Color.sleepAccent)
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.sleepDarkGray, Color.sleepPrimary.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.sleepAccent.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var quickStatsSection: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Episodes",
                value: "\(dataManager.episodes.count)",
                icon: "note.text",
                color: Color.sleepAccent
            )
            
            StatCard(
                title: "Recordings",
                value: "\(dataManager.audioRecordings.count)",
                subtitle: dataManager.audioRecordings.isEmpty ? "No recordings yet" : "\(dataManager.audioRecordings.filter { $0.totalDetections > 0 }.count) with sounds",
                icon: "mic.fill",
                color: Color.sleepPurple
            )
            
            StatCard(
                title: "This Week",
                value: "\(recentEpisodesCount)",
                icon: "calendar",
                color: Color.sleepSecondary
            )
        }
    }
    
    private var centralRecordingSection: some View {
        VStack(spacing: 24) {
            // Primary Recording Button - Large and Prominent
        VStack(spacing: 16) {
                Button(action: { showingRecordAudio = true }) {
                    VStack(spacing: 12) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                        
                        Text("Start Recording")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Capture sleep sounds")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.sleepSecondary, Color.sleepPurple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(20)
                    .shadow(color: Color.sleepSecondary.opacity(0.4), radius: 15, x: 0, y: 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.sleepAccent.opacity(0.3), lineWidth: 2)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Quick Recording Stats
                HStack(spacing: 20) {
                    if let lastRecording = dataManager.audioRecordings.last {
                        VStack(spacing: 4) {
                            Text("Last Recording")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            Text(lastRecording.date, formatter: relativeDateFormatter)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                    }
                    
                    Divider()
                        .frame(height: 30)
                        .background(.white.opacity(0.3))
                    
                    VStack(spacing: 4) {
                            Text("Sounds Today")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            Text("\(soundsDetectedToday)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                    }
                }
                .padding(.horizontal)
            }
            
            // Secondary Actions - Smaller and Less Prominent
            VStack(spacing: 12) {
                Text("Other Actions")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 16) {
                    // Self Report - Secondary
                    Button(action: { showingSelfReport = true }) {
                        VStack(spacing: 8) {
                            Image(systemName: "note.text")
                                .font(.title3)
                                .foregroundColor(Color.sleepAccent)
                            
                            Text("Self Report")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.sleepDarkGray, Color.sleepPrimary.opacity(0.2)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.sleepAccent.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Apple Health - Tertiary
                    Button(action: { showingHealthKit = true }) {
                        VStack(spacing: 8) {
                            Image(systemName: "heart.fill")
                                .font(.title3)
                                .foregroundColor(Color.sleepPurple)
                            
                            Text("Health Sync")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.sleepDarkGray, Color.sleepPrimary.opacity(0.2)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.sleepPurple.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private var historyAccessSection: some View {
        VStack(spacing: 16) {
            Text("View History")
                    .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            NavigationLink(destination: DataView(dataManager: dataManager)) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title2)
                        .foregroundColor(Color.sleepSecondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Data & Analytics")
                        .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text("View detailed charts and history")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(Color.sleepAccent)
                }
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.sleepDarkGray, Color.sleepPrimary.opacity(0.2)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.sleepSecondary.opacity(0.2), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    
    private var soundsDetectedToday: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? Date()
        
        return dataManager.audioRecordings
            .filter { recording in
                recording.date >= today && recording.date < tomorrow
            }
            .reduce(0) { $0 + $1.totalDetections }
    }
    
    private var relativeDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }
    
    private var timeOfDay: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "morning"
        case 12..<17:
            return "afternoon"
        case 17..<22:
            return "evening"
        default:
            return "night"
        }
    }
    
    private var recentEpisodesCount: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return dataManager.episodes.filter { $0.date >= weekAgo }.count
    }
    
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    // MARK: - Alert Sensitivity Section
    private var alertSensitivitySection: some View {
        VStack(spacing: 16) {
            // Section Header
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(Color.sleepAccent)
                    .font(.title3)
                
                Text("Alert Sensitivity")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Current profile indicator
                Text(currentSensitivityProfile.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(getSensitivityColor(for: currentSensitivityProfile).opacity(0.2))
                    )
                    .foregroundColor(getSensitivityColor(for: currentSensitivityProfile))
            }
            
            // Sensitivity Slider
            VStack(spacing: 12) {
                // Slider
                HStack {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.title3)
                    
                    Slider(value: $sensitivitySliderValue, in: 0...1, step: 0.25)
                        .accentColor(getSensitivityColor(for: currentSensitivityProfile))
                        .onChange(of: sensitivitySliderValue) { newValue in
                            let newProfile = SensitivityProfile.fromSliderValue(newValue)
                            if newProfile != currentSensitivityProfile {
                                currentSensitivityProfile = newProfile
                                // Update AudioManager with new profile
                                audioManager.changeSensitivityProfile(to: newProfile)
                            }
                        }
                    
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.title3)
                }
                
                // Profile Labels
                HStack {
                    Text("Very Conservative")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    Text("Balanced")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    Text("Very Sensitive")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // Profile Description
            Text(currentSensitivityProfile.description)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.sleepDarkGray, Color.sleepPrimary.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.sleepAccent.opacity(0.2), lineWidth: 1)
        )
        .onAppear {
            // Load current profile from AudioManager
            currentSensitivityProfile = audioManager.getCurrentSensitivityProfile()
            sensitivitySliderValue = currentSensitivityProfile.sliderValue
        }
    }
    
    // MARK: - Helper Methods
    private func getSensitivityColor(for profile: SensitivityProfile) -> Color {
        switch profile {
        case .veryConservative:
            return .green
        case .conservative:
            return .blue
        case .balanced:
            return .yellow
        case .sensitive:
            return .orange
        case .verySensitive:
            return .red
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let color: Color
    
    init(title: String, value: String, subtitle: String? = nil, icon: String, color: Color) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.sleepDarkGray, Color.sleepPrimary.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}


#Preview {
    DashboardView(dataManager: DataManager())
} 
