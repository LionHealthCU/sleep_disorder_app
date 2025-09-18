# SomniQ - Sleep Disorder Tracking App

SomniQ is a comprehensive iOS app designed to help users track, monitor, and manage sleep disorders. Built with SwiftUI, it provides a user-friendly interface for recording sleep episodes, capturing audio during sleep, and connecting with a supportive community.

## Features

### 🎯 Core Functionality

- **Setup & Onboarding**: Guided setup process to capture user's usual sleep schedule
- **Audio Recording**: Record sleep sounds throughout the night for analysis
- **Self-Report Episodes**: Log sleep episodes with severity levels and symptoms
- **Data Visualization**: View charts and analytics of sleep patterns
- **Apple Health Integration**: Connect with HealthKit for comprehensive health data
- **Community Support**: Connect with others experiencing similar challenges

### 📊 Sleep Episode Tracking

- **Severity Levels**: Categorize episodes as Mild, Moderate, or Severe
- **Symptom Tracking**: Track common sleep disorder symptoms including:
  - Snoring
  - Gasping for air
  - Restless sleep
  - Insomnia
  - Nightmares
  - Sleepwalking
  - Excessive daytime sleepiness
  - Morning headaches
  - Dry mouth
  - Chest pain

### 🎙️ Audio Recording

- **Night-long Recording**: Capture sleep sounds for analysis
- **Permission Management**: Proper microphone permission handling
- **Recording Playback**: Listen to recorded audio files
- **File Management**: Organize and manage audio recordings

### 📈 Data Analytics

- **Interactive Charts**: Visualize sleep patterns over time
- **Severity Distribution**: Track episode severity trends
- **Symptom Analysis**: Identify most common symptoms
- **Time Range Filtering**: View data for different time periods
- **Statistics Dashboard**: Quick overview of key metrics

### 🏥 Health Integration

- **Apple HealthKit**: Seamless integration with Apple Health
- **Data Import/Export**: Sync sleep data with HealthKit
- **Privacy Focused**: Secure handling of health data
- **Comprehensive Sync**: Link audio recordings with sleep sessions

### 👥 Community Features

- **Support Network**: Connect with others experiencing sleep disorders
- **Experience Sharing**: Share personal experiences and tips
- **Question & Answer**: Ask questions and get community support
- **Post Categories**: Organize content by support, tips, questions, and general
- **Like & Comment**: Engage with community posts

## Technical Architecture

### 🏗️ App Structure

```
SomniQ/
├── Models/
│   └── SleepData.swift          # Core data models
├── Managers/
│   ├── DataManager.swift        # Data persistence & state management
│   └── AudioManager.swift       # Audio recording functionality
├── Views/
│   ├── SetupView.swift          # Initial setup flow
│   ├── DashboardView.swift      # Main dashboard
│   ├── AudioRecordingView.swift # Audio recording interface
│   ├── SelfReportView.swift     # Episode logging
│   ├── DataView.swift           # Analytics & charts
│   ├── HealthKitView.swift      # Health integration
│   └── CommunityView.swift      # Community features
└── SomniQApp.swift              # Main app entry point
```

### 📱 Key Technologies

- **SwiftUI**: Modern declarative UI framework
- **HealthKit**: Apple's health data framework
- **AVFoundation**: Audio recording and playback
- **Charts**: Data visualization (iOS 16+)
- **UserDefaults**: Local data persistence
- **Combine**: Reactive programming patterns

### 🔐 Privacy & Security

- **Local Storage**: All data stored locally on device
- **Encrypted Data**: Health data encrypted at rest
- **Permission-Based**: Explicit user consent for all features
- **Dual Storage**: Local-first with optional cloud backup
- **Firebase Integration**: Secure cloud storage for cross-device sync

## Firebase Data Storage

SomniQ stores data in Firebase using two services:

### Firebase Storage
Audio recordings (.caf files) are stored in Firebase Storage with the following structure:
```
audio_recordings/{userId}/sleep_recording_{userId}_{timestamp}.caf
```

### Firebase Firestore
All other app data is stored in Firestore collections:

```
users/{userId}/
├── episodes/           # Sleep episodes with symptoms and severity
├── recordings/         # Audio recording metadata and summaries
└── preferences/        # User settings and configuration

community_posts/        # Community support posts and comments
```

### Data Types Stored
- **Sleep Episodes**: Date, time, severity level, symptoms, notes
- **Audio Recordings**: Recording metadata, duration, detected sounds, file URLs
- **User Preferences**: App settings, sleep schedule, notification preferences
- **Community Posts**: Support posts, comments, likes, user interactions

All data is stored both locally (for offline access) and in Firebase (for cross-device sync).

## Getting Started

### Prerequisites

- iOS 16.0 or later
- Xcode 14.0 or later
- Swift 5.7 or later

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/SomniQ.git
   ```

2. Open the project in Xcode:
   ```bash
   open SomniQ.xcodeproj
   ```

3. Build and run the app on your device or simulator

### Setup Process

1. **First Launch**: The app will guide you through initial setup
2. **Sleep Schedule**: Enter your usual bedtime and wake time
3. **Permissions**: Grant microphone access for audio recording
4. **HealthKit**: Optionally connect with Apple Health
5. **Ready to Use**: Start tracking your sleep patterns

## Usage Guide

### Recording Sleep Episodes

1. Tap "Self Report" on the dashboard
2. Select the date and time of the episode
3. Choose severity level (Mild/Moderate/Severe)
4. Select symptoms you experienced
5. Add optional notes
6. Save the episode

### Audio Recording

1. Tap "Record Audio" on the dashboard
2. Grant microphone permission if prompted
3. Place device near your bed
4. Tap "Start Recording" before sleep
5. Tap "Stop Recording" when you wake up
6. Save the recording with a name

### Viewing Data

1. Tap the chart icon in the top-right of the dashboard
2. Select time range (Week/Month/3 Months/Year)
3. Choose chart type (Episodes/Severity/Symptoms)
4. View statistics and recent episodes

### Community Features

1. Tap "Community" on the dashboard
2. Browse existing posts
3. Use search and filters to find relevant content
4. Like and comment on posts
5. Create your own posts to share experiences

## Contributing

We welcome contributions to improve SomniQ! Please feel free to:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

### Development Guidelines

- Follow SwiftUI best practices
- Maintain accessibility standards
- Add appropriate error handling
- Include unit tests for new features
- Update documentation as needed

## Privacy Policy

SomniQ is designed with privacy in mind:

- **No Data Collection**: We don't collect or transmit personal data
- **Local Storage**: All data remains on your device
- **Optional HealthKit**: Health integration is completely optional
- **Transparent Permissions**: Clear explanation of why permissions are needed

## Support

If you encounter any issues or have questions:

1. Check the in-app community for help
2. Review the setup guide
3. Ensure all permissions are granted
4. Contact support through the app

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Apple HealthKit team for health data integration
- SwiftUI community for UI best practices
- Sleep disorder community for valuable feedback and insights

---

**Note**: SomniQ is designed to help track sleep patterns and should not replace professional medical advice. Always consult with healthcare providers for medical concerns related to sleep disorders. 