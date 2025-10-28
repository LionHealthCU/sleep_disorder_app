import Foundation
import Combine

// MARK: - Simplified Alert Processor
/// Simple alert processor that fires alerts immediately when critical sounds are detected
class AlertProcessor: ObservableObject {
    
    // MARK: - Published Properties
    /// Currently active alerts that need attention
    @Published var activeAlerts: [AlertEvent] = []
    
    /// Historical record of all alerts that have been triggered
    @Published var alertHistory: [AlertEvent] = []
    
    // MARK: - Private Properties
    /// Critical sound classes that should trigger alerts
    private let criticalSounds: Set<String>
    
    /// Confidence threshold for triggering alerts (same as display threshold)
    private let confidenceThreshold: Double = 0.5
    
    /// Maximum number of historical alerts to keep in memory
    private let maxHistorySize = 100
    
    /// Cooldown period between alerts (in seconds) - prevents alert spam
    private let alertCooldownSeconds: TimeInterval = 30.0
    
    /// Timestamp of the last alert that was fired
    private var lastAlertTime: Date?
    
    // MARK: - Initialization
    init() {
        // Get all critical sound classes from the existing mapping
        self.criticalSounds = Set(SoundClassMapping.defaultMapping.filter { $0.value == .critical }.map { $0.key })
        
        print("🚨 Simple AlertProcessor initialized")
        print("🚨 Monitoring \(criticalSounds.count) critical sounds: \(Array(criticalSounds).sorted())")
        print("🚨 Confidence threshold: \(confidenceThreshold)")
    }
    
    // MARK: - Core Processing Method
    /// Processes a single frame of sound analysis data and fires alerts immediately for critical sounds
    /// - Parameters:
    ///   - time: Current timestamp in seconds from start of recording
    ///   - probs: Dictionary of sound class probabilities from SoundAnalysis
    ///   - top2: Tuple of top 2 classifications (unused in simplified version)
    /// - Returns: Array of sound class names that triggered alerts
    func processFrame(time: TimeInterval, probs: [String: Double], top2: (String, Double, String, Double)) -> [String] {
        var fired: [String] = []
        
        print("\n🔍 [Simple AlertProcessor] Processing frame at \(String(format: "%.1f", time))s")
        
        // Check if we're still in cooldown period
        let now = Date()
        if let lastAlert = lastAlertTime {
            let timeSinceLastAlert = now.timeIntervalSince(lastAlert)
            if timeSinceLastAlert < alertCooldownSeconds {
                let remaining = alertCooldownSeconds - timeSinceLastAlert
                print("⏸️ [Simple AlertProcessor] In cooldown - \(String(format: "%.1f", remaining))s remaining")
                return fired
            }
        }
        
        // Simple logic: Check each critical sound class
        for soundClass in criticalSounds {
            let confidence = probs[soundClass] ?? 0.0
            
            print("🎯 [Simple AlertProcessor] Checking \(soundClass): confidence=\(String(format: "%.3f", confidence))")
            
            // If confidence is above threshold, fire alert immediately
            if confidence >= confidenceThreshold {
                let alertEvent = AlertEvent(
                    soundClass: soundClass,
                    tier: .critical,
                    timestamp: Date(),
                    confidence: confidence
                )
                
                print("🚨 [Simple AlertProcessor] ALERT FIRED: \(soundClass) (confidence: \(String(format: "%.3f", confidence)))")
                
                // Update last alert time
                lastAlertTime = now
                
                // Add to active alerts and history
                DispatchQueue.main.async {
                    self.activeAlerts.append(alertEvent)
                    self.alertHistory.append(alertEvent)
                    
                    // Keep history size manageable
                    if self.alertHistory.count > self.maxHistorySize {
                        self.alertHistory.removeFirst()
                    }
                    
                    // Sort active alerts by timestamp (most recent first)
                    self.activeAlerts.sort { $0.timestamp > $1.timestamp }
                }
                
                fired.append(soundClass)
                
                // Only fire one alert per frame (break after first match)
                break
            }
        }
        
        return fired
    }
    
    // MARK: - Public Management Methods
    /// Remove a specific alert from active alerts
    /// - Parameter alertId: UUID of the alert to remove
    func clearAlert(_ alertId: UUID) {
        let beforeCount = activeAlerts.count
        activeAlerts.removeAll { $0.id == alertId }
        let afterCount = activeAlerts.count
        
        if beforeCount > afterCount {
            print("🗑️ [Simple AlertProcessor] Cleared alert with ID: \(alertId)")
        }
    }
    
    /// Remove all active alerts
    func clearAllAlerts() {
        let count = activeAlerts.count
        activeAlerts.removeAll()
        print("🗑️ [Simple AlertProcessor] Cleared all \(count) active alerts")
    }
    
    /// Get the most recent active alert
    /// - Returns: The most recent active alert, or nil if none
    func getTopActiveAlert() -> AlertEvent? {
        return activeAlerts.first
    }
    
    /// Reset all states (useful for starting a new recording session)
    func reset() {
        let activeCount = activeAlerts.count
        activeAlerts.removeAll()
        lastAlertTime = nil
        print("🔄 [Simple AlertProcessor] Reset complete - cleared \(activeCount) active alerts")
    }
}
