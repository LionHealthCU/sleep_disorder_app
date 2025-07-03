import SwiftUI

struct SetupView: View {
    @ObservedObject var dataManager: DataManager
    @State private var bedtime = Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? Date()
    @State private var wakeTime = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
    @State private var currentStep = 0
    
    private let steps = [
        "Welcome to SomniQ",
        "Set Your Sleep Schedule",
        "Ready to Start"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Progress indicator
                ProgressView(value: Double(currentStep), total: Double(steps.count - 1))
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .padding(.horizontal)
                
                // Step content
                VStack(spacing: 20) {
                    switch currentStep {
                    case 0:
                        welcomeStep
                    case 1:
                        sleepScheduleStep
                    case 2:
                        finalStep
                    default:
                        EmptyView()
                    }
                }
                .padding()
                
                Spacer()
                
                // Navigation buttons
                HStack {
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Spacer()
                    
                    Button(currentStep == steps.count - 1 ? "Get Started" : "Next") {
                        if currentStep == steps.count - 1 {
                            completeSetup()
                        } else {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(currentStep == 1 && !isValidSleepSchedule)
                }
                .padding()
            }
            .navigationTitle("Setup")
            .navigationBarHidden(true)
        }
    }
    
    private var welcomeStep: some View {
        VStack(spacing: 30) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            VStack(spacing: 16) {
                Text("Welcome to SomniQ")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Your personal sleep disorder tracking companion")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(icon: "mic.fill", title: "Record Audio", description: "Capture sleep sounds for analysis")
                FeatureRow(icon: "note.text", title: "Track Episodes", description: "Log symptoms and severity")
                FeatureRow(icon: "heart.fill", title: "Health Integration", description: "Connect with Apple Health")
                FeatureRow(icon: "person.3.fill", title: "Community", description: "Connect with others")
            }
            .padding(.top)
        }
    }
    
    private var sleepScheduleStep: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                Text("Your Sleep Schedule")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Help us understand your typical sleep patterns")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Usual Bedtime", systemImage: "bed.double.fill")
                        .font(.headline)
                    
                    DatePicker("Bedtime", selection: $bedtime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .scaleEffect(0.8)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Label("Usual Wake Time", systemImage: "sunrise.fill")
                        .font(.headline)
                    
                    DatePicker("Wake Time", selection: $wakeTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .scaleEffect(0.8)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            if !isValidSleepSchedule {
                Text("Wake time should be after bedtime")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
    }
    
    private var finalStep: some View {
        VStack(spacing: 30) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            VStack(spacing: 16) {
                Text("You're All Set!")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("SomniQ is ready to help you track and understand your sleep patterns")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Your sleep schedule:")
                    .font(.headline)
                
                HStack {
                    Image(systemName: "bed.double.fill")
                    Text("Bedtime: \(bedtime, formatter: timeFormatter)")
                }
                
                HStack {
                    Image(systemName: "sunrise.fill")
                    Text("Wake time: \(wakeTime, formatter: timeFormatter)")
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var isValidSleepSchedule: Bool {
        // Check if wake time is after bedtime
        // If bedtime is after midnight (e.g., 1 AM), wake time should be the next day
        let calendar = Calendar.current
        
        // Normalize both times to today for comparison
        let today = Date()
        let bedtimeToday = calendar.date(bySettingHour: calendar.component(.hour, from: bedtime),
                                        minute: calendar.component(.minute, from: bedtime),
                                        second: 0, of: today) ?? bedtime
        
        let wakeTimeToday = calendar.date(bySettingHour: calendar.component(.hour, from: wakeTime),
                                         minute: calendar.component(.minute, from: wakeTime),
                                         second: 0, of: today) ?? wakeTime
        
        // If bedtime is late (after 6 PM) and wake time is early (before 6 PM), 
        // assume wake time is the next day
        if calendar.component(.hour, from: bedtimeToday) >= 18 && calendar.component(.hour, from: wakeTimeToday) < 18 {
            // Add 24 hours to wake time for comparison
            let wakeTimeNextDay = calendar.date(byAdding: .day, value: 1, to: wakeTimeToday) ?? wakeTimeToday
            return wakeTimeNextDay > bedtimeToday
        } else {
            return wakeTimeToday > bedtimeToday
        }
    }
    
    private func completeSetup() {
        let preferences = UserPreferences(usualBedtime: bedtime, usualWakeTime: wakeTime)
        dataManager.updateUserPreferences(preferences)
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    SetupView(dataManager: DataManager())
} 