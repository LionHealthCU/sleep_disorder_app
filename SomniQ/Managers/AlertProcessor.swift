import Foundation
import Combine

// MARK: - Alert Processing Engine
/// The AlertProcessor is the core engine that analyzes sound classification frames
/// and determines when alerts should be triggered based on configurable rules.
class AlertProcessor: ObservableObject {
    
    // MARK: - Published Properties
    /// Currently active alerts that need attention
    @Published var activeAlerts: [AlertEvent] = []
    
    /// Historical record of all alerts that have been triggered
    @Published var alertHistory: [AlertEvent] = []
    
    // MARK: - Private Properties
    /// Current state for each sound class being monitored
    private var alertStates: [String: AlertState] = [:]
    
    /// Configuration rules for each sound class
    private var alertRules: [String: AlertRule]
    
    /// Maximum number of historical alerts to keep in memory
    private let maxHistorySize = 100
    
    // MARK: - Initialization
    /// Initialize the AlertProcessor with default or custom rules
    /// - Parameter rules: Dictionary of sound class names to their alert rules
    init(rules: [String: AlertRule] = AlertConfiguration.defaultRules) {
        self.alertRules = rules
        
        // Initialize states for all sound classes in the rules
        for soundClass in rules.keys {
            alertStates[soundClass] = AlertState()
        }
        
        print("🚨 AlertProcessor initialized with \(rules.count) sound class rules")
    }
    
    // MARK: - Core Processing Method
    /// Processes a single frame of sound analysis data and determines if any alerts should fire
    /// - Parameters:
    ///   - time: Current timestamp in seconds from start of recording
    ///   - probs: Dictionary of sound class probabilities from SoundAnalysis
    ///   - top2: Tuple of top 2 classifications for uncertainty filtering
    /// - Returns: Array of sound class names that triggered alerts
    func processFrame(time: TimeInterval, probs: [String: Double], top2: (String, Double, String, Double)) -> [String] {
        var fired: [String] = []
        
        // STEP 1: Uncertainty Filter
        // If the top classification has low confidence OR the top two are too close,
        // we consider the classification uncertain and reject it
        let (c1, p1, c2, p2) = top2
        let uncertain = (p1 < 0.40) || (p1 - p2 < 0.15)
        
        if uncertain {
            print("⚠️ Uncertain classification: \(c1)=\(String(format: "%.3f", p1)), \(c2)=\(String(format: "%.3f", p2))")
        }
        
        // STEP 2: Process Each Sound Class
        for (soundClass, rule) in alertRules {
            guard var state = alertStates[soundClass] else { continue }
            
            // Skip if currently in cooldown period
            if time < state.cooldownUntil {
                continue
            }
            
            // STEP 3: Update State with New Data
            let currentProbability = probs[soundClass] ?? 0.0
            
            // Update EMA (Exponential Moving Average) for smoothing
            // Alpha determines how much the new value affects the average
            // Higher alpha = more responsive to recent changes
            let alpha = rule.frameHz / (rule.frameHz + 1.0)  // τ≈1s
            state.ema = alpha * currentProbability + (1 - alpha) * state.ema
            
            // Update ring buffer for windowed mean calculation (if enabled)
            if rule.useWindowMean {
                let maxBufferSize = Int(rule.windowSec * rule.frameHz)
                
                // Remove oldest value if buffer is full
                if state.ring.count == maxBufferSize {
                    state.ring.removeFirst()
                }
                
                // Add new value (apply uncertainty filter here)
                state.ring.append(uncertain ? 0.0 : currentProbability)
            }
            
            // STEP 4: Decision Logic
            let shouldFireAlert = evaluateAlertCondition(
                state: state,
                rule: rule,
                time: time,
                uncertain: uncertain
            )
            
            if shouldFireAlert {
                // Create and store the alert
                let alertEvent = createAlertEvent(
                    soundClass: soundClass,
                    tier: rule.tier,
                    confidence: rule.useWindowMean ? 
                        (state.ring.isEmpty ? 0.0 : state.ring.reduce(0, +) / Double(state.ring.count)) :
                        state.ema,
                    timestamp: Date()
                )
                
                // Update state for cooldown
                state.isActive = true
                state.cooldownUntil = time + rule.cooldownSec
                state.aboveOnSince = nil
                
                // Publish alert updates on main thread
                DispatchQueue.main.async {
                    self.activeAlerts.append(alertEvent)
                    self.alertHistory.append(alertEvent)
                    
                    // Keep history size manageable
                    if self.alertHistory.count > self.maxHistorySize {
                        self.alertHistory.removeFirst()
                    }
                    
                    // Sort active alerts by priority (critical first)
                    self.activeAlerts.sort { $0.tier.priority > $1.tier.priority }
                }
                
                fired.append(soundClass)
                print("🚨 ALERT FIRED: \(soundClass) (tier: \(rule.tier.rawValue), confidence: \(String(format: "%.3f", alertEvent.confidence)))")
            } else {
                // Update state for hysteresis (deactivation)
                if state.isActive && state.ema <= rule.off {
                    state.isActive = false
                    
                    // Remove from active alerts
                    DispatchQueue.main.async {
                        self.activeAlerts.removeAll { $0.soundClass == soundClass }
                    }
                }
            }
            
            // Save updated state
            alertStates[soundClass] = state
        }
        
        return fired
    }
    
    // MARK: - Alert Condition Evaluation
    /// Determines if an alert should fire based on current state and rules
    private func evaluateAlertCondition(
        state: AlertState,
        rule: AlertRule,
        time: TimeInterval,
        uncertain: Bool
    ) -> Bool {
        
        // Never fire alerts during uncertainty
        if uncertain {
            return false
        }
        
        // Don't fire if already active
        if state.isActive {
            return false
        }
        
        if rule.useWindowMean {
            // WINDOWED MEAN DETECTION
            // Requires sustained activity over a time window
            let windowMean = state.ring.isEmpty ? 0.0 : state.ring.reduce(0, +) / Double(state.ring.count)
            
            if windowMean >= rule.windowThresh {
                // Window threshold achieved - alert fires immediately
                // The window duration provides natural debouncing
                return true
            }
        } else {
            // EMA WITH HYSTERESIS DETECTION
            // Requires sustained threshold breach with debounce
            if state.ema >= rule.on {
                // Threshold exceeded
                if let aboveSince = state.aboveOnSince {
                    // Check if we've been above threshold long enough (debounce)
                    if time - aboveSince >= rule.debounceSec {
                        return true
                    }
                } else {
                    // Start tracking when we first exceeded threshold
                    alertStates[rule.soundClass]?.aboveOnSince = time
                }
            } else {
                // Below threshold - reset tracking
                alertStates[rule.soundClass]?.aboveOnSince = nil
            }
        }
        
        return false
    }
    
    // MARK: - Alert Event Creation
    /// Creates an AlertEvent from the current detection
    private func createAlertEvent(
        soundClass: String,
        tier: AlertTier,
        confidence: Double,
        timestamp: Date
    ) -> AlertEvent {
        return AlertEvent(
            soundClass: soundClass,
            tier: tier,
            timestamp: timestamp,
            confidence: confidence
        )
    }
    
    // MARK: - Public Management Methods
    /// Remove a specific alert from active alerts
    /// - Parameter alertId: UUID of the alert to remove
    func clearAlert(_ alertId: UUID) {
        activeAlerts.removeAll { $0.id == alertId }
        print("🗑️ Cleared alert with ID: \(alertId)")
    }
    
    /// Remove all active alerts
    func clearAllAlerts() {
        activeAlerts.removeAll()
        print("🗑️ Cleared all active alerts")
    }
    
    /// Get the highest priority active alert
    /// - Returns: The most important active alert, or nil if none
    func getTopActiveAlert() -> AlertEvent? {
        return activeAlerts.first
    }
    
    /// Update the rule for a specific sound class
    /// - Parameter rule: The new AlertRule to use
    func updateRule(_ rule: AlertRule) {
        alertRules[rule.soundClass] = rule
        alertStates[rule.soundClass] = AlertState() // Reset state for new rule
        print("📝 Updated rule for \(rule.soundClass): tier=\(rule.tier.rawValue), on=\(rule.on), off=\(rule.off)")
    }
    
    /// Get current statistics about the processor
    /// - Returns: Dictionary with processor statistics
    func getStats() -> [String: Any] {
        return [
            "totalRules": alertRules.count,
            "activeAlerts": activeAlerts.count,
            "historySize": alertHistory.count,
            "monitoredClasses": Array(alertRules.keys).sorted()
        ]
    }
    
    /// Reset all states (useful for starting a new recording session)
    func reset() {
        alertStates.removeAll()
        activeAlerts.removeAll()
        
        // Reinitialize states for all rules
        for soundClass in alertRules.keys {
            alertStates[soundClass] = AlertState()
        }
        
        print("🔄 AlertProcessor reset - ready for new session")
    }
}
