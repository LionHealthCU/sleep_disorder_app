import SwiftUI

struct DashboardView: View {
    @ObservedObject var dataManager: DataManager
    @State private var showingRecordAudio = false
    @State private var showingSelfReport = false
    @State private var showingHealthKit = false
    @State private var showingCommunity = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with user info
                    headerSection
                    
                    // Quick stats
                    quickStatsSection
                    
                    // Main action buttons
                    actionButtonsSection
                    
                    // Recent episodes
                    recentEpisodesSection
                }
                .padding()
            }
            .navigationTitle("SomniQ")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset Setup") {
                        dataManager.resetSetup()
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: DataView(dataManager: dataManager)) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                    }
                }
            }
        }
        .sheet(isPresented: $showingRecordAudio) {
            AudioRecordingView(dataManager: dataManager)
        }
        .sheet(isPresented: $showingSelfReport) {
            SelfReportView(dataManager: dataManager)
        }
        .sheet(isPresented: $showingHealthKit) {
            HealthKitView(dataManager: dataManager)
        }
        .sheet(isPresented: $showingCommunity) {
            CommunityView(dataManager: dataManager)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Good \(timeOfDay)")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    if let preferences = dataManager.userPreferences {
                        Text("Your usual sleep time: \(preferences.usualBedtime, formatter: timeFormatter) - \(preferences.usualWakeTime, formatter: timeFormatter)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "moon.zzz.fill")
                    .font(.title)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var quickStatsSection: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Episodes",
                value: "\(dataManager.episodes.count)",
                icon: "note.text",
                color: .blue
            )
            
            StatCard(
                title: "Recordings",
                value: "\(dataManager.audioRecordings.count)",
                icon: "mic.fill",
                color: .green
            )
            
            StatCard(
                title: "This Week",
                value: "\(recentEpisodesCount)",
                icon: "calendar",
                color: .orange
            )
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ActionButton(
                    title: "Record Audio",
                    subtitle: "Capture sleep sounds",
                    icon: "mic.fill",
                    color: .red
                ) {
                    showingRecordAudio = true
                }
                
                ActionButton(
                    title: "Self Report",
                    subtitle: "Log an episode",
                    icon: "note.text",
                    color: .blue
                ) {
                    showingSelfReport = true
                }
                
                ActionButton(
                    title: "Apple Health",
                    subtitle: "Connect & sync",
                    icon: "heart.fill",
                    color: .green
                ) {
                    showingHealthKit = true
                }
                
                ActionButton(
                    title: "Community",
                    subtitle: "Connect with others",
                    icon: "person.3.fill",
                    color: .purple
                ) {
                    showingCommunity = true
                }
            }
        }
    }
    
    private var recentEpisodesSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Recent Episodes")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink("View All", destination: DataView(dataManager: dataManager))
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            if dataManager.episodes.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "note.text")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    Text("No episodes recorded yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Tap 'Self Report' to log your first episode")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(Array(dataManager.episodes.prefix(3))) { episode in
                        EpisodeRow(episode: episode)
                    }
                }
            }
        }
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
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(color)
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EpisodeRow: View {
    let episode: SleepEpisode
    
    var body: some View {
        HStack {
            Image(systemName: episode.severity.icon)
                .foregroundColor(episode.severity.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(episode.severity.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(episode.date, formatter: dateFormatter)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if !episode.symptoms.isEmpty {
                Text("\(episode.symptoms.count) symptoms")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

#Preview {
    DashboardView(dataManager: DataManager())
} 