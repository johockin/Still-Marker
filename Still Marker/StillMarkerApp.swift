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
    init() {
        // Apply saved appearance preference before first render to avoid flash
        let stored = UserDefaults.standard.string(forKey: "appearance") ?? AppAppearance.light.rawValue
        if let pref = AppAppearance(rawValue: stored) {
            AppAppearance.apply(pref)
        }
    }

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

        Settings {
            SettingsView()
        }
    }

    private func setDefaultWindowSize() {
        guard let screen = NSScreen.main else { return }
        let screenSize = screen.visibleFrame.size

        let windowWidth = screenSize.width * 0.85
        let windowHeight = screenSize.height * 0.85

        if let window = NSApplication.shared.windows.first {
            let newFrame = NSRect(
                x: (screenSize.width - windowWidth) / 2 + screen.visibleFrame.origin.x,
                y: (screenSize.height - windowHeight) / 2 + screen.visibleFrame.origin.y,
                width: windowWidth,
                height: windowHeight
            )
            window.setFrame(newFrame, display: true, animate: false)

            window.minSize = NSSize(width: 800, height: 600)
            window.backgroundColor = .windowBackgroundColor
        }
    }
}
