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
    
    /// Current sensitivity profile
    @Published var currentProfile: SensitivityProfile = .balanced
    
    // MARK: - Private Properties
    /// Current state for each sound class being monitored
    private var alertStates: [String: AlertState] = [:]
    
    /// Configuration rules for each sound class (generated from current profile)
    private var alertRules: [String: AlertRule] = [:]
    
    /// Current alert profile configuration
    private var currentAlertProfile: AlertProfile
    
    /// Maximum number of historical alerts to keep in memory
    private let maxHistorySize = 100
    
    // MARK: - Initialization
    /// Initialize the AlertProcessor with a sensitivity profile
    /// - Parameter profile: The initial sensitivity profile to use
    init(profile: SensitivityProfile = .balanced) {
        self.currentProfile = profile
        self.currentAlertProfile = AlertProfile.getProfile(for: profile)
        
        // Generate initial rules based on profile
        self.alertRules = AlertConfiguration.generateRules(for: profile)
        
        // Initialize states for all sound classes
        for soundClass in alertRules.keys {
            alertStates[soundClass] = AlertState()
        }
        
        print("🚨 AlertProcessor initialized with \(profile.rawValue) profile")
        print("🚨 AlertProcessor loaded \(alertRules.count) sound class rules")
        print("🚨 AlertProcessor uncertainty: threshold=\(String(format: "%.2f", currentAlertProfile.uncertaintyThreshold)), diff=\(String(format: "%.2f", currentAlertProfile.uncertaintyDifference))")
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
        
        print("\n🔍 [AlertProcessor] Processing frame at \(String(format: "%.1f", time))s")
        
        // STEP 1: Uncertainty Filter (now profile-based)
        // Use profile-specific uncertainty thresholds instead of fixed values
        let (c1, p1, c2, p2) = top2
        let uncertain = (p1 < currentAlertProfile.uncertaintyThreshold) || (p1 - p2 < currentAlertProfile.uncertaintyDifference)
        
        print("📊 [AlertProcessor] Top classifications: \(c1)=\(String(format: "%.3f", p1)), \(c2)=\(String(format: "%.3f", p2))")
        print("📊 [AlertProcessor] Profile uncertainty: threshold=\(String(format: "%.2f", currentAlertProfile.uncertaintyThreshold)), diff=\(String(format: "%.2f", currentAlertProfile.uncertaintyDifference))")
        
        if uncertain {
            print("⚠️ [AlertProcessor] UNCERTAIN classification - rejecting frame (p1=\(String(format: "%.3f", p1)) < \(String(format: "%.2f", currentAlertProfile.uncertaintyThreshold)) OR diff=\(String(format: "%.3f", p1-p2)) < \(String(format: "%.2f", currentAlertProfile.uncertaintyDifference)))")
        } else {
            print("✅ [AlertProcessor] Classification is certain - processing frame")
        }
        
        // STEP 2: Process Each Sound Class
        for (soundClass, rule) in alertRules {
            guard var state = alertStates[soundClass] else { continue }
            
            let currentProbability = probs[soundClass] ?? 0.0
            
            print("🎯 [AlertProcessor] Processing \(soundClass):")
            print("   📈 Current probability: \(String(format: "%.3f", currentProbability))")
            print("   📊 Current EMA: \(String(format: "%.3f", state.ema))")
            print("   🔥 Alert active: \(state.isActive)")
            print("   ⏰ Cooldown until: \(String(format: "%.1f", state.cooldownUntil))s")
            
            // Skip if currently in cooldown period
            if time < state.cooldownUntil {
                print("   ⏸️ [AlertProcessor] \(soundClass) in cooldown - skipping")
                continue
            }
            
            // STEP 3: Update State with New Data
            
            // Update EMA (Exponential Moving Average) for smoothing
            // Alpha determines how much the new value affects the average
            // Higher alpha = more responsive to recent changes
            let alpha = rule.frameHz / (rule.frameHz + 1.0)  // τ≈1s
            let oldEMA = state.ema
            state.ema = alpha * currentProbability + (1 - alpha) * state.ema
            
            print("   🔄 [AlertProcessor] EMA updated: \(String(format: "%.3f", oldEMA)) → \(String(format: "%.3f", state.ema)) (α=\(String(format: "%.3f", alpha)))")
            
            // Update ring buffer for windowed mean calculation (if enabled)
            if rule.useWindowMean {
                let maxBufferSize = Int(rule.windowSec * rule.frameHz)
                let oldRingCount = state.ring.count
                
                // Remove oldest value if buffer is full
                if state.ring.count == maxBufferSize {
                    state.ring.removeFirst()
                }
                
                // Add new value (apply uncertainty filter here)
                let valueToAdd = uncertain ? 0.0 : currentProbability
                state.ring.append(valueToAdd)
                
                print("   📊 [AlertProcessor] Ring buffer: \(oldRingCount) → \(state.ring.count) values (added: \(String(format: "%.3f", valueToAdd)))")
                
                if !state.ring.isEmpty {
                    let windowMean = state.ring.reduce(0, +) / Double(state.ring.count)
                    print("   📈 [AlertProcessor] Window mean: \(String(format: "%.3f", windowMean))")
                }
            } else {
                print("   📈 [AlertProcessor] Using EMA detection (not windowed)")
            }
            
            // STEP 4: Decision Logic
            print("   🤔 [AlertProcessor] Evaluating alert condition...")
            let shouldFireAlert = evaluateAlertCondition(
                state: state,
                rule: rule,
                time: time,
                uncertain: uncertain
            )
            
            print("   📋 [AlertProcessor] Rule settings: on=\(rule.on), off=\(rule.off), debounce=\(rule.debounceSec)s, cooldown=\(rule.cooldownSec)s")
            print("   📋 [AlertProcessor] Detection method: \(rule.useWindowMean ? "Windowed Mean" : "EMA with Hysteresis")")
            
            if shouldFireAlert {
                // Create and store the alert
                let confidence = rule.useWindowMean ? 
                    (state.ring.isEmpty ? 0.0 : state.ring.reduce(0, +) / Double(state.ring.count)) :
                    state.ema
                    
                let alertEvent = createAlertEvent(
                    soundClass: soundClass,
                    tier: rule.tier,
                    confidence: confidence,
                    timestamp: Date()
                )
                
                print("   🚨 [AlertProcessor] ALERT TRIGGERED! Creating alert event...")
                print("   📊 [AlertProcessor] Alert details: tier=\(rule.tier.rawValue), confidence=\(String(format: "%.3f", confidence))")
                
                // Update state for cooldown
                state.isActive = true
                state.cooldownUntil = time + rule.cooldownSec
                state.aboveOnSince = nil
                
                print("   ⏰ [AlertProcessor] Cooldown set until \(String(format: "%.1f", state.cooldownUntil))s")
                
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
                print("🚨 [AlertProcessor] ALERT FIRED: \(soundClass) (tier: \(rule.tier.rawValue), confidence: \(String(format: "%.3f", alertEvent.confidence)))")
            } else {
                print("   ❌ [AlertProcessor] Alert condition not met")
                
                // Update state for hysteresis (deactivation)
                if state.isActive && state.ema <= rule.off {
                    print("   🔄 [AlertProcessor] EMA (\(String(format: "%.3f", state.ema))) ≤ off threshold (\(rule.off)) - deactivating alert")
                    state.isActive = false
                    
                    // Remove from active alerts
                    DispatchQueue.main.async {
                        self.activeAlerts.removeAll { $0.soundClass == soundClass }
                    }
                    print("   🗑️ [AlertProcessor] Alert deactivated for \(soundClass)")
                } else if state.isActive {
                    print("   🔥 [AlertProcessor] Alert still active (EMA=\(String(format: "%.3f", state.ema)) > off=\(rule.off))")
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
        
        print("     🔍 [AlertProcessor] Evaluating condition for \(rule.soundClass):")
        
        // Never fire alerts during uncertainty
        if uncertain {
            print("     ❌ [AlertProcessor] Rejecting due to uncertainty")
            return false
        }
        
        // Don't fire if already active
        if state.isActive {
            print("     ❌ [AlertProcessor] Rejecting - alert already active")
            return false
        }
        
        if rule.useWindowMean {
            // WINDOWED MEAN DETECTION
            // Requires sustained activity over a time window
            let windowMean = state.ring.isEmpty ? 0.0 : state.ring.reduce(0, +) / Double(state.ring.count)
            
            print("     📊 [AlertProcessor] Windowed detection: mean=\(String(format: "%.3f", windowMean)), threshold=\(rule.windowThresh)")
            
            if windowMean >= rule.windowThresh {
                // Window threshold achieved - alert fires immediately
                // The window duration provides natural debouncing
                print("     ✅ [AlertProcessor] Window threshold met - ALERT SHOULD FIRE")
                return true
            } else {
                print("     ❌ [AlertProcessor] Window threshold not met")
            }
        } else {
            // EMA WITH HYSTERESIS DETECTION
            // Requires sustained threshold breach with debounce
            print("     📊 [AlertProcessor] EMA detection: ema=\(String(format: "%.3f", state.ema)), on=\(rule.on), off=\(rule.off)")
            
            if state.ema >= rule.on {
                // Threshold exceeded
                print("     📈 [AlertProcessor] EMA above ON threshold")
                
                if let aboveSince = state.aboveOnSince {
                    let timeAbove = time - aboveSince
                    print("     ⏱️ [AlertProcessor] Been above threshold for \(String(format: "%.1f", timeAbove))s (need \(rule.debounceSec)s)")
                    
                    // Check if we've been above threshold long enough (debounce)
                    if timeAbove >= rule.debounceSec {
                        print("     ✅ [AlertProcessor] Debounce period complete - ALERT SHOULD FIRE")
                        return true
                    } else {
                        print("     ⏳ [AlertProcessor] Still in debounce period")
                    }
                } else {
                    // Start tracking when we first exceeded threshold
                    print("     🚀 [AlertProcessor] First time above threshold - starting debounce timer")
                    alertStates[rule.soundClass]?.aboveOnSince = time
                }
            } else {
                // Below threshold - reset tracking
                if state.aboveOnSince != nil {
                    print("     🔄 [AlertProcessor] EMA below ON threshold - resetting debounce timer")
                    alertStates[rule.soundClass]?.aboveOnSince = nil
                } else {
                    print("     ❌ [AlertProcessor] EMA below ON threshold")
                }
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
        let beforeCount = activeAlerts.count
        activeAlerts.removeAll { $0.id == alertId }
        let afterCount = activeAlerts.count
        
        if beforeCount > afterCount {
            print("🗑️ [AlertProcessor] Cleared alert with ID: \(alertId) (removed \(beforeCount - afterCount) alert(s))")
        } else {
            print("⚠️ [AlertProcessor] No alert found with ID: \(alertId)")
        }
    }
    
    /// Remove all active alerts
    func clearAllAlerts() {
        let count = activeAlerts.count
        activeAlerts.removeAll()
        print("🗑️ [AlertProcessor] Cleared all \(count) active alerts")
    }
    
    /// Get the highest priority active alert
    /// - Returns: The most important active alert, or nil if none
    func getTopActiveAlert() -> AlertEvent? {
        let topAlert = activeAlerts.first
        if let alert = topAlert {
            print("📊 [AlertProcessor] Top active alert: \(alert.soundClass) (\(alert.tier.rawValue), \(String(format: "%.3f", alert.confidence)))")
        } else {
            print("📊 [AlertProcessor] No active alerts")
        }
        return topAlert
    }
    
    /// Update the rule for a specific sound class
    /// - Parameter rule: The new AlertRule to use
    func updateRule(_ rule: AlertRule) {
        alertRules[rule.soundClass] = rule
        alertStates[rule.soundClass] = AlertState() // Reset state for new rule
        print("📝 [AlertProcessor] Updated rule for \(rule.soundClass):")
        print("   🏷️ Tier: \(rule.tier.rawValue)")
        print("   📊 Thresholds: on=\(rule.on), off=\(rule.off)")
        print("   ⏱️ Timing: debounce=\(rule.debounceSec)s, cooldown=\(rule.cooldownSec)s")
        print("   🔧 Method: \(rule.useWindowMean ? "Windowed Mean" : "EMA with Hysteresis")")
        if rule.useWindowMean {
            print("   📈 Window: \(rule.windowSec)s, threshold=\(rule.windowThresh)")
        }
    }
    
    /// Change the sensitivity profile and regenerate all rules
    /// - Parameter profile: The new sensitivity profile to use
    func changeProfile(to profile: SensitivityProfile) {
        print("🔄 [AlertProcessor] Changing profile from \(currentProfile.rawValue) to \(profile.rawValue)")
        
        // Update current profile
        currentProfile = profile
        currentAlertProfile = AlertProfile.getProfile(for: profile)
        
        // Generate new rules based on the profile
        alertRules = AlertConfiguration.generateRules(for: profile)
        
        // Reset all alert states for the new rules
        alertStates.removeAll()
        for soundClass in alertRules.keys {
            alertStates[soundClass] = AlertState()
        }
        
        // Clear any active alerts since rules have changed
        clearAllAlerts()
        
        print("✅ [AlertProcessor] Profile changed to \(profile.rawValue)")
        print("🔧 [AlertProcessor] New uncertainty: threshold=\(String(format: "%.2f", currentAlertProfile.uncertaintyThreshold)), diff=\(String(format: "%.2f", currentAlertProfile.uncertaintyDifference))")
        print("📋 [AlertProcessor] Regenerated \(alertRules.count) rules")
    }
    
    /// Get the current profile name
    /// - Returns: The current sensitivity profile
    func getCurrentProfile() -> SensitivityProfile {
        return currentProfile
    }
    
    /// Get the current profile configuration
    /// - Returns: The current AlertProfile configuration
    func getCurrentProfileConfig() -> AlertProfile {
        return currentAlertProfile
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
        let activeCount = activeAlerts.count
        let stateCount = alertStates.count
        
        alertStates.removeAll()
        activeAlerts.removeAll()
        
        // Reinitialize states for all rules
        for soundClass in alertRules.keys {
            alertStates[soundClass] = AlertState()
        }
        
        print("🔄 [AlertProcessor] RESET COMPLETE:")
        print("   🗑️ Cleared \(activeCount) active alerts")
        print("   🔄 Reset \(stateCount) alert states")
        print("   🆕 Reinitialized states for \(alertRules.count) sound classes")
        print("   ✅ Ready for new recording session")
    }
}
