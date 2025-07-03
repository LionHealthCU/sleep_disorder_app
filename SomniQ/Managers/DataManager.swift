import Foundation
import SwiftUI
import AVFoundation

class DataManager: ObservableObject {
    @Published var episodes: [SleepEpisode] = []
    @Published var audioRecordings: [AudioRecording] = []
    @Published var userPreferences: UserPreferences?
    @Published var communityPosts: [CommunityPost] = []
    @Published var isSetupComplete: Bool = false
    
    private let episodesKey = "sleepEpisodes"
    private let recordingsKey = "audioRecordings"
    private let preferencesKey = "userPreferences"
    private let postsKey = "communityPosts"
    private let setupKey = "isSetupComplete"
    
    init() {
        loadData()
        loadSampleDataIfNeeded()
    }
    
    // MARK: - Data Persistence
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: episodesKey),
           let episodes = try? JSONDecoder().decode([SleepEpisode].self, from: data) {
            self.episodes = episodes
        }
        
        if let data = UserDefaults.standard.data(forKey: recordingsKey),
           let recordings = try? JSONDecoder().decode([AudioRecording].self, from: data) {
            self.audioRecordings = recordings
        }
        
        if let data = UserDefaults.standard.data(forKey: preferencesKey),
           let preferences = try? JSONDecoder().decode(UserPreferences.self, from: data) {
            self.userPreferences = preferences
        }
        
        if let data = UserDefaults.standard.data(forKey: postsKey),
           let posts = try? JSONDecoder().decode([CommunityPost].self, from: data) {
            self.communityPosts = posts
        }
        
        self.isSetupComplete = UserDefaults.standard.bool(forKey: setupKey)
    }
    
    private func saveData() {
        if let data = try? JSONEncoder().encode(episodes) {
            UserDefaults.standard.set(data, forKey: episodesKey)
        }
        
        if let data = try? JSONEncoder().encode(audioRecordings) {
            UserDefaults.standard.set(data, forKey: recordingsKey)
        }
        
        if let preferences = userPreferences,
           let data = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(data, forKey: preferencesKey)
        }
        
        if let data = try? JSONEncoder().encode(communityPosts) {
            UserDefaults.standard.set(data, forKey: postsKey)
        }
        
        UserDefaults.standard.set(isSetupComplete, forKey: setupKey)
    }
    
    // MARK: - Episode Management
    func addEpisode(_ episode: SleepEpisode) {
        episodes.append(episode)
        saveData()
    }
    
    func updateEpisode(_ episode: SleepEpisode) {
        if let index = episodes.firstIndex(where: { $0.id == episode.id }) {
            episodes[index] = episode
            saveData()
        }
    }
    
    func deleteEpisode(_ episode: SleepEpisode) {
        episodes.removeAll { $0.id == episode.id }
        saveData()
    }
    
    // MARK: - Audio Recording Management
    func addAudioRecording(_ recording: AudioRecording) {
        audioRecordings.append(recording)
        saveData()
    }
    
    func deleteAudioRecording(_ recording: AudioRecording) {
        audioRecordings.removeAll { $0.id == recording.id }
        // Delete the actual file
        try? FileManager.default.removeItem(at: recording.fileURL)
        saveData()
    }
    
    // MARK: - User Preferences
    func updateUserPreferences(_ preferences: UserPreferences) {
        userPreferences = preferences
        isSetupComplete = true
        saveData()
    }
    
    // MARK: - Reset Setup (for testing)
    func resetSetup() {
        isSetupComplete = false
        userPreferences = nil
        UserDefaults.standard.removeObject(forKey: setupKey)
        UserDefaults.standard.removeObject(forKey: preferencesKey)
    }
    
    // MARK: - Community Posts
    func addCommunityPost(_ post: CommunityPost) {
        communityPosts.insert(post, at: 0)
        saveData()
    }
    
    func likePost(_ post: CommunityPost) {
        if let index = communityPosts.firstIndex(where: { $0.id == post.id }) {
            communityPosts[index].likes += 1
            saveData()
        }
    }
    
    func addComment(to post: CommunityPost, comment: Comment) {
        if let index = communityPosts.firstIndex(where: { $0.id == post.id }) {
            communityPosts[index].comments.append(comment)
            saveData()
        }
    }
    
    // MARK: - Analytics
    func getEpisodesForDateRange(from startDate: Date, to endDate: Date) -> [SleepEpisode] {
        return episodes.filter { episode in
            episode.date >= startDate && episode.date <= endDate
        }
    }
    
    func getSeverityDistribution() -> [EpisodeSeverity: Int] {
        var distribution: [EpisodeSeverity: Int] = [:]
        for severity in EpisodeSeverity.allCases {
            distribution[severity] = episodes.filter { $0.severity == severity }.count
        }
        return distribution
    }
    
    func getMostCommonSymptoms() -> [Symptom: Int] {
        var symptomCounts: [Symptom: Int] = [:]
        for episode in episodes {
            for symptom in episode.symptoms {
                symptomCounts[symptom, default: 0] += 1
            }
        }
        return symptomCounts
    }
    
    // MARK: - Sample Data
    private func loadSampleDataIfNeeded() {
        if episodes.isEmpty && isSetupComplete {
            loadSampleEpisodes()
        }
        
        if communityPosts.isEmpty {
            loadSampleCommunityPosts()
        }
    }
    
    private func loadSampleEpisodes() {
        let calendar = Calendar.current
        let now = Date()
        
        let sampleEpisodes = [
            SleepEpisode(
                date: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
                severity: .moderate,
                symptoms: [.snoring, .gasping],
                notes: "Woke up feeling tired, partner noticed snoring"
            ),
            SleepEpisode(
                date: calendar.date(byAdding: .day, value: -3, to: now) ?? now,
                severity: .severe,
                symptoms: [.gasping, .chestPain, .morningHeadache],
                notes: "Very difficult night, felt like I couldn't breathe"
            ),
            SleepEpisode(
                date: calendar.date(byAdding: .day, value: -5, to: now) ?? now,
                severity: .mild,
                symptoms: [.restless],
                notes: "Slept okay but felt restless"
            )
        ]
        
        episodes = sampleEpisodes
        saveData()
    }
    
    private func loadSampleCommunityPosts() {
        let samplePosts = [
            CommunityPost(
                author: "SleepWell",
                content: "Has anyone tried the new CPAP mask? I'm having trouble adjusting to it.",
                likes: 12,
                comments: [
                    Comment(author: "Dreamer", content: "It took me about 2 weeks to get used to it. Hang in there!"),
                    Comment(author: "Restful", content: "Try adjusting the straps, that helped me a lot.")
                ]
            ),
            CommunityPost(
                author: "NightOwl",
                content: "Just had my sleep study results back. Moderate sleep apnea. Starting treatment next week!",
                likes: 8,
                comments: [
                    Comment(author: "SleepWell", content: "Good luck! Treatment made a huge difference for me.")
                ]
            ),
            CommunityPost(
                author: "Restful",
                content: "What's everyone's favorite sleep tracking app? Looking for recommendations.",
                likes: 15,
                comments: [
                    Comment(author: "Dreamer", content: "I love Sleep Cycle, it's really accurate!"),
                    Comment(author: "NightOwl", content: "AutoSleep with Apple Watch is great too.")
                ]
            )
        ]
        
        communityPosts = samplePosts
        saveData()
    }
} 