import SwiftUI

struct SelfReportView: View {
    @ObservedObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedSeverity: EpisodeSeverity = .moderate
    @State private var selectedSymptoms: Set<Symptom> = []
    @State private var notes = ""
    @State private var episodeDate = Date()
    @State private var showingSaveAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                // Date and Time Section
                Section("When did this episode occur?") {
                    DatePicker("Date & Time", selection: $episodeDate, displayedComponents: [.date, .hourAndMinute])
                }
                
                // Severity Section
                Section("How severe was this episode?") {
                    Picker("Severity", selection: $selectedSeverity) {
                        ForEach(EpisodeSeverity.allCases, id: \.self) { severity in
                            HStack {
                                Image(systemName: severity.icon)
                                    .foregroundColor(severity.color)
                                Text(severity.rawValue)
                            }
                            .tag(severity)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    // Severity description
                    VStack(alignment: .leading, spacing: 8) {
                        Text(severityDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Image(systemName: selectedSeverity.icon)
                                .foregroundColor(selectedSeverity.color)
                            Text("\(selectedSeverity.rawValue) Episode")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                    .padding(.top, 8)
                }
                
                // Symptoms Section
                Section("What symptoms did you experience?") {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(Symptom.allCases, id: \.self) { symptom in
                            SymptomToggleButton(
                                symptom: symptom,
                                isSelected: selectedSymptoms.contains(symptom)
                            ) {
                                if selectedSymptoms.contains(symptom) {
                                    selectedSymptoms.remove(symptom)
                                } else {
                                    selectedSymptoms.insert(symptom)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Notes Section
                Section("Additional Notes (Optional)") {
                    TextField("Describe what happened, how you felt, or any other details...", text: $notes, axis: .vertical)
                        .lineLimit(4...8)
                }
                
                // Quick Actions Section
                Section {
                    HStack {
                        Button("Save Episode") {
                            saveEpisode()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(selectedSymptoms.isEmpty)
                        
                        Spacer()
                        
                        Button("Cancel") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .navigationTitle("Report Episode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Episode Saved", isPresented: $showingSaveAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your sleep episode has been recorded successfully.")
        }
    }
    
    private var severityDescription: String {
        switch selectedSeverity {
        case .mild:
            return "Minor symptoms that don't significantly impact sleep quality"
        case .moderate:
            return "Noticeable symptoms that affect sleep but are manageable"
        case .severe:
            return "Significant symptoms that severely impact sleep and daily function"
        }
    }
    
    private func saveEpisode() {
        let episode = SleepEpisode(
            date: episodeDate,
            severity: selectedSeverity,
            symptoms: Array(selectedSymptoms),
            notes: notes
        )
        
        dataManager.addEpisode(episode)
        showingSaveAlert = true
    }
}

struct SymptomToggleButton: View {
    let symptom: Symptom
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: symptom.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(symptom.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SelfReportView(dataManager: DataManager())
} 