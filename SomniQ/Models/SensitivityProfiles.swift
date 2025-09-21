import Foundation

// MARK: - Sensitivity Profile Types
/// Defines different sensitivity levels for the alert system
enum SensitivityProfile: String, CaseIterable, Codable {
    case veryConservative = "Very Conservative"
    case conservative = "Conservative" 
    case balanced = "Balanced"
    case sensitive = "Sensitive"
    case verySensitive = "Very Sensitive"
    
    /// User-friendly description of what each profile does
    var description: String {
        switch self {
        case .veryConservative:
            return "Minimal alerts - only for clear, sustained sounds. Best for heavy sleepers."
        case .conservative:
            return "Fewer alerts with longer delays. Good for deep sleepers."
        case .balanced:
            return "Balanced sensitivity - default settings for most users."
        case .sensitive:
            return "More alerts with faster response. Good for light sleepers."
        case .verySensitive:
            return "Maximum sensitivity - alerts for most sounds quickly. Best for very light sleepers."
        }
    }
    
    /// Numeric value for slider (0.0 to 1.0)
    var sliderValue: Double {
        switch self {
        case .veryConservative: return 0.0
        case .conservative: return 0.25
        case .balanced: return 0.5
        case .sensitive: return 0.75
        case .verySensitive: return 1.0
        }
    }
    
    /// Create profile from slider value
    static func fromSliderValue(_ value: Double) -> SensitivityProfile {
        switch value {
        case 0.0..<0.125: return .veryConservative
        case 0.125..<0.375: return .conservative
        case 0.375..<0.625: return .balanced
        case 0.625..<0.875: return .sensitive
        default: return .verySensitive
        }
    }
}

// MARK: - Alert Profile Configuration
/// Contains all the parameters that define how alerts behave
struct AlertProfile: Codable {
    let name: SensitivityProfile
    
    // Uncertainty filtering parameters
    let uncertaintyThreshold: Double      // Minimum confidence to not be "uncertain"
    let uncertaintyDifference: Double     // Minimum difference between top 2 classifications
    
    // Tier-specific multipliers for timing
    let criticalMultiplier: Double        // Multiplier for critical tier timing
    let highMultiplier: Double           // Multiplier for high tier timing  
    let mediumMultiplier: Double         // Multiplier for medium tier timing
    let lowMultiplier: Double            // Multiplier for low tier timing
    
    // Base thresholds (will be adjusted by tier)
    let baseOnThreshold: Double          // Base activation threshold
    let baseOffThreshold: Double         // Base deactivation threshold
    let baseDebounceSec: Double          // Base debounce time
    let baseCooldownSec: Double          // Base cooldown time
    
    // Detection method preferences
    let preferWindowedForLow: Bool       // Use windowed detection for low tier
    let preferWindowedForMedium: Bool    // Use windowed detection for medium tier
    let preferWindowedForHigh: Bool      // Use windowed detection for high tier
    let preferWindowedForCritical: Bool  // Use windowed detection for critical tier
}

// MARK: - Default Profile Configurations
extension AlertProfile {
    
    /// Creates the default profile configurations for each sensitivity level
    static let profiles: [SensitivityProfile: AlertProfile] = [
        .veryConservative: AlertProfile(
            name: .veryConservative,
            uncertaintyThreshold: 0.7,      // Very high confidence required
            uncertaintyDifference: 0.3,     // Large gap between top 2
            criticalMultiplier: 1.0,        // Keep critical fast
            highMultiplier: 2.0,            // Make high tier slower
            mediumMultiplier: 3.0,          // Make medium tier much slower
            lowMultiplier: 4.0,             // Make low tier very slow
            baseOnThreshold: 0.9,           // Very high threshold
            baseOffThreshold: 0.7,          // High off threshold
            baseDebounceSec: 5.0,           // Long debounce
            baseCooldownSec: 60.0,          // Long cooldown
            preferWindowedForLow: true,     // Use windowed for low tier
            preferWindowedForMedium: true,  // Use windowed for medium tier
            preferWindowedForHigh: true,    // Use windowed for high tier
            preferWindowedForCritical: false // Keep critical immediate
        ),
        
        .conservative: AlertProfile(
            name: .conservative,
            uncertaintyThreshold: 0.6,      // High confidence required
            uncertaintyDifference: 0.25,    // Good gap between top 2
            criticalMultiplier: 1.0,        // Keep critical fast
            highMultiplier: 1.5,            // Make high tier slower
            mediumMultiplier: 2.0,          // Make medium tier slower
            lowMultiplier: 2.5,             // Make low tier slower
            baseOnThreshold: 0.8,           // High threshold
            baseOffThreshold: 0.6,          // Medium-high off threshold
            baseDebounceSec: 3.0,           // Medium debounce
            baseCooldownSec: 30.0,          // Medium cooldown
            preferWindowedForLow: true,     // Use windowed for low tier
            preferWindowedForMedium: true,  // Use windowed for medium tier
            preferWindowedForHigh: false,   // Use EMA for high tier
            preferWindowedForCritical: false // Keep critical immediate
        ),
        
        .balanced: AlertProfile(
            name: .balanced,
            uncertaintyThreshold: 0.4,      // Current default
            uncertaintyDifference: 0.15,    // Current default
            criticalMultiplier: 1.0,        // Keep critical fast
            highMultiplier: 1.0,            // Keep high tier as-is
            mediumMultiplier: 1.0,          // Keep medium tier as-is
            lowMultiplier: 1.0,             // Keep low tier as-is
            baseOnThreshold: 0.7,           // Current default
            baseOffThreshold: 0.5,          // Current default
            baseDebounceSec: 2.0,           // Current default
            baseCooldownSec: 15.0,          // Current default
            preferWindowedForLow: true,     // Use windowed for low tier
            preferWindowedForMedium: true,  // Use windowed for medium tier
            preferWindowedForHigh: true,    // Use windowed for high tier
            preferWindowedForCritical: false // Keep critical immediate
        ),
        
        .sensitive: AlertProfile(
            name: .sensitive,
            uncertaintyThreshold: 0.3,      // Lower confidence required
            uncertaintyDifference: 0.1,     // Smaller gap between top 2
            criticalMultiplier: 0.5,        // Make critical even faster
            highMultiplier: 0.7,            // Make high tier faster
            mediumMultiplier: 0.8,          // Make medium tier faster
            lowMultiplier: 1.0,             // Keep low tier as-is
            baseOnThreshold: 0.6,           // Lower threshold
            baseOffThreshold: 0.4,          // Lower off threshold
            baseDebounceSec: 1.0,           // Shorter debounce
            baseCooldownSec: 8.0,           // Shorter cooldown
            preferWindowedForLow: false,    // Use EMA for low tier
            preferWindowedForMedium: false, // Use EMA for medium tier
            preferWindowedForHigh: false,   // Use EMA for high tier
            preferWindowedForCritical: false // Keep critical immediate
        ),
        
        .verySensitive: AlertProfile(
            name: .verySensitive,
            uncertaintyThreshold: 0.2,      // Very low confidence required
            uncertaintyDifference: 0.05,    // Very small gap between top 2
            criticalMultiplier: 0.3,        // Make critical very fast
            highMultiplier: 0.5,            // Make high tier very fast
            mediumMultiplier: 0.6,          // Make medium tier fast
            lowMultiplier: 0.8,             // Make low tier faster
            baseOnThreshold: 0.5,           // Very low threshold
            baseOffThreshold: 0.3,          // Very low off threshold
            baseDebounceSec: 0.5,           // Very short debounce
            baseCooldownSec: 3.0,           // Very short cooldown
            preferWindowedForLow: false,    // Use EMA for all tiers
            preferWindowedForMedium: false, // Use EMA for all tiers
            preferWindowedForHigh: false,   // Use EMA for all tiers
            preferWindowedForCritical: false // Keep critical immediate
        )
    ]
    
    /// Get profile for a specific sensitivity level
    static func getProfile(for sensitivity: SensitivityProfile) -> AlertProfile {
        return profiles[sensitivity] ?? profiles[.balanced]!
    }
}
