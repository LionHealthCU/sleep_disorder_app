import Foundation
import SwiftUI

// MARK: - Alert Tier
enum AlertTier: String, CaseIterable, Codable, Equatable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
    
    var color: Color {
        switch self {
        case .low:
            return .green
        case .medium:
            return .yellow
        case .high:
            return .orange
        case .critical:
            return .red
        }
    }
    
    var icon: String {
        switch self {
        case .low:
            return "bell"
        case .medium:
            return "bell.fill"
        case .high:
            return "exclamationmark.triangle"
        case .critical:
            return "exclamationmark.triangle.fill"
        }
    }
    
    var priority: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        case .critical: return 4
        }
    }
}


// MARK: - Alert Event
struct AlertEvent: Identifiable, Codable, Equatable {
    let id = UUID()
    let soundClass: String
    let tier: AlertTier
    let timestamp: Date
    let confidence: Double
    let duration: TimeInterval?
    
    init(soundClass: String, tier: AlertTier, timestamp: Date, confidence: Double, duration: TimeInterval? = nil) {
        self.soundClass = soundClass
        self.tier = tier
        self.timestamp = timestamp
        self.confidence = confidence
        self.duration = duration
    }
}
