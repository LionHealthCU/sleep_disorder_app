import SwiftUI
import Charts

struct DataView: View {
    @ObservedObject var dataManager: DataManager
    @State private var selectedTimeRange: TimeRange = .week
    @State private var selectedChartType: ChartType = .episodes
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case threeMonths = "3 Months"
        case year = "Year"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
            case .year: return 365
            }
        }
    }
    
    enum ChartType: String, CaseIterable {
        case episodes = "Episodes"
        case severity = "Severity"
        case symptoms = "Symptoms"
        case recordings = "Recordings"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Time range selector
                    timeRangeSelector
                    
                    // Chart type selector
                    chartTypeSelector
                    
                    // Main chart
                    mainChartSection
                    
                    // Statistics
                    statisticsSection
                    
                    // Episode list
                    episodeListSection
                    
                    // Recordings list
                    recordingsListSection
                }
                .padding()
            }
            .navigationTitle("Data & Analytics")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var timeRangeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Time Range")
                .font(.headline)
            
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    private var chartTypeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Chart Type")
                .font(.headline)
            
            Picker("Chart Type", selection: $selectedChartType) {
                ForEach(ChartType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    private var mainChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(chartTitle)
                .font(.headline)
            
            VStack {
                switch selectedChartType {
                case .episodes:
                    episodesChart
                case .severity:
                    severityChart
                case .symptoms:
                    symptomsChart
                case .recordings:
                    recordingsChart
                }
            }
            .frame(height: 300)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var episodesChart: some View {
        Chart {
            ForEach(filteredEpisodes, id: \.id) { episode in
                BarMark(
                    x: .value("Date", episode.date, unit: .day),
                    y: .value("Count", 1)
                )
                .foregroundStyle(episode.severity.color)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.day().month())
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel()
            }
        }
    }
    
    private var severityChart: some View {
        Chart {
            ForEach(severityData, id: \.severity) { data in
                BarMark(
                    x: .value("Severity", data.severity.rawValue),
                    y: .value("Count", data.count)
                )
                .foregroundStyle(data.severity.color)
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel()
            }
        }
    }
    
    private var symptomsChart: some View {
        Chart {
            ForEach(symptomData.prefix(8), id: \.symptom) { data in
                BarMark(
                    x: .value("Count", data.count),
                    y: .value("Symptom", data.symptom.rawValue)
                )
                .foregroundStyle(.blue)
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel()
            }
        }
    }
    
    private var recordingsChart: some View {
        Chart {
            ForEach(filteredRecordings, id: \.id) { recording in
                BarMark(
                    x: .value("Date", recording.date, unit: .day),
                    y: .value("Duration", recording.duration / 3600) // Convert to hours
                )
                .foregroundStyle(.green)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.day().month())
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel() // TODO: Add decimal precision formatting later - currently showing whole numbers to avoid ambiguity
            }
        }
        .chartYAxisLabel("Duration (hours)")
    }
    
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Statistics")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatisticCard(
                    title: "Total Episodes",
                    value: "\(filteredEpisodes.count)",
                    icon: "note.text",
                    color: .blue
                )
                
                StatisticCard(
                    title: "Most Common",
                    value: mostCommonSymptom?.rawValue ?? "None",
                    icon: "chart.bar.fill",
                    color: .orange
                )
                
                StatisticCard(
                    title: "Average Severity",
                    value: averageSeverity,
                    icon: "exclamationmark.triangle.fill",
                    color: .red
                )
                
                StatisticCard(
                    title: "Audio Recordings",
                    value: "\(audioRecordingsInRange.count)",
                    icon: "mic.fill",
                    color: .green
                )
                
                StatisticCard(
                    title: "Total Sounds",
                    value: "\(audioRecordingsInRange.reduce(0) { $0 + $1.totalDetections })",
                    icon: "waveform",
                    color: .purple
                )
                
                StatisticCard(
                    title: "Avg Duration",
                    value: averageRecordingDuration,
                    icon: "clock",
                    color: .blue
                )
                
                StatisticCard(
                    title: "Most Detected",
                    value: mostCommonDetectedSound ?? "None",
                    icon: "chart.bar.fill",
                    color: .orange
                )
            }
        }
    }
    
    private var episodeListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Episodes")
                .font(.headline)
            
            if filteredEpisodes.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    Text("No episodes in this time range")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(filteredEpisodes.prefix(10)) { episode in
                        EpisodeDetailRow(episode: episode)
                    }
                }
            }
        }
    }
    
    private var recordingsListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Recordings")
                .font(.headline)
            
            if filteredRecordings.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "mic.fill")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    Text("No recordings in this time range")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(filteredRecordings.prefix(10)) { recording in
                        RecordingDetailRow(recording: recording)
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var chartTitle: String {
        switch selectedChartType {
        case .episodes:
            return "Episodes Over Time"
        case .severity:
            return "Severity Distribution"
        case .symptoms:
            return "Most Common Symptoms"
        case .recordings:
            return "Recording Duration Over Time"
        }
    }
    
    private var filteredEpisodes: [SleepEpisode] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -selectedTimeRange.days, to: Date()) ?? Date()
        return dataManager.episodes.filter { $0.date >= startDate }
    }
    
    private var severityData: [SeverityData] {
        let severityCounts = Dictionary(grouping: filteredEpisodes, by: { $0.severity })
            .mapValues { $0.count }
        
        return EpisodeSeverity.allCases.map { severity in
            SeverityData(severity: severity, count: severityCounts[severity] ?? 0)
        }
    }
    
    private var symptomData: [SymptomData] {
        var symptomCounts: [Symptom: Int] = [:]
        for episode in filteredEpisodes {
            for symptom in episode.symptoms {
                symptomCounts[symptom, default: 0] += 1
            }
        }
        
        return symptomCounts.map { SymptomData(symptom: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }
    
    private var mostCommonSymptom: Symptom? {
        symptomData.first?.symptom
    }
    
    private var averageSeverity: String {
        guard !filteredEpisodes.isEmpty else { return "None" }
        
        let severityValues = filteredEpisodes.map { episode -> Int in
            switch episode.severity {
            case .mild: return 1
            case .moderate: return 2
            case .severe: return 3
            }
        }
        
        let average = Double(severityValues.reduce(0, +)) / Double(severityValues.count)
        
        switch average {
        case 1.0..<1.5:
            return "Mild"
        case 1.5..<2.5:
            return "Moderate"
        default:
            return "Severe"
        }
    }
    
    private var audioRecordingsInRange: [AudioRecording] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -selectedTimeRange.days, to: Date()) ?? Date()
        return dataManager.audioRecordings.filter { $0.date >= startDate }
    }
    
    private var filteredRecordings: [AudioRecording] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -selectedTimeRange.days, to: Date()) ?? Date()
        return dataManager.audioRecordings.filter { $0.date >= startDate }
    }
    
    private var averageRecordingDuration: String {
        guard !filteredRecordings.isEmpty else { return "None" }
        
        let totalDuration = filteredRecordings.reduce(0) { $0 + $1.duration }
        let averageHours = totalDuration / Double(filteredRecordings.count) / 3600
        
        if averageHours >= 1 {
            return String(format: "%.1fh", averageHours)
        } else {
            let averageMinutes = averageHours * 60
            return String(format: "%.0fm", averageMinutes)
        }
    }
    
    private var mostCommonDetectedSound: String? {
        guard !filteredRecordings.isEmpty else { return nil }
        
        var soundCounts: [String: Int] = [:]
        for recording in filteredRecordings {
            for sound in recording.detectedSounds {
                soundCounts[sound.soundName, default: 0] += 1
            }
        }
        
        return soundCounts.max(by: { $0.value < $1.value })?.key
    }
}

struct SeverityData {
    let severity: EpisodeSeverity
    let count: Int
}

struct SymptomData {
    let symptom: Symptom
    let count: Int
}

struct StatisticCard: View {
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
                .font(.title3)
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct EpisodeDetailRow: View {
    let episode: SleepEpisode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: episode.severity.icon)
                    .foregroundColor(episode.severity.color)
                
                Text(episode.severity.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(episode.date, formatter: dateFormatter)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !episode.symptoms.isEmpty {
                Text("Symptoms: \(episode.symptoms.map { $0.rawValue }.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !episode.notes.isEmpty {
                Text(episode.notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
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

struct RecordingDetailRow: View {
    let recording: AudioRecording
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "mic.fill")
                    .foregroundColor(.green)
                
                Text(formatDuration(recording.duration))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(recording.date, formatter: dateFormatter)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if recording.totalDetections > 0 {
                HStack {
                    Text("\(recording.totalDetections) sounds detected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let mostCommon = recording.mostCommonSound {
                        Text("Most: \(mostCommon.capitalized)")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                }
                
                if !recording.detectedSounds.isEmpty {
                    Text("Sounds: \(recording.detectedSounds.prefix(5).map { $0.soundName.capitalized }.joined(separator: ", "))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else {
            return String(format: "%dm", minutes)
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
    DataView(dataManager: DataManager())
} 