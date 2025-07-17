//
//  FRAMESHIFTApp.swift
//  FRAMESHIFT
//
//  Created by Claude Code on 2025-01-17.
//

import SwiftUI

@main
struct FRAMESHIFTApp: App {
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