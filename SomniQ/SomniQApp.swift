//
//  SomniQApp.swift
//  SomniQ
//
//  Created by Maximilian Comfere on 6/30/25.
//

import SwiftUI
import FirebaseCore

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
