import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

// MARK: - Firestore Service
class FirestoreService: ObservableObject {
    static let shared = FirestoreService()
    
    private let db = Firestore.firestore()
    private var currentUserId: String?
    private var cancellables = Set<AnyCancellable>()
    
    // Published properties for real-time updates
    @Published var isOnline = true
    @Published var syncStatus: SyncStatus = .idle
    
    enum SyncStatus {
        case idle
        case syncing
        case success
        case error(String)
    }
    
    private init() {
        setupAuthListener()
        setupNetworkListener()
    }
    
    // MARK: - Authentication Setup
    private func setupAuthListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.currentUserId = user?.uid
                if user != nil {
                    print("FirestoreService: User authenticated, ready for sync")
                } else {
                    print("FirestoreService: User signed out, clearing data")
                }
            }
        }
    }
    
    private func setupNetworkListener() {
        // Monitor network connectivity
        // This is a simplified version - in production you might want to use Network framework
        Timer.publish(every: 5.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                // Simple network check - in production use proper network monitoring
                self?.isOnline = true // Assume online for now
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Collection References
    private func episodesCollection() -> CollectionReference? {
        guard let userId = currentUserId else { return nil }
        return db.collection("users").document(userId).collection("episodes")
    }
    
    private func recordingsCollection() -> CollectionReference? {
        guard let userId = currentUserId else { return nil }
        return db.collection("users").document(userId).collection("recordings")
    }
    
    private func preferencesDocument() -> DocumentReference? {
        guard let userId = currentUserId else { return nil }
        return db.collection("users").document(userId).collection("preferences").document("user_preferences")
    }
    
    private func communityPostsCollection() -> CollectionReference? {
        return db.collection("community_posts")
    }
    
    // MARK: - Sleep Episodes
    func saveEpisode(_ episode: SleepEpisode) async {
        guard let collection = episodesCollection() else { return }
        
        do {
            let episodeData = try encodeEpisode(episode)
            try await collection.document(episode.id.uuidString).setData(episodeData)
            print("Episode saved to Firestore: \(episode.id)")
        } catch {
            print("Failed to save episode to Firestore: \(error)")
            DispatchQueue.main.async {
                self.syncStatus = .error("Failed to save episode: \(error.localizedDescription)")
            }
        }
    }
    
    func loadEpisodes() async -> [SleepEpisode] {
        guard let collection = episodesCollection() else { return [] }
        
        do {
            let snapshot = try await collection.getDocuments()
            let episodes = snapshot.documents.compactMap { doc in
                decodeEpisode(from: doc.data(), id: doc.documentID)
            }
            print("Loaded \(episodes.count) episodes from Firestore")
            return episodes
        } catch {
            print("Failed to load episodes from Firestore: \(error)")
            DispatchQueue.main.async {
                self.syncStatus = .error("Failed to load episodes: \(error.localizedDescription)")
            }
            return []
        }
    }
    
    func deleteEpisode(_ episode: SleepEpisode) async {
        guard let collection = episodesCollection() else { return }
        
        do {
            try await collection.document(episode.id.uuidString).delete()
            print("Episode deleted from Firestore: \(episode.id)")
        } catch {
            print("Failed to delete episode from Firestore: \(error)")
            DispatchQueue.main.async {
                self.syncStatus = .error("Failed to delete episode: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Audio Recordings
    func saveRecording(_ recording: AudioRecording) async {
        guard let collection = recordingsCollection() else { return }
        
        do {
            let recordingData = try encodeRecording(recording)
            try await collection.document(recording.id.uuidString).setData(recordingData)
            print("Recording saved to Firestore: \(recording.id)")
        } catch {
            print("Failed to save recording to Firestore: \(error)")
            DispatchQueue.main.async {
                self.syncStatus = .error("Failed to save recording: \(error.localizedDescription)")
            }
        }
    }
    
    func loadRecordings() async -> [AudioRecording] {
        guard let collection = recordingsCollection() else { return [] }
        
        do {
            let snapshot = try await collection.getDocuments()
            let recordings = snapshot.documents.compactMap { doc in
                decodeRecording(from: doc.data(), id: doc.documentID)
            }
            print("Loaded \(recordings.count) recordings from Firestore")
            return recordings
        } catch {
            print("Failed to load recordings from Firestore: \(error)")
            DispatchQueue.main.async {
                self.syncStatus = .error("Failed to load recordings: \(error.localizedDescription)")
            }
            return []
        }
    }
    
    func deleteRecording(_ recording: AudioRecording) async {
        guard let collection = recordingsCollection() else { return }
        
        do {
            try await collection.document(recording.id.uuidString).delete()
            print("Recording deleted from Firestore: \(recording.id)")
        } catch {
            print("Failed to delete recording from Firestore: \(error)")
            DispatchQueue.main.async {
                self.syncStatus = .error("Failed to delete recording: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - User Preferences
    func savePreferences(_ preferences: UserPreferences) async {
        guard let document = preferencesDocument() else { return }
        
        do {
            let preferencesData = try encodePreferences(preferences)
            try await document.setData(preferencesData)
            print("Preferences saved to Firestore")
        } catch {
            print("Failed to save preferences to Firestore: \(error)")
            DispatchQueue.main.async {
                self.syncStatus = .error("Failed to save preferences: \(error.localizedDescription)")
            }
        }
    }
    
    func loadPreferences() async -> UserPreferences? {
        guard let document = preferencesDocument() else { return nil }
        
        do {
            let snapshot = try await document.getDocument()
            guard snapshot.exists, let data = snapshot.data() else { return nil }
            
            let preferences = decodePreferences(from: data)
            print("Loaded preferences from Firestore")
            return preferences
        } catch {
            print("Failed to load preferences from Firestore: \(error)")
            DispatchQueue.main.async {
                self.syncStatus = .error("Failed to load preferences: \(error.localizedDescription)")
            }
            return nil
        }
    }
    
    // MARK: - Community Posts
    func saveCommunityPost(_ post: CommunityPost) async {
        guard let collection = communityPostsCollection() else { return }
        
        do {
            let postData = try encodeCommunityPost(post)
            try await collection.document(post.id.uuidString).setData(postData)
            print("Community post saved to Firestore: \(post.id)")
        } catch {
            print("Failed to save community post to Firestore: \(error)")
            DispatchQueue.main.async {
                self.syncStatus = .error("Failed to save post: \(error.localizedDescription)")
            }
        }
    }
    
    func loadCommunityPosts() async -> [CommunityPost] {
        guard let collection = communityPostsCollection() else { return [] }
        
        do {
            let snapshot = try await collection.order(by: "date", descending: true).getDocuments()
            let posts = snapshot.documents.compactMap { doc in
                decodeCommunityPost(from: doc.data(), id: doc.documentID)
            }
            print("Loaded \(posts.count) community posts from Firestore")
            return posts
        } catch {
            print("Failed to load community posts from Firestore: \(error)")
            DispatchQueue.main.async {
                self.syncStatus = .error("Failed to load posts: \(error.localizedDescription)")
            }
            return []
        }
    }
    
    func updatePostLikes(_ post: CommunityPost) async {
        guard let collection = communityPostsCollection() else { return }
        
        do {
            try await collection.document(post.id.uuidString).updateData([
                "likes": post.likes
            ])
            print("Post likes updated in Firestore: \(post.id)")
        } catch {
            print("Failed to update post likes in Firestore: \(error)")
            DispatchQueue.main.async {
                self.syncStatus = .error("Failed to update likes: \(error.localizedDescription)")
            }
        }
    }
    
    func addCommentToPost(_ post: CommunityPost, comment: Comment) async {
        guard let collection = communityPostsCollection() else { return }
        
        do {
            let commentsData = post.comments.map { encodeComment($0) }
            try await collection.document(post.id.uuidString).updateData([
                "comments": commentsData
            ])
            print("Comment added to post in Firestore: \(post.id)")
        } catch {
            print("Failed to add comment to post in Firestore: \(error)")
            DispatchQueue.main.async {
                self.syncStatus = .error("Failed to add comment: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Full Sync
    func syncAllData() async {
        guard currentUserId != nil else { return }
        
        DispatchQueue.main.async {
            self.syncStatus = .syncing
        }
        
        // This would be called by DataManager to sync all local data to Firestore
        print("Starting full data sync to Firestore...")
        
        DispatchQueue.main.async {
            self.syncStatus = .success
        }
    }
    
    // MARK: - Encoding/Decoding Helpers
    private func encodeEpisode(_ episode: SleepEpisode) throws -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        
        let data = try encoder.encode(episode)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        // Convert URL to string for Firestore
        var episodeData = json ?? [:]
        if let url = episode.audioRecordingURL {
            episodeData["audioRecordingURL"] = url.absoluteString
        }
        
        return episodeData
    }
    
    private func decodeEpisode(from data: [String: Any], id: String) -> SleepEpisode? {
        var episodeData = data
        
        // Convert URL string back to URL
        if let urlString = episodeData["audioRecordingURL"] as? String {
            episodeData["audioRecordingURL"] = URL(string: urlString)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: episodeData)
            var episode = try decoder.decode(SleepEpisode.self, from: jsonData)
            // Set the ID from Firestore document ID
            episode = SleepEpisode(
                date: episode.date,
                severity: episode.severity,
                symptoms: episode.symptoms,
                notes: episode.notes,
                duration: episode.duration,
                audioRecordingURL: episode.audioRecordingURL
            )
            return episode
        } catch {
            print("Failed to decode episode: \(error)")
            return nil
        }
    }
    
    private func encodeRecording(_ recording: AudioRecording) throws -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        
        let data = try encoder.encode(recording)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        // Convert URL to string for Firestore
        var recordingData = json ?? [:]
        recordingData["fileURL"] = recording.fileURL.absoluteString
        
        return recordingData
    }
    
    private func decodeRecording(from data: [String: Any], id: String) -> AudioRecording? {
        var recordingData = data
        
        // Convert URL string back to URL
        if let urlString = recordingData["fileURL"] as? String,
           let url = URL(string: urlString) {
            recordingData["fileURL"] = url
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: recordingData)
            var recording = try decoder.decode(AudioRecording.self, from: jsonData)
            // Set the ID from Firestore document ID
            recording = AudioRecording(
                date: recording.date,
                duration: recording.duration,
                fileURL: recording.fileURL,
                episodeId: recording.episodeId,
                detectedSounds: recording.detectedSounds,
                mostCommonSound: recording.mostCommonSound,
                totalDetections: recording.totalDetections,
                uniqueSoundCount: recording.uniqueSoundCount
            )
            return recording
        } catch {
            print("Failed to decode recording: \(error)")
            return nil
        }
    }
    
    private func encodePreferences(_ preferences: UserPreferences) throws -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        
        let data = try encoder.encode(preferences)
        return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }
    
    private func decodePreferences(from data: [String: Any]) -> UserPreferences? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            return try decoder.decode(UserPreferences.self, from: jsonData)
        } catch {
            print("Failed to decode preferences: \(error)")
            return nil
        }
    }
    
    private func encodeCommunityPost(_ post: CommunityPost) throws -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        
        let data = try encoder.encode(post)
        return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }
    
    private func decodeCommunityPost(from data: [String: Any], id: String) -> CommunityPost? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            var post = try decoder.decode(CommunityPost.self, from: jsonData)
            // Set the ID from Firestore document ID
            post = CommunityPost(
                author: post.author,
                content: post.content,
                date: post.date,
                likes: post.likes,
                comments: post.comments
            )
            return post
        } catch {
            print("Failed to decode community post: \(error)")
            return nil
        }
    }
    
    private func encodeComment(_ comment: Comment) -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        
        do {
            let data = try encoder.encode(comment)
            return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        } catch {
            print("Failed to encode comment: \(error)")
            return [:]
        }
    }
}
