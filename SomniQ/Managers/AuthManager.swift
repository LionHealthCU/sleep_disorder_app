import Foundation
import SwiftUI
import FirebaseAuth
import Combine

extension Notification.Name {
    static let userDidSignIn = Notification.Name("userDidSignIn")
    static let userDidSignOut = Notification.Name("userDidSignOut")
}

class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    struct User: Codable {
        let id: String
        let email: String
        let displayName: String
    }
    
    init() {
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                if let firebaseUser = user {
                    self?.currentUser = User(
                        id: firebaseUser.uid,
                        email: firebaseUser.email ?? "",
                        displayName: firebaseUser.displayName ?? firebaseUser.email?.components(separatedBy: "@").first ?? "User"
                    )
                    self?.isAuthenticated = true
                    
                    // Notify DataManager about the current user
                    NotificationCenter.default.post(name: .userDidSignIn, object: firebaseUser.uid)
                } else {
                    self?.currentUser = nil
                    self?.isAuthenticated = false
                    
                    // Notify DataManager that user signed out
                    NotificationCenter.default.post(name: .userDidSignOut, object: nil)
                }
            }
        }
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await Auth.auth().signIn(withEmail: email, password: password)
            DispatchQueue.main.async {
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func signUp(email: String, password: String, displayName: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            
            // Update display name
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()
            
            DispatchQueue.main.async {
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    var userDisplayName: String {
        return currentUser?.displayName ?? "User"
    }
    
    var userEmail: String {
        return currentUser?.email ?? ""
    }
}
