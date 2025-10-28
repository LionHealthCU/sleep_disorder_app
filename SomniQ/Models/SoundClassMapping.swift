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

