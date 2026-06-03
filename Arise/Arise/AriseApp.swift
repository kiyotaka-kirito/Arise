//
//  AriseApp.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 01/06/2026.
//

import SwiftUI
import Firebase

@main
struct AriseApp: App {
    
    // MARK: - Root Dependencies
    private let container = AppDependencyContainer()
    private let coordinator: AppCoordinator
    
    init() {
        FirebaseApp.configure()
        
        coordinator = AppCoordinator(container: container)
        coordinator.start()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(
                coordinator: coordinator,
                container: container
            )
        }
    }
}
