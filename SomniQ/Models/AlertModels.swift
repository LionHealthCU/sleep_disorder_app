import Foundation
import SwiftUI

// MARK: - Alert Tier
enum AlertTier: String, CaseIterable, Codable {
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

// MARK: - Alert Rule
struct AlertRule: Codable {
    let soundClass: String
    let tier: AlertTier
    let on: Double          // Activation threshold (0.0 to 1.0)
    let off: Double         // Deactivation threshold (hysteresis)
    let debounceSec: Double // Time to wait before triggering
    let cooldownSec: Double // Cooldown period after alert
    let frameHz: Double     // Frame rate for calculations
    let useWindowMean: Bool // Use windowed mean vs EMA
    let windowSec: Double   // Window duration for mean calculation
    let windowThresh: Double // Threshold for windowed detection
    
    init(soundClass: String, tier: AlertTier, on: Double, off: Double, 
         debounceSec: Double = 2.0, cooldownSec: Double = 10.0, 
         frameHz: Double = 1.0, useWindowMean: Bool = false, 
         windowSec: Double = 5.0, windowThresh: Double = 0.7) {
        self.soundClass = soundClass
        self.tier = tier
        self.on = on
        self.off = off
        self.debounceSec = debounceSec
        self.cooldownSec = cooldownSec
        self.frameHz = frameHz
        self.useWindowMean = useWindowMean
        self.windowSec = windowSec
        self.windowThresh = windowThresh
    }
}

// MARK: - Alert State
struct AlertState: Codable {
    var ema: Double = 0.0                    // Exponential Moving Average
    var isActive: Bool = false               // Current alert status
    var cooldownUntil: TimeInterval = 0.0    // When cooldown ends
    var aboveOnSince: TimeInterval? = nil    // When threshold was first exceeded
    var ring: [Double] = []                  // Ring buffer for windowed mean
    
    init() {
        self.ema = 0.0
        self.isActive = false
        self.cooldownUntil = 0.0
        self.aboveOnSince = nil
        self.ring = []
    }
}

// MARK: - Alert Event
struct AlertEvent: Identifiable, Codable {
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
