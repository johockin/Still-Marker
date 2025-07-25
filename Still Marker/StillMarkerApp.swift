//
//  StillMarkerApp.swift
//  Still Marker
//
//  Created by Claude Code on 2025-01-17.
//

import SwiftUI
import AppKit

@main
struct StillMarkerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    setDefaultWindowSize()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) {
                // Remove default "New" menu item
            }
        }
    }
    
    private func setDefaultWindowSize() {
        // Get the main screen size
        guard let screen = NSScreen.main else { return }
        let screenSize = screen.visibleFrame.size
        
        // Calculate 85% of screen size
        let windowWidth = screenSize.width * 0.85
        let windowHeight = screenSize.height * 0.85
        
        // Set window size and center it
        if let window = NSApplication.shared.windows.first {
            let newFrame = NSRect(
                x: (screenSize.width - windowWidth) / 2 + screen.visibleFrame.origin.x,
                y: (screenSize.height - windowHeight) / 2 + screen.visibleFrame.origin.y,
                width: windowWidth,
                height: windowHeight
            )
            window.setFrame(newFrame, display: true, animate: false)
            
            // Set minimum window size to prevent it from getting too small
            window.minSize = NSSize(width: 800, height: 600)
            
            // Log the screen and window dimensions for debugging
            print("🖥️ Screen size: \(screenSize.width) x \(screenSize.height)")
            print("🪟 Window size set to: \(windowWidth) x \(windowHeight) (85% of screen)")
        }
    }
}