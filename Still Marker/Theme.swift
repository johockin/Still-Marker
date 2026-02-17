//
//  Theme.swift
//  Still Marker
//
//  Appearance-aware color system. Supports Light / Dark / System.
//

import SwiftUI
import AppKit

// MARK: - Appearance Preference

enum AppAppearance: String, CaseIterable {
    case light
    case dark
    case system

    var label: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }

    static func apply(_ appearance: AppAppearance) {
        switch appearance {
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        case .system:
            NSApp.appearance = nil
        }
    }
}

// MARK: - Theme Colors

enum Theme {
    // Background
    static let background = Color(nsColor: .windowBackgroundColor)

    // Text hierarchy — macOS semantic labels auto-adapt to appearance
    static let text = Color(nsColor: .labelColor)
    static let textSecondary = Color(nsColor: .secondaryLabelColor)
    static let textDim = Color(nsColor: .tertiaryLabelColor)
    static let textGhost = Color(nsColor: .quaternaryLabelColor)

    // Gold accent — darker on light backgrounds for contrast
    static let gold = Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: 0.82, green: 0.70, blue: 0.36, alpha: 1.0)
            : NSColor(red: 0.60, green: 0.48, blue: 0.15, alpha: 1.0)
    }))

    static let goldDim = Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: 0.82, green: 0.70, blue: 0.36, alpha: 0.45)
            : NSColor(red: 0.60, green: 0.48, blue: 0.15, alpha: 0.40)
    }))

    // Surface fills for controls
    static let surfaceHover = Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor.white.withAlphaComponent(0.08)
            : NSColor.black.withAlphaComponent(0.06)
    }))

    static let surfaceSubtle = Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor.white.withAlphaComponent(0.03)
            : NSColor.black.withAlphaComponent(0.03)
    }))

    // Borders for controls
    static let borderHover = Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor.white.withAlphaComponent(0.15)
            : NSColor.black.withAlphaComponent(0.15)
    }))

    static let borderSubtle = Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor.white.withAlphaComponent(0.06)
            : NSColor.black.withAlphaComponent(0.10)
    }))

    // Overlays
    static let overlayScrim = Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor.black.withAlphaComponent(0.7)
            : NSColor.black.withAlphaComponent(0.4)
    }))

    static let toastBackground = Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor.black.withAlphaComponent(0.85)
            : NSColor.white.withAlphaComponent(0.95)
    }))

    // Frame card pillarbox/letterbox fill
    static let frameFill = Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: 0.10, green: 0.10, blue: 0.11, alpha: 1.0)
            : NSColor(red: 0.92, green: 0.92, blue: 0.93, alpha: 1.0)
    }))
}
