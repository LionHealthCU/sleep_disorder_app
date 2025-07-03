import SwiftUI
import HealthKit

struct HealthKitView: View {
    @ObservedObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    @State private var healthStore: HKHealthStore?
    @State private var isAuthorized = false
    @State private var showingPermissionAlert = false
    @State private var syncStatus = SyncStatus.notStarted
    @State private var lastSyncDate: Date?
    
    enum SyncStatus {
        case notStarted
        case syncing
        case completed
        case failed(String)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Connection status
                    connectionStatusSection
                    
                    // Sync options
                    if isAuthorized {
                        syncOptionsSection
                    }
                    
                    // Benefits
                    benefitsSection
                    
                    // Privacy info
                    privacySection
                }
                .padding()
            }
            .navigationTitle("Apple Health")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            setupHealthKit()
        }
        .alert("HealthKit Permission", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable HealthKit access in Settings to sync your sleep data.")
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            VStack(spacing: 8) {
                Text("Connect with Apple Health")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Sync your sleep data and get a complete picture of your health")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var connectionStatusSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: isAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isAuthorized ? .green : .red)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(isAuthorized ? "Connected" : "Not Connected")
                        .font(.headline)
                    
                    Text(isAuthorized ? "HealthKit access granted" : "HealthKit access required")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !isAuthorized {
                    Button("Connect") {
                        requestHealthKitPermission()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            if let lastSync = lastSyncDate {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.blue)
                    
                    Text("Last synced: \(lastSync, formatter: dateFormatter)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var syncOptionsSection: some View {
        VStack(spacing: 16) {
            Text("Sync Options")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                SyncOptionRow(
                    title: "Import Sleep Data",
                    subtitle: "Get sleep data from Apple Health",
                    icon: "arrow.down.circle.fill",
                    color: .blue
                ) {
                    importSleepData()
                }
                
                SyncOptionRow(
                    title: "Export Episodes",
                    subtitle: "Share your episodes with Apple Health",
                    icon: "arrow.up.circle.fill",
                    color: .green
                ) {
                    exportEpisodes()
                }
                
                SyncOptionRow(
                    title: "Sync Audio Recordings",
                    subtitle: "Link recordings to sleep sessions",
                    icon: "mic.circle.fill",
                    color: .orange
                ) {
                    syncAudioRecordings()
                }
            }
            
            if case .syncing = syncStatus {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Syncing...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            
            if case .completed = syncStatus {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Sync completed successfully")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .padding()
            }
            
            if case .failed(let error) = syncStatus {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("Sync failed: \(error)")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding()
            }
        }
    }
    
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Benefits of HealthKit Integration")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                BenefitRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Comprehensive Data",
                    description: "Combine sleep data from multiple sources"
                )
                
                BenefitRow(
                    icon: "heart.fill",
                    title: "Health Insights",
                    description: "See how sleep affects your overall health"
                )
                
                BenefitRow(
                    icon: "share",
                    title: "Share with Doctors",
                    description: "Easily share data with healthcare providers"
                )
                
                BenefitRow(
                    icon: "gear",
                    title: "Automatic Sync",
                    description: "Keep your data up to date automatically"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Privacy & Security")
                .font(.headline)
            
            Text("Your health data is encrypted and stored locally on your device. SomniQ only accesses the data you explicitly grant permission for.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: "lock.shield")
                    .foregroundColor(.blue)
                Text("Data is encrypted and secure")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - HealthKit Methods
    
    private func setupHealthKit() {
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
            checkAuthorizationStatus()
        }
    }
    
    private func checkAuthorizationStatus() {
        guard let healthStore = healthStore else { return }
        
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        
        healthStore.getRequestStatusForAuthorization(toShare: [sleepType], read: [sleepType]) { status, error in
            DispatchQueue.main.async {
                self.isAuthorized = status == .unnecessary
            }
        }
    }
    
    private func requestHealthKitPermission() {
        guard let healthStore = healthStore else { return }
        
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        
        healthStore.requestAuthorization(toShare: [sleepType], read: [sleepType]) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.isAuthorized = true
                    self.updateUserPreferences()
                } else {
                    self.showingPermissionAlert = true
                }
            }
        }
    }
    
    private func importSleepData() {
        syncStatus = .syncing
        
        // Simulate import process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.syncStatus = .completed
            self.lastSyncDate = Date()
        }
    }
    
    private func exportEpisodes() {
        syncStatus = .syncing
        
        // Simulate export process
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.syncStatus = .completed
            self.lastSyncDate = Date()
        }
    }
    
    private func syncAudioRecordings() {
        syncStatus = .syncing
        
        // Simulate sync process
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.syncStatus = .completed
            self.lastSyncDate = Date()
        }
    }
    
    private func updateUserPreferences() {
        if var preferences = dataManager.userPreferences {
            preferences.isHealthKitEnabled = true
            dataManager.updateUserPreferences(preferences)
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

struct SyncOptionRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    HealthKitView(dataManager: DataManager())
} 