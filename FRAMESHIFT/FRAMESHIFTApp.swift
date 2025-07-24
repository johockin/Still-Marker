//
//  StillMarkerApp.swift
//  Still Marker
//
//  Created by Claude Code on 2025-01-17.
//

import SwiftUI

@main
struct StillMarkerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) {
                // Remove default "New" menu item
            }
        }
    }
}