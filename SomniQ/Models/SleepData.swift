import Foundation
import SwiftUI

// MARK: - Sleep Episode Model
struct SleepEpisode: Identifiable, Codable {
    let id = UUID()
    var date: Date
    var severity: EpisodeSeverity
    var symptoms: [Symptom]
    var notes: String
    var duration: TimeInterval?
    var audioRecordingURL: URL?
    
    init(date: Date = Date(), severity: EpisodeSeverity, symptoms: [Symptom] = [], notes: String = "", duration: TimeInterval? = nil, audioRecordingURL: URL? = nil) {
        self.date = date
        self.severity = severity
        self.symptoms = symptoms
        self.notes = notes
        self.duration = duration
        self.audioRecordingURL = audioRecordingURL
    }
}

// MARK: - Episode Severity
enum EpisodeSeverity: String, CaseIterable, Codable {
    case mild = "Mild"
    case moderate = "Moderate"
    case severe = "Severe"
    
    var color: Color {
        switch self {
        case .mild:
            return .green
        case .moderate:
            return .orange
        case .severe:
            return .red
        }
    }
    
    var icon: String {
        switch self {
        case .mild:
            return "moon.fill"
        case .moderate:
            return "moon.zzz.fill"
        case .severe:
            return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Symptoms
enum Symptom: String, CaseIterable, Codable {
    case snoring = "Snoring"
    case gasping = "Gasping for Air"
    case restless = "Restless Sleep"
    case insomnia = "Insomnia"
    case nightmares = "Nightmares"
    case sleepwalking = "Sleepwalking"
    case excessiveDaytimeSleepiness = "Excessive Daytime Sleepiness"
    case morningHeadache = "Morning Headache"
    case dryMouth = "Dry Mouth"
    case chestPain = "Chest Pain"
    
    var icon: String {
        switch self {
        case .snoring:
            return "lungs.fill"
        case .gasping:
            return "wind"
        case .restless:
            return "bed.double.fill"
        case .insomnia:
            return "eye.slash.fill"
        case .nightmares:
            return "brain.head.profile"
        case .sleepwalking:
            return "figure.walk"
        case .excessiveDaytimeSleepiness:
            return "zzz"
        case .morningHeadache:
            return "headphones"
        case .dryMouth:
            return "drop.fill"
        case .chestPain:
            return "heart.fill"
        }
    }
}

// MARK: - Audio Recording Model
struct AudioRecording: Identifiable, Codable {
    let id = UUID()
    var date: Date
    var duration: TimeInterval
    var fileURL: URL
    var episodeId: UUID?
    
    // Enhanced with analysis data
    var detectedSounds: [DetectedSound]
    var mostCommonSound: String?
    var totalDetections: Int
    var uniqueSoundCount: Int
    
    init(date: Date = Date(), duration: TimeInterval, fileURL: URL, episodeId: UUID? = nil, detectedSounds: [DetectedSound] = [], mostCommonSound: String? = nil, totalDetections: Int = 0, uniqueSoundCount: Int = 0) {
        self.date = date
        self.duration = duration
        self.fileURL = fileURL
        self.episodeId = episodeId
        self.detectedSounds = detectedSounds
        self.mostCommonSound = mostCommonSound
        self.totalDetections = totalDetections
        self.uniqueSoundCount = uniqueSoundCount
    }
    
    // Convenience initializer from RecordingSummary
    init(from summary: RecordingSummary, episodeId: UUID? = nil) {
        self.date = summary.recordingDate
        self.duration = summary.duration
        self.fileURL = summary.fileURL
        self.episodeId = episodeId
        self.detectedSounds = summary.detectedSounds
        self.mostCommonSound = summary.mostCommonSound
        self.totalDetections = summary.totalDetections
        self.uniqueSoundCount = Set(summary.detectedSounds.map { $0.soundName }).count
    }
}

// MARK: - Detected Sound Model
struct DetectedSound: Identifiable, Codable {
    let id = UUID()
    let soundName: String
    let confidence: Float
    let timestamp: Date
    
    init(soundName: String, confidence: Float, timestamp: Date) {
        self.soundName = soundName
        self.confidence = confidence
        self.timestamp = timestamp
    }
}

// MARK: - User Preferences
struct UserPreferences: Codable {
    var usualBedtime: Date
    var usualWakeTime: Date
    var isHealthKitEnabled: Bool = false
    var notificationsEnabled: Bool = true
    var reminderTime: Date = Calendar.current.date(from: DateComponents(hour: 21, minute: 0)) ?? Date()
    
    init(usualBedtime: Date, usualWakeTime: Date) {
        self.usualBedtime = usualBedtime
        self.usualWakeTime = usualWakeTime
    }
}

// MARK: - Community Post
struct CommunityPost: Identifiable, Codable {
    let id = UUID()
    var author: String
    var content: String
    var date: Date
    var likes: Int
    var comments: [Comment]
    
    init(author: String, content: String, date: Date = Date(), likes: Int = 0, comments: [Comment] = []) {
        self.author = author
        self.content = content
        self.date = date
        self.likes = likes
        self.comments = comments
    }
}

// MARK: - Comment
struct Comment: Identifiable, Codable {
    let id = UUID()
    var author: String
    var content: String
    var date: Date
    
    init(author: String, content: String, date: Date = Date()) {
        self.author = author
        self.content = content
        self.date = date
    }
} 