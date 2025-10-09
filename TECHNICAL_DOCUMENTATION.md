# SomniQ - Technical Documentation

## Table of Contents
1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Core Components](#core-components)
4. [Data Models](#data-models)
5. [Manager Classes](#manager-classes)
6. [User Interface](#user-interface)
7. [Audio Processing Pipeline](#audio-processing-pipeline)
8. [Alert System](#alert-system)
9. [Data Persistence](#data-persistence)
10. [Firebase Integration](#firebase-integration)
11. [Security & Privacy](#security--privacy)
12. [Dependencies](#dependencies)
13. [Development Guidelines](#development-guidelines)

## Project Overview

SomniQ is a comprehensive iOS sleep disorder tracking application built with SwiftUI that combines real-time audio analysis, user reporting, and community features to help users monitor and understand their sleep patterns.

### Key Features
- **Real-time Audio Recording & Analysis**: Continuous sleep sound monitoring using Apple's SoundAnalysis framework
- **Intelligent Alert System**: Multi-tier alert system with configurable sensitivity profiles
- **Sleep Episode Tracking**: Manual logging of sleep disturbances with severity classification
- **Data Analytics**: Comprehensive sleep pattern analysis and visualization
- **Community Features**: Support network for users to share experiences
- **Health Integration**: Apple HealthKit integration for comprehensive health tracking
- **Cloud Synchronization**: Firebase-based data synchronization across devices

### Technology Stack
- **Platform**: iOS 17.0+
- **Language**: Swift 5.9+
- **Framework**: SwiftUI
- **Backend**: Firebase (Authentication, Firestore, Storage)
- **Audio Processing**: AVFoundation, SoundAnalysis
- **Health Integration**: HealthKit
- **Architecture Pattern**: MVVM with ObservableObject managers

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    SomniQ Application                       │
├─────────────────────────────────────────────────────────────┤
│  Presentation Layer (SwiftUI Views)                        │
│  ├── DashboardView                                         │
│  ├── AudioRecordingView                                    │
│  ├── LoginView                                            │
│  ├── SetupView                                            │
│  ├── CommunityView                                        │
│  └── DataView                                             │
├─────────────────────────────────────────────────────────────┤
│  Business Logic Layer (Manager Classes)                    │
│  ├── AuthManager                                          │
│  ├── AudioManager                                         │
│  ├── DataManager                                          │
│  ├── FirestoreService                                     │
│  └── AlertProcessor                                       │
├─────────────────────────────────────────────────────────────┤
│  Data Layer                                                │
│  ├── Models (SleepData, AlertModels, etc.)                │
│  ├── Local Storage (UserDefaults)                         │
│  └── Remote Storage (Firebase)                            │
├─────────────────────────────────────────────────────────────┤
│  System Integration                                        │
│  ├── AVFoundation                                         │
│  ├── SoundAnalysis                                        │
│  ├── HealthKit                                            │
│  └── Firebase SDK                                         │
└─────────────────────────────────────────────────────────────┘
```

### Design Patterns

1. **MVVM (Model-View-ViewModel)**: Clear separation between UI and business logic
2. **Observer Pattern**: ObservableObject for reactive UI updates
3. **Singleton Pattern**: FirestoreService for centralized data management
4. **Strategy Pattern**: Configurable sensitivity profiles for alert system
5. **Factory Pattern**: Alert rule generation based on sensitivity profiles

## Core Components

### 1. SomniQApp.swift
The main application entry point that:
- Initializes Firebase
- Sets up the main app structure
- Manages authentication state routing
- Coordinates between DataManager and AuthManager

```swift
@main
struct SomniQApp: App {
    @StateObject private var dataManager = DataManager()
    @StateObject private var authManager = AuthManager()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                if dataManager.isSetupComplete {
                    DashboardView(dataManager: dataManager)
                        .environmentObject(authManager)
                } else {
                    SetupView(dataManager: dataManager)
                }
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
    }
}
```

### 2. ContentView.swift
A simple splash/welcome view with the SomniQ branding and description.

## Data Models

### Sleep Episode Model
```swift
struct SleepEpisode: Identifiable, Codable {
    let id = UUID()
    var date: Date
    var severity: EpisodeSeverity
    var symptoms: [Symptom]
    var notes: String
    var duration: TimeInterval?
    var audioRecordingURL: URL?
}
```

**Severity Levels:**
- `mild`: Minor sleep disturbances
- `moderate`: Noticeable sleep issues
- `severe`: Significant sleep problems

**Symptoms:**
- Snoring, Gasping for Air, Restless Sleep
- Insomnia, Nightmares, Sleepwalking
- Excessive Daytime Sleepiness, Morning Headache
- Dry Mouth, Chest Pain

### Audio Recording Model
```swift
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
}
```

### Detected Sound Model
```swift
struct DetectedSound: Identifiable, Codable {
    let id = UUID()
    let soundName: String
    let confidence: Float
    let timestamp: Date
}
```

### User Preferences Model
```swift
struct UserPreferences: Codable {
    var usualBedtime: Date
    var usualWakeTime: Date
    var isHealthKitEnabled: Bool = false
    var notificationsEnabled: Bool = true
    var reminderTime: Date
}
```

### Community Models
```swift
struct CommunityPost: Identifiable, Codable {
    let id = UUID()
    var author: String
    var content: String
    var date: Date
    var likes: Int
    var comments: [Comment]
}

struct Comment: Identifiable, Codable {
    let id = UUID()
    var author: String
    var content: String
    var date: Date
}
```

## Manager Classes

### AuthManager
Handles user authentication using Firebase Auth:

**Key Responsibilities:**
- User sign-in/sign-up functionality
- Authentication state management
- User profile management
- Integration with DataManager for user-specific data

**Key Methods:**
```swift
func signIn(email: String, password: String) async
func signUp(email: String, password: String, displayName: String) async
func signOut()
```

**State Management:**
- `@Published var isAuthenticated: Bool`
- `@Published var currentUser: User?`
- `@Published var isLoading: Bool`
- `@Published var errorMessage: String?`

### AudioManager
Core audio processing and recording functionality:

**Key Responsibilities:**
- Audio recording using AVAudioEngine
- Real-time sound analysis with SoundAnalysis framework
- Alert system integration
- Firebase Storage upload
- Permission management

**Key Components:**
```swift
class AudioManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var detectedSounds: [DetectedSound] = []
    @Published var activeAlerts: [AlertEvent] = []
    
    private var audioEngine: AVAudioEngine?
    private let soundAnalysisManager = SoundAnalysisManager()
    private let alertProcessor = AlertProcessor(profile: .balanced)
}
```

**Audio Pipeline:**
1. **Input**: Microphone via AVAudioEngine
2. **Processing**: Real-time sound classification using SoundAnalysis
3. **Analysis**: Confidence-based sound detection with configurable thresholds
4. **Alerting**: Multi-tier alert system with sensitivity profiles
5. **Storage**: Local file storage + Firebase Storage upload

### DataManager
Central data management and persistence:

**Key Responsibilities:**
- Local data persistence using UserDefaults
- Firebase synchronization
- Data analytics and reporting
- User-specific data isolation

**Key Methods:**
```swift
func addEpisode(_ episode: SleepEpisode)
func addAudioRecording(_ recording: AudioRecording)
func updateUserPreferences(_ preferences: UserPreferences)
func syncFromFirestore() async
func syncToFirestore() async
```

**Data Flow:**
1. **Local First**: All data stored locally in UserDefaults
2. **Background Sync**: Automatic Firebase synchronization
3. **User Isolation**: Data scoped to authenticated user
4. **Conflict Resolution**: Local data takes precedence

### FirestoreService
Firebase integration and cloud synchronization:

**Key Responsibilities:**
- Firestore database operations
- Firebase Storage file management
- Real-time data synchronization
- Network status monitoring

**Data Structure:**
```
users/{userId}/
├── episodes/{episodeId}
├── recordings/{recordingId}
├── preferences/user_preferences
└── community_posts/{postId}
```

### AlertProcessor
Intelligent alert system with configurable sensitivity:

**Key Features:**
- Multi-tier alert system (Low, Medium, High, Critical)
- Configurable sensitivity profiles
- Uncertainty filtering
- Debouncing and cooldown mechanisms
- Windowed vs EMA detection methods

**Alert Tiers:**
- **Critical**: Gasping, screaming, alarms, explosions
- **High**: Snoring, coughing, crying, thunder
- **Medium**: Speech, laughter, door slams, phone rings
- **Low**: Music, ambient sounds, breathing

## User Interface

### DashboardView
Main application interface featuring:
- **Custom SomniQ Branding**: Gradient-based design with moon icon
- **Quick Stats**: Episode count, recordings, weekly activity
- **Central Recording Section**: Prominent recording button
- **Alert Sensitivity Controls**: Real-time sensitivity adjustment
- **Navigation**: Access to data analytics and other features

**Design Philosophy:**
- Dark theme optimized for night use
- Large, accessible buttons for sleep-deprived users
- Real-time feedback and status indicators
- Minimal cognitive load design

### AudioRecordingView
Dedicated recording interface with:
- **Real-time Sound Detection**: Live display of detected sounds
- **Permission Management**: Guided microphone permission flow
- **Recording Controls**: Start/stop with visual feedback
- **Upload Progress**: Firebase Storage upload status
- **Summary View**: Post-recording analysis results

### LoginView
Authentication interface with:
- **Email/Password Authentication**: Firebase Auth integration
- **Sign-up Flow**: New user registration
- **Error Handling**: Clear error messaging
- **Loading States**: Visual feedback during authentication

### SetupView
Onboarding flow with:
- **Welcome Introduction**: Feature overview
- **Sleep Schedule Configuration**: Bedtime and wake time setup
- **Validation**: Schedule consistency checking
- **Completion Confirmation**: Setup success feedback

### CommunityView
Social features including:
- **Post Creation**: Community interaction
- **Search and Filtering**: Content discovery
- **Likes and Comments**: Engagement features
- **Guidelines**: Community standards

## Audio Processing Pipeline

### 1. Audio Capture
```swift
// AVAudioEngine setup for recording
let engine = AVAudioEngine()
let inputNode = engine.inputNode
let format = inputNode.outputFormat(forBus: 0)

// Install tap for real-time processing
inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, time in
    // Process audio buffer
}
```

### 2. Sound Analysis
```swift
// SoundAnalysis framework integration
class SoundAnalysisManager: NSObject, ObservableObject {
    var streamAnalyzer: SNAudioStreamAnalyzer?
    private var classifySoundRequest: SNClassifySoundRequest?
    
    func setupSoundClassifier() {
        classifySoundRequest = try SNClassifySoundRequest(classifierIdentifier: .version1)
        classifySoundRequest?.windowDuration = CMTime(seconds: 1.0, preferredTimescale: 1000)
        classifySoundRequest?.overlapFactor = 0.5
    }
}
```

### 3. Real-time Classification
- **Frame Rate**: 1Hz processing (1-second windows)
- **Overlap**: 50% overlap for continuous detection
- **Confidence Threshold**: Configurable per sensitivity profile
- **Classification Types**: 120+ sound classes from Apple's model

### 4. Alert Processing
- **Multi-tier System**: 4 alert levels based on sound classification
- **Sensitivity Profiles**: 5 configurable profiles (Very Conservative to Very Sensitive)
- **Uncertainty Filtering**: Rejects ambiguous classifications
- **Debouncing**: Prevents alert spam with configurable delays

## Alert System

### Architecture
```
Sound Detection → Classification → Tier Mapping → Alert Processing → User Notification
```

### Sensitivity Profiles

#### Very Conservative
- **Uncertainty Threshold**: 0.7 (high confidence required)
- **Base Thresholds**: 0.9 on, 0.7 off
- **Debounce**: 5.0 seconds
- **Cooldown**: 60.0 seconds
- **Use Case**: Heavy sleepers, minimal disruption preference

#### Conservative
- **Uncertainty Threshold**: 0.6
- **Base Thresholds**: 0.8 on, 0.6 off
- **Debounce**: 3.0 seconds
- **Cooldown**: 30.0 seconds
- **Use Case**: Deep sleepers

#### Balanced (Default)
- **Uncertainty Threshold**: 0.4
- **Base Thresholds**: 0.7 on, 0.5 off
- **Debounce**: 2.0 seconds
- **Cooldown**: 15.0 seconds
- **Use Case**: Average sleepers

#### Sensitive
- **Uncertainty Threshold**: 0.3
- **Base Thresholds**: 0.6 on, 0.4 off
- **Debounce**: 1.0 second
- **Cooldown**: 8.0 seconds
- **Use Case**: Light sleepers

#### Very Sensitive
- **Uncertainty Threshold**: 0.2
- **Base Thresholds**: 0.5 on, 0.3 off
- **Debounce**: 0.5 seconds
- **Cooldown**: 3.0 seconds
- **Use Case**: Very light sleepers, maximum alerting

### Alert Rule Configuration
```swift
struct AlertRule: Codable {
    let soundClass: String
    let tier: AlertTier
    let on: Double          // Activation threshold
    let off: Double         // Deactivation threshold (hysteresis)
    let debounceSec: Double // Time to wait before triggering
    let cooldownSec: Double // Cooldown period after alert
    let frameHz: Double     // Frame rate for calculations
    let useWindowMean: Bool // Use windowed mean vs EMA
    let windowSec: Double   // Window duration
    let windowThresh: Double // Window threshold
}
```

### Sound Class Mapping
The system maps 120+ sound classes to alert tiers:

**Critical Tier (Immediate Attention):**
- Gasping, screaming, sirens, alarms
- Gunshots, explosions, breaking glass
- Smoke detectors, fire alarms

**High Tier (Significant Disruption):**
- Snoring, coughing, crying
- Dog barking, thunder, storms

**Medium Tier (Moderate Disruption):**
- Speech, laughter, door slams
- Phone rings, car horns, helicopters

**Low Tier (Minimal Disruption):**
- Music, ambient sounds, breathing
- Whispering, wind, rain

## Data Persistence

### Local Storage (UserDefaults)
All user data is stored locally using UserDefaults with user-specific keys:

```swift
private func userSpecificKey(_ baseKey: String) -> String {
    guard let userId = currentUserId else { return baseKey }
    return "\(baseKey)_\(userId)"
}
```

**Data Types Stored:**
- Sleep episodes (JSON encoded)
- Audio recordings (metadata only, files stored separately)
- User preferences
- Community posts
- Setup completion status

### File Storage
Audio recordings are stored as CAF files in the Documents directory:
```swift
let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
let recordingName = "sleep_recording_\(Date().timeIntervalSince1970).caf"
let recordingURL = documentsPath.appendingPathComponent(recordingName)
```

### Data Synchronization Strategy
1. **Local First**: All operations work with local data
2. **Background Sync**: Firebase synchronization happens asynchronously
3. **Conflict Resolution**: Local data takes precedence
4. **Offline Support**: Full functionality without network connectivity

## Firebase Integration

### Authentication
- **Provider**: Email/Password authentication
- **User Management**: Profile creation and management
- **Session Persistence**: Automatic sign-in on app launch

### Firestore Database
**Data Structure:**
```
users/{userId}/
├── episodes/{episodeId}/
│   ├── date: timestamp
│   ├── severity: string
│   ├── symptoms: array
│   ├── notes: string
│   ├── duration: number (optional)
│   └── audioRecordingURL: string (optional)
├── recordings/{recordingId}/
│   ├── date: timestamp
│   ├── duration: number
│   ├── fileURL: string
│   ├── detectedSounds: array
│   ├── mostCommonSound: string
│   ├── totalDetections: number
│   └── uniqueSoundCount: number
├── preferences/user_preferences/
│   ├── usualBedtime: timestamp
│   ├── usualWakeTime: timestamp
│   ├── isHealthKitEnabled: boolean
│   ├── notificationsEnabled: boolean
│   └── reminderTime: timestamp
└── community_posts/{postId}/
    ├── author: string
    ├── content: string
    ├── date: timestamp
    ├── likes: number
    └── comments: array
```

### Firebase Storage
Audio files are stored in Firebase Storage with the following structure:
```
audio_recordings/{userId}/{timestamp}.caf
```

**Metadata includes:**
- Recording date
- User ID
- Duration
- Content type (audio/x-caf)

### Real-time Synchronization
- **Automatic Sync**: Background synchronization on user sign-in
- **Conflict Resolution**: Local data precedence
- **Network Monitoring**: Basic connectivity awareness
- **Error Handling**: Graceful degradation on sync failures

## Security & Privacy

### Data Protection
- **Local Encryption**: UserDefaults data is system-encrypted
- **Firebase Security**: Firestore security rules restrict access to user data
- **Audio Privacy**: Audio files stored securely in Firebase Storage
- **User Isolation**: Data scoped to authenticated user only

### Privacy Considerations
- **Minimal Data Collection**: Only necessary sleep-related data
- **User Control**: Users can delete their data at any time
- **Local Processing**: Audio analysis happens on-device
- **No Third-party Sharing**: Data not shared with external parties

### Firebase Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Community posts are readable by all authenticated users
    match /community_posts/{postId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null;
    }
  }
}
```

## Dependencies

### Core iOS Frameworks
- **SwiftUI**: User interface framework
- **AVFoundation**: Audio recording and playback
- **SoundAnalysis**: Real-time sound classification
- **HealthKit**: Health data integration
- **Combine**: Reactive programming

### Firebase SDK
- **FirebaseCore**: Core Firebase functionality
- **FirebaseAuth**: User authentication
- **FirebaseFirestore**: NoSQL database
- **FirebaseStorage**: File storage

### Package Dependencies
```swift
// Package.resolved dependencies
- Firebase iOS SDK (latest)
- Swift Package Manager integration
```

## Development Guidelines

### Code Organization
```
SomniQ/
├── SomniQApp.swift          # App entry point
├── ContentView.swift        # Splash screen
├── Models/                  # Data models
│   ├── SleepData.swift
│   ├── AlertModels.swift
│   ├── SensitivityProfiles.swift
│   └── SoundClassMapping.swift
├── Managers/                # Business logic
│   ├── AuthManager.swift
│   ├── AudioManager.swift
│   ├── DataManager.swift
│   ├── FirestoreService.swift
│   └── AlertProcessor.swift
├── Views/                   # User interface
│   ├── DashboardView.swift
│   ├── AudioRecordingView.swift
│   ├── LoginView.swift
│   ├── SetupView.swift
│   ├── CommunityView.swift
│   ├── DataView.swift
│   ├── SelfReportView.swift
│   └── HealthKitView.swift
└── Assets.xcassets/         # App resources
```

### Coding Standards
1. **Swift Style Guide**: Follow Apple's Swift API Design Guidelines
2. **Documentation**: Comprehensive inline documentation for public APIs
3. **Error Handling**: Proper error handling with user-friendly messages
4. **Testing**: Unit tests for business logic components
5. **Performance**: Efficient audio processing and memory management

### Best Practices
1. **Memory Management**: Proper cleanup of audio resources
2. **Background Processing**: Efficient background audio analysis
3. **User Experience**: Responsive UI with loading states
4. **Accessibility**: VoiceOver support and accessibility labels
5. **Internationalization**: Localized strings and date formatting

### Performance Considerations
- **Audio Processing**: Optimized buffer sizes and processing intervals
- **Memory Usage**: Efficient sound detection storage
- **Battery Life**: Minimal background processing impact
- **Network Usage**: Compressed audio uploads and efficient sync

### Testing Strategy
- **Unit Tests**: Core business logic testing
- **Integration Tests**: Firebase integration testing
- **UI Tests**: Critical user flow testing
- **Audio Tests**: Sound analysis accuracy testing

### Deployment
- **iOS Version**: Minimum iOS 17.0
- **Device Support**: iPhone and iPad
- **App Store**: Health & Fitness category
- **Privacy Policy**: Required for health data collection
- **Firebase Configuration**: Production Firebase project setup

This technical documentation provides a comprehensive overview of the SomniQ application architecture, implementation details, and development guidelines. The system is designed for scalability, maintainability, and user privacy while providing powerful sleep monitoring capabilities.
