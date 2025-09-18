import Foundation
import SwiftUI
import AVFoundation
import Combine

class DataManager: ObservableObject {
    @Published var episodes: [SleepEpisode] = []
    @Published var audioRecordings: [AudioRecording] = []
    @Published var userPreferences: UserPreferences?
    @Published var communityPosts: [CommunityPost] = []
    @Published var isSetupComplete: Bool = false
    @Published var isSyncing: Bool = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    
    private var currentUserId: String?
    private let firestoreService = FirestoreService.shared
    private var cancellables = Set<AnyCancellable>()
    private let episodesKey = "sleepEpisodes"
    private let recordingsKey = "audioRecordings"
    private let preferencesKey = "userPreferences"
    private let postsKey = "communityPosts"
    private let setupKey = "isSetupComplete"
    
    init() {
        // Clear mock data only once, then start collecting real user data
        clearMockDataOnce()
        
        loadData()
        // App now collects and stores real user data
        
        // Listen for user authentication changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userDidSignIn(_:)),
            name: .userDidSignIn,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userDidSignOut(_:)),
            name: .userDidSignOut,
            object: nil
        )
        
        // Listen for Firestore sync status changes
        firestoreService.$syncStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                switch status {
                case .syncing:
                    self?.isSyncing = true
                    self?.syncError = nil
                case .success:
                    self?.isSyncing = false
                    self?.lastSyncDate = Date()
                    self?.syncError = nil
                case .error(let error):
                    self?.isSyncing = false
                    self?.syncError = error
                case .idle:
                    self?.isSyncing = false
                }
            }
            .store(in: &cancellables)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func userDidSignIn(_ notification: Notification) {
        if let userId = notification.object as? String {
            setCurrentUser(userId)
        }
    }
    
    @objc private func userDidSignOut(_ notification: Notification) {
        // Clear current user data when signing out
        currentUserId = nil
        episodes = []
        audioRecordings = []
        userPreferences = nil
        communityPosts = []
        isSetupComplete = false
    }
    
    func setCurrentUser(_ userId: String) {
        self.currentUserId = userId
        loadData()
        
        // Perform initial sync from Firestore when user signs in
        Task {
            await syncFromFirestore()
        }
    }
    
    private func userSpecificKey(_ baseKey: String) -> String {
        guard let userId = currentUserId else { return baseKey }
        return "\(baseKey)_\(userId)"
    }
    
    private func clearMockDataOnce() {
        let mockDataClearedKey = "mockDataCleared"
        
        // Only clear mock data if we haven't done it before
        if !UserDefaults.standard.bool(forKey: mockDataClearedKey) {
            // Clear all UserDefaults data to remove any existing mock data
            UserDefaults.standard.removeObject(forKey: episodesKey)
            UserDefaults.standard.removeObject(forKey: recordingsKey)
            UserDefaults.standard.removeObject(forKey: postsKey)
            UserDefaults.standard.removeObject(forKey: preferencesKey)
            UserDefaults.standard.removeObject(forKey: setupKey)
            
            // Mark that we've cleared mock data
            UserDefaults.standard.set(true, forKey: mockDataClearedKey)
            
            print("Cleared mock data once - app now ready to collect real user data")
        }
    }
    
    // MARK: - Data Persistence
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: userSpecificKey(episodesKey)),
           let episodes = try? JSONDecoder().decode([SleepEpisode].self, from: data) {
            self.episodes = episodes
        }
        
        if let data = UserDefaults.standard.data(forKey: userSpecificKey(recordingsKey)),
           let recordings = try? JSONDecoder().decode([AudioRecording].self, from: data) {
            self.audioRecordings = recordings
        }
        
        if let data = UserDefaults.standard.data(forKey: userSpecificKey(preferencesKey)),
           let preferences = try? JSONDecoder().decode(UserPreferences.self, from: data) {
            self.userPreferences = preferences
        }
        
        if let data = UserDefaults.standard.data(forKey: userSpecificKey(postsKey)),
           let posts = try? JSONDecoder().decode([CommunityPost].self, from: data) {
            self.communityPosts = posts
        }
        
        self.isSetupComplete = UserDefaults.standard.bool(forKey: userSpecificKey(setupKey))
    }
    
    private func saveData() {
        if let data = try? JSONEncoder().encode(episodes) {
            UserDefaults.standard.set(data, forKey: userSpecificKey(episodesKey))
        }
        
        if let data = try? JSONEncoder().encode(audioRecordings) {
            UserDefaults.standard.set(data, forKey: userSpecificKey(recordingsKey))
        }
        
        if let preferences = userPreferences,
           let data = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(data, forKey: userSpecificKey(preferencesKey))
        }
        
        if let data = try? JSONEncoder().encode(communityPosts) {
            UserDefaults.standard.set(data, forKey: userSpecificKey(postsKey))
        }
        
        UserDefaults.standard.set(isSetupComplete, forKey: userSpecificKey(setupKey))
    }
    
    // MARK: - Episode Management
    func addEpisode(_ episode: SleepEpisode) {
        episodes.append(episode)
        saveData()
        
        // Sync to Firestore
        Task {
            await firestoreService.saveEpisode(episode)
        }
    }
    
    func updateEpisode(_ episode: SleepEpisode) {
        if let index = episodes.firstIndex(where: { $0.id == episode.id }) {
            episodes[index] = episode
            saveData()
            
            // Sync to Firestore
            Task {
                await firestoreService.saveEpisode(episode)
            }
        }
    }
    
    func deleteEpisode(_ episode: SleepEpisode) {
        episodes.removeAll { $0.id == episode.id }
        saveData()
        
        // Sync to Firestore
        Task {
            await firestoreService.deleteEpisode(episode)
        }
    }
    
    // MARK: - Audio Recording Management
    func addAudioRecording(_ recording: AudioRecording) {
        audioRecordings.append(recording)
        saveData()
        
        // Sync to Firestore
        Task {
            await firestoreService.saveRecording(recording)
        }
    }
    
    func deleteAudioRecording(_ recording: AudioRecording) {
        audioRecordings.removeAll { $0.id == recording.id }
        // Delete the actual file
        try? FileManager.default.removeItem(at: recording.fileURL)
        saveData()
        
        // Sync to Firestore
        Task {
            await firestoreService.deleteRecording(recording)
        }
    }
    
    // MARK: - User Preferences
    func updateUserPreferences(_ preferences: UserPreferences) {
        userPreferences = preferences
        isSetupComplete = true
        saveData()
        
        // Sync to Firestore
        Task {
            await firestoreService.savePreferences(preferences)
        }
    }
    
    // MARK: - Reset Setup (for testing)
    func resetSetup() {
        isSetupComplete = false
        userPreferences = nil
        UserDefaults.standard.removeObject(forKey: userSpecificKey(setupKey))
        UserDefaults.standard.removeObject(forKey: userSpecificKey(preferencesKey))
    }
    
    // MARK: - Community Posts
    func addCommunityPost(_ post: CommunityPost) {
        communityPosts.insert(post, at: 0)
        saveData()
        
        // Sync to Firestore
        Task {
            await firestoreService.saveCommunityPost(post)
        }
    }
    
    func likePost(_ post: CommunityPost) {
        if let index = communityPosts.firstIndex(where: { $0.id == post.id }) {
            communityPosts[index].likes += 1
            saveData()
            
            // Sync to Firestore
            Task {
                await firestoreService.updatePostLikes(communityPosts[index])
            }
        }
    }
    
    func addComment(to post: CommunityPost, comment: Comment) {
        if let index = communityPosts.firstIndex(where: { $0.id == post.id }) {
            communityPosts[index].comments.append(comment)
            saveData()
            
            // Sync to Firestore
            Task {
                await firestoreService.addCommentToPost(communityPosts[index], comment: comment)
            }
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
    
    // MARK: - Firestore Sync Methods
    func syncFromFirestore() async {
        guard currentUserId != nil else { return }
        
        print("Starting sync from Firestore...")
        
        // Load data from Firestore
        let firestoreEpisodes = await firestoreService.loadEpisodes()
        let firestoreRecordings = await firestoreService.loadRecordings()
        let firestorePreferences = await firestoreService.loadPreferences()
        let firestorePosts = await firestoreService.loadCommunityPosts()
        
        // Update local data
        DispatchQueue.main.async {
            self.episodes = firestoreEpisodes
            self.audioRecordings = firestoreRecordings
            self.userPreferences = firestorePreferences
            self.communityPosts = firestorePosts
            
            // Save to local storage
            self.saveData()
            
            print("Sync from Firestore completed")
        }
    }
    
    func syncToFirestore() async {
        guard currentUserId != nil else { return }
        
        print("Starting sync to Firestore...")
        
        // Sync all local data to Firestore
        for episode in episodes {
            await firestoreService.saveEpisode(episode)
        }
        
        for recording in audioRecordings {
            await firestoreService.saveRecording(recording)
        }
        
        if let preferences = userPreferences {
            await firestoreService.savePreferences(preferences)
        }
        
        for post in communityPosts {
            await firestoreService.saveCommunityPost(post)
        }
        
        print("Sync to Firestore completed")
    }
    
    func performFullSync() async {
        guard currentUserId != nil else { return }
        
        print("Starting full bidirectional sync...")
        
        // First, sync from Firestore to get latest data
        await syncFromFirestore()
        
        // Then, sync local changes back to Firestore
        await syncToFirestore()
        
        print("Full sync completed")
    }
    
    // MARK: - Sample Data (Removed)
    // All sample data loading has been removed to ensure analytics use real recording data only
    // Users will see empty states until they create real recordings and episodes
} 