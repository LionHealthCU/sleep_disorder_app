import Foundation

// MARK: - Sound Class Mapping Configuration
struct SoundClassMapping {
    
    // MARK: - Default Sound Class to Alert Tier Mapping
    static let defaultMapping: [String: AlertTier] = [
        // Critical sleep disturbances - Immediate attention required
        "Gasping": .critical,
        "Choking": .critical,
        "Screaming": .critical,
        "Crash": .critical,
        "Siren": .critical,
        "Alarm": .critical,
        
        // High priority sleep issues - Significant sleep disruption
        "Snoring": .high,
        "Coughing": .high,
        "Crying": .high,
        "Whimpering": .high,
        "Groaning": .high,
        "Sobbing": .high,
        "Wailing": .high,
        
        // Medium priority sounds - Moderate sleep disruption
        "Talking": .medium,
        "Laughing": .medium,
        "Shouting": .medium,
        "Singing": .medium,
        "Yawning": .medium,
        "Whistling": .medium,
        "Clapping": .medium,
        
        // Low priority ambient sounds - Minimal sleep disruption
        "Music": .low,
        "Television": .low,
        "Applause": .low,
        "Footsteps": .low,
        "Door": .low,
        "Wind": .low,
        "Rain": .low,
        "Thunder": .low,
        "Silence": .low,
        "Ambient": .low,
        "Background": .low
    ]
    
    // MARK: - Public Interface
    
    /// Returns the alert tier for a given sound class
    /// - Parameter soundClass: The sound class identifier from SoundAnalysis
    /// - Returns: The appropriate AlertTier, defaults to .low if not found
    static func getTier(for soundClass: String) -> AlertTier {
        return defaultMapping[soundClass] ?? .low
    }
    
    /// Returns all sound classes mapped to a specific tier
    /// - Parameter tier: The alert tier to filter by
    /// - Returns: Array of sound class names
    static func getSoundClasses(for tier: AlertTier) -> [String] {
        return defaultMapping.compactMap { (soundClass, alertTier) in
            alertTier == tier ? soundClass : nil
        }.sorted()
    }
    
    /// Returns all available sound classes in the mapping
    /// - Returns: Array of all sound class names
    static func getAllSoundClasses() -> [String] {
        return Array(defaultMapping.keys).sorted()
    }
    
    /// Checks if a sound class exists in the mapping
    /// - Parameter soundClass: The sound class to check
    /// - Returns: True if the sound class is mapped
    static func contains(_ soundClass: String) -> Bool {
        return defaultMapping[soundClass] != nil
    }
    
    /// Returns the total count of mapped sound classes
    /// - Returns: Number of sound classes in the mapping
    static func count() -> Int {
        return defaultMapping.count
    }
}

// MARK: - Alert Configuration
struct AlertConfiguration {
    
    // MARK: - Default Alert Rules
    static let defaultRules: [String: AlertRule] = {
        var rules: [String: AlertRule] = [:]
        
        // Create rules for all mapped sound classes
        for (soundClass, tier) in SoundClassMapping.defaultMapping {
            let rule = createDefaultRule(for: soundClass, tier: tier)
            rules[soundClass] = rule
        }
        
        return rules
    }()
    
    // MARK: - Rule Creation Helper
    
    /// Creates a default alert rule for a sound class based on its tier
    /// - Parameters:
    ///   - soundClass: The sound class name
    ///   - tier: The alert tier
    /// - Returns: A configured AlertRule
    private static func createDefaultRule(for soundClass: String, tier: AlertTier) -> AlertRule {
        switch tier {
        case .critical:
            return AlertRule(
                soundClass: soundClass,
                tier: tier,
                on: 0.6,        // Lower threshold for faster detection
                off: 0.4,       // Hysteresis to prevent rapid toggling
                debounceSec: 1.0,  // Quick response time
                cooldownSec: 5.0,  // Short cooldown for critical events
                frameHz: 1.0,
                useWindowMean: false  // Immediate detection for critical sounds
            )
            
        case .high:
            return AlertRule(
                soundClass: soundClass,
                tier: tier,
                on: 0.7,        // Higher threshold for more confidence
                off: 0.5,       // Hysteresis
                debounceSec: 2.0,  // Moderate debounce
                cooldownSec: 15.0, // Longer cooldown
                frameHz: 1.0,
                useWindowMean: true,  // Windowed detection for sustained sounds
                windowSec: 3.0,
                windowThresh: 0.6
            )
            
        case .medium:
            return AlertRule(
                soundClass: soundClass,
                tier: tier,
                on: 0.8,        // Higher threshold
                off: 0.6,       // Hysteresis
                debounceSec: 3.0,  // Longer debounce
                cooldownSec: 30.0, // Longer cooldown
                frameHz: 1.0,
                useWindowMean: true,  // Windowed detection
                windowSec: 5.0,
                windowThresh: 0.7
            )
            
        case .low:
            return AlertRule(
                soundClass: soundClass,
                tier: tier,
                on: 0.9,        // Very high threshold
                off: 0.7,       // Hysteresis
                debounceSec: 5.0,  // Long debounce
                cooldownSec: 60.0, // Long cooldown
                frameHz: 1.0,
                useWindowMean: true,  // Windowed detection
                windowSec: 10.0,
                windowThresh: 0.8
            )
        }
    }
    
    // MARK: - Public Interface
    
    /// Returns the default rule for a sound class
    /// - Parameter soundClass: The sound class name
    /// - Returns: The default AlertRule, or nil if not found
    static func getDefaultRule(for soundClass: String) -> AlertRule? {
        return defaultRules[soundClass]
    }
    
    /// Creates a default rule for an unmapped sound class
    /// - Parameter soundClass: The sound class name
    /// - Returns: A default AlertRule with low tier settings
    static func createDefaultRule(for soundClass: String) -> AlertRule {
        return AlertRule(
            soundClass: soundClass,
            tier: .low,  // Default to low tier for unmapped sounds
            on: 0.9,
            off: 0.7,
            debounceSec: 5.0,
            cooldownSec: 60.0,
            frameHz: 1.0,
            useWindowMean: true,
            windowSec: 10.0,
            windowThresh: 0.8
        )
    }
    
    /// Returns all available rules
    /// - Returns: Dictionary of all default rules
    static func getAllRules() -> [String: AlertRule] {
        return defaultRules
    }
}
