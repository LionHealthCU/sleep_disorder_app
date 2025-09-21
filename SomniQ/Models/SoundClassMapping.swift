import Foundation

// MARK: - Sound Class Mapping Configuration
struct SoundClassMapping {
    
    // MARK: - Default Sound Class to Alert Tier Mapping
    static let defaultMapping: [String: AlertTier] = [
        // Critical sleep disturbances - Immediate attention required
        "gasp": .critical,                    // Gasping for air
        "screaming": .critical,               // Screaming
        "siren": .critical,                   // Emergency sirens
        "police_siren": .critical,            // Police siren
        "ambulance_siren": .critical,         // Ambulance siren
        "fire_engine_siren": .critical,       // Fire engine siren
        "civil_defense_siren": .critical,     // Civil defense siren
        "smoke_detector": .critical,          // Smoke detector alarm
        "alarm_clock": .critical,             // Alarm clock
        "gunshot_gunfire": .critical,         // Gunshots
        "artillery_fire": .critical,          // Artillery fire
        "fireworks": .critical,               // Fireworks
        "firecracker": .critical,             // Firecrackers
        "boom": .critical,                    // Explosions
        "glass_breaking": .critical,          // Breaking glass
        "slap_smack": .critical,              // Slapping/smacking sounds
        
        // High priority sleep issues - Significant sleep disruption
        "snoring": .high,                     // Snoring
        "cough": .high,                       // Coughing
        "crying_sobbing": .high,              // Crying/sobbing
        "baby_crying": .high,                 // Baby crying
        "dog_bark": .high,                    // Dog barking
        "dog_howl": .high,                    // Dog howling
        "dog_growl": .high,                   // Dog growling
        "dog_whimper": .high,                 // Dog whimpering
        "cat_meow": .high,                    // Cat meowing
        "baby_laughter": .high,               // Baby laughter
        "coyote_howl": .high,                 // Coyote howling
        "lion_roar": .high,                   // Lion roaring
        "thunder": .high,                     // Thunder
        "thunderstorm": .high,                // Thunderstorm
        
        // Medium priority sounds - Moderate sleep disruption
        "speech": .medium,                    // General speech
        "shout": .medium,                     // Shouting
        "yell": .medium,                      // Yelling
        "battle_cry": .medium,                // Battle cry
        "children_shouting": .medium,         // Children shouting
        "laughter": .medium,                  // General laughter
        "giggling": .medium,                  // Giggling
        "belly_laugh": .medium,               // Belly laughing
        "chuckle_chortle": .medium,           // Chuckling
        "singing": .medium,                   // Singing
        "choir_singing": .medium,             // Choir singing
        "whistling": .medium,                 // Whistling
        "clapping": .medium,                  // Clapping
        "cheering": .medium,                  // Cheering
        "applause": .medium,                  // Applause
        "chatter": .medium,                   // Chatter
        "crowd": .medium,                     // Crowd noise
        "babble": .medium,                    // Babbling
        "door_slam": .medium,                 // Door slamming
        "knock": .medium,                     // Knocking
        "squeak": .medium,                    // Squeaking
        "telephone_bell_ringing": .medium,    // Phone ringing
        "ringtone": .medium,                  // Ringtone
        "car_horn": .medium,                  // Car horn
        "air_horn": .medium,                  // Air horn
        "train_whistle": .medium,             // Train whistle
        "train_horn": .medium,                // Train horn
        "helicopter": .medium,                // Helicopter
        "airplane": .medium,                  // Airplane
        
        // Low priority ambient sounds - Minimal sleep disruption
        "music": .low,                        // General music
        "plucked_string_instrument": .low,    // String instruments
        "guitar": .low,                       // Guitar
        "piano": .low,                        // Piano
        "drum_kit": .low,                     // Drum kit
        "orchestra": .low,                    // Orchestra
        "wind": .low,                         // Wind
        "wind_rustling_leaves": .low,         // Wind in leaves
        "water": .low,                        // Water sounds
        "rain": .low,                         // Rain
        "raindrop": .low,                     // Raindrops
        "ocean": .low,                        // Ocean
        "sea_waves": .low,                    // Sea waves
        "fire_crackle": .low,                 // Fire crackling
        "breathing": .low,                    // Breathing
        "sigh": .low,                         // Sighing
        "whispering": .low,                   // Whispering
        "humming": .low,                      // Humming
        "snicker": .low,                      // Snickering
        "sneeze": .low,                       // Sneezing
        "nose_blowing": .low,                 // Nose blowing
        "person_walking": .low,               // Walking
        "person_shuffling": .low,             // Shuffling
        "person_running": .low,               // Running
        "chewing": .low,                      // Chewing
        "biting": .low,                       // Biting
        "gargling": .low,                     // Gargling
        "burp": .low,                         // Burping
        "hiccup": .low,                       // Hiccups
        "slurp": .low,                        // Slurping
        "finger_snapping": .low,              // Finger snapping
        "booing": .low,                       // Booing
        "yodeling": .low,                     // Yodeling
        "rapping": .low,                      // Rapping
        "dog": .low,                          // General dog sounds
        "dog_bow_wow": .low,                  // Dog bow wow
        "cat": .low,                          // General cat sounds
        "cat_purr": .low,                     // Cat purring
        "bird": .low,                         // General bird sounds
        "bird_vocalization": .low,            // Bird vocalizations
        "bird_chirp_tweet": .low,             // Bird chirping
        "insect": .low,                       // General insect sounds
        "cricket_chirp": .low,                // Cricket chirping
        "mosquito_buzz": .low,                // Mosquito buzzing
        "fly_buzz": .low,                     // Fly buzzing
        "bee_buzz": .low,                     // Bee buzzing
        "frog": .low,                         // General frog sounds
        "frog_croak": .low,                   // Frog croaking
        "silence": .low                       // Silence
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

// MARK: - Profile-Based Alert Configuration
struct AlertConfiguration {
    
    // MARK: - Profile-Based Rule Generation
    
    /// Generates alert rules for all sound classes based on a sensitivity profile
    /// - Parameter profile: The sensitivity profile to use
    /// - Returns: Dictionary of sound class names to their configured AlertRules
    static func generateRules(for profile: SensitivityProfile) -> [String: AlertRule] {
        let alertProfile = AlertProfile.getProfile(for: profile)
        var rules: [String: AlertRule] = [:]
        
        print("🔧 [AlertConfiguration] Generating rules for \(profile.rawValue) profile")
        
        // Create rules for all mapped sound classes
        for (soundClass, tier) in SoundClassMapping.defaultMapping {
            let rule = createRule(for: soundClass, tier: tier, profile: alertProfile)
            rules[soundClass] = rule
        }
        
        print("✅ [AlertConfiguration] Generated \(rules.count) rules for \(profile.rawValue) profile")
        return rules
    }
    
    /// Creates a default alert rule for a sound class based on its tier and profile
    /// - Parameters:
    ///   - soundClass: The sound class name
    ///   - tier: The alert tier
    ///   - profile: The sensitivity profile configuration
    /// - Returns: A configured AlertRule
    private static func createRule(for soundClass: String, tier: AlertTier, profile: AlertProfile) -> AlertRule {
        
        // Get the multiplier for this tier
        let multiplier = getTierMultiplier(tier: tier, profile: profile)
        
        // Calculate thresholds based on profile and tier
        let (onThreshold, offThreshold) = calculateThresholds(tier: tier, profile: profile)
        
        // Calculate timing based on profile and tier
        let (debounceSec, cooldownSec) = calculateTiming(tier: tier, profile: profile, multiplier: multiplier)
        
        // Determine detection method based on profile and tier
        let useWindowMean = shouldUseWindowedDetection(tier: tier, profile: profile)
        
        // Calculate window parameters if using windowed detection
        let (windowSec, windowThresh) = calculateWindowParameters(tier: tier, profile: profile, useWindowMean: useWindowMean)
        
        let rule = AlertRule(
            soundClass: soundClass,
            tier: tier,
            on: onThreshold,
            off: offThreshold,
            debounceSec: debounceSec,
            cooldownSec: cooldownSec,
            frameHz: 1.0,
            useWindowMean: useWindowMean,
            windowSec: windowSec,
            windowThresh: windowThresh
        )
        
        print("   📋 [AlertConfiguration] \(soundClass) (\(tier.rawValue)): on=\(String(format: "%.2f", onThreshold)), off=\(String(format: "%.2f", offThreshold)), debounce=\(String(format: "%.1f", debounceSec))s, cooldown=\(String(format: "%.1f", cooldownSec))s, windowed=\(useWindowMean)")
        
        return rule
    }
    
    /// Gets the timing multiplier for a specific tier based on the profile
    private static func getTierMultiplier(tier: AlertTier, profile: AlertProfile) -> Double {
        switch tier {
        case .critical: return profile.criticalMultiplier
        case .high: return profile.highMultiplier
        case .medium: return profile.mediumMultiplier
        case .low: return profile.lowMultiplier
        }
    }
    
    /// Calculates on/off thresholds based on tier and profile
    private static func calculateThresholds(tier: AlertTier, profile: AlertProfile) -> (on: Double, off: Double) {
        // Start with base thresholds from profile
        var onThreshold = profile.baseOnThreshold
        var offThreshold = profile.baseOffThreshold
        
        // Adjust based on tier (critical gets lower thresholds, low gets higher thresholds)
        switch tier {
        case .critical:
            onThreshold *= 0.85  // Lower threshold for critical (easier to trigger)
            offThreshold *= 0.80 // Lower off threshold
        case .high:
            onThreshold *= 0.95  // Slightly lower threshold
            offThreshold *= 0.90 // Slightly lower off threshold
        case .medium:
            // Keep base thresholds
            break
        case .low:
            onThreshold *= 1.10  // Higher threshold for low tier (harder to trigger)
            offThreshold *= 1.15 // Higher off threshold
        }
        
        // Ensure thresholds are within valid range
        onThreshold = max(0.1, min(0.95, onThreshold))
        offThreshold = max(0.05, min(onThreshold - 0.1, offThreshold))
        
        return (onThreshold, offThreshold)
    }
    
    /// Calculates debounce and cooldown timing based on tier, profile, and multiplier
    private static func calculateTiming(tier: AlertTier, profile: AlertProfile, multiplier: Double) -> (debounceSec: Double, cooldownSec: Double) {
        let baseDebounce = profile.baseDebounceSec * multiplier
        let baseCooldown = profile.baseCooldownSec * multiplier
        
        // Adjust based on tier
        let debounceSec: Double
        let cooldownSec: Double
        
        switch tier {
        case .critical:
            debounceSec = max(0.5, baseDebounce * 0.5)  // Critical gets faster response
            cooldownSec = max(2.0, baseCooldown * 0.5)  // Critical gets shorter cooldown
        case .high:
            debounceSec = max(1.0, baseDebounce * 0.8)  // High gets moderately faster
            cooldownSec = max(5.0, baseCooldown * 0.8)  // High gets moderately shorter cooldown
        case .medium:
            debounceSec = max(1.5, baseDebounce)        // Medium uses base timing
            cooldownSec = max(10.0, baseCooldown)       // Medium uses base timing
        case .low:
            debounceSec = max(2.0, baseDebounce * 1.2)  // Low gets slower response
            cooldownSec = max(15.0, baseCooldown * 1.5) // Low gets longer cooldown
        }
        
        return (debounceSec, cooldownSec)
    }
    
    /// Determines if windowed detection should be used for a tier based on profile
    private static func shouldUseWindowedDetection(tier: AlertTier, profile: AlertProfile) -> Bool {
        switch tier {
        case .critical: return profile.preferWindowedForCritical
        case .high: return profile.preferWindowedForHigh
        case .medium: return profile.preferWindowedForMedium
        case .low: return profile.preferWindowedForLow
        }
    }
    
    /// Calculates window parameters for windowed detection
    private static func calculateWindowParameters(tier: AlertTier, profile: AlertProfile, useWindowMean: Bool) -> (windowSec: Double, windowThresh: Double) {
        if !useWindowMean {
            return (5.0, 0.7) // Default values when not using windowed detection
        }
        
        // Calculate window duration based on tier
        let windowSec: Double
        switch tier {
        case .critical:
            windowSec = 2.0  // Short window for critical
        case .high:
            windowSec = 3.0  // Medium window for high
        case .medium:
            windowSec = 5.0  // Standard window for medium
        case .low:
            windowSec = 8.0  // Long window for low
        }
        
        // Calculate window threshold based on profile base threshold
        let windowThresh = max(0.5, min(0.9, profile.baseOnThreshold * 0.9))
        
        return (windowSec, windowThresh)
    }
    
    // MARK: - Public Interface
    
    /// Returns a rule for a sound class based on the specified profile
    /// - Parameters:
    ///   - soundClass: The sound class name
    ///   - profile: The sensitivity profile to use
    /// - Returns: The AlertRule for the sound class, or nil if not found
    static func getRule(for soundClass: String, profile: SensitivityProfile) -> AlertRule? {
        let rules = generateRules(for: profile)
        return rules[soundClass]
    }
    
    /// Creates a default rule for an unmapped sound class based on profile
    /// - Parameters:
    ///   - soundClass: The sound class name
    ///   - profile: The sensitivity profile to use
    /// - Returns: A default AlertRule with low tier settings
    static func createDefaultRule(for soundClass: String, profile: SensitivityProfile) -> AlertRule {
        let alertProfile = AlertProfile.getProfile(for: profile)
        
        // Use low tier settings for unmapped sounds
        let (onThreshold, offThreshold) = calculateThresholds(tier: .low, profile: alertProfile)
        let (debounceSec, cooldownSec) = calculateTiming(tier: .low, profile: alertProfile, multiplier: alertProfile.lowMultiplier)
        let useWindowMean = shouldUseWindowedDetection(tier: .low, profile: alertProfile)
        let (windowSec, windowThresh) = calculateWindowParameters(tier: .low, profile: alertProfile, useWindowMean: useWindowMean)
        
        return AlertRule(
            soundClass: soundClass,
            tier: .low,  // Default to low tier for unmapped sounds
            on: onThreshold,
            off: offThreshold,
            debounceSec: debounceSec,
            cooldownSec: cooldownSec,
            frameHz: 1.0,
            useWindowMean: useWindowMean,
            windowSec: windowSec,
            windowThresh: windowThresh
        )
    }
    
    /// Returns all available rules for a specific profile
    /// - Parameter profile: The sensitivity profile to use
    /// - Returns: Dictionary of all rules for the profile
    static func getAllRules(for profile: SensitivityProfile) -> [String: AlertRule] {
        return generateRules(for: profile)
    }
}
