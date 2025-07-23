//
//  SomniQApp.swift
//  SomniQ
//
//  Created by Maximilian Comfere on 6/30/25.
//

import SwiftUI

@main
struct SomniQApp: App {
    @StateObject private var dataManager = DataManager()
    
    var body: some Scene {
        WindowGroup {
            if dataManager.isSetupComplete {
                DashboardView(dataManager: dataManager)
            } else {
                SetupView(dataManager: dataManager)
            }
        }
    }
}
