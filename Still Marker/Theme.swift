//
//  Theme.swift
//  Still Marker
//
//  Dark room color system with accessibility compliance.
//

import SwiftUI

enum Theme {
    // Background: not pure black — a warm dark gray that's easier on the eyes
    static let background = Color(red: 0.10, green: 0.10, blue: 0.11)

    // Text hierarchy: WCAG AA compliant contrast ratios on background
    static let text = Color.white.opacity(0.92)            // Primary text
    static let textSecondary = Color.white.opacity(0.70)    // Secondary text, labels
    static let textDim = Color.white.opacity(0.55)          // Tertiary, hints
    static let textGhost = Color.white.opacity(0.35)        // Timestamps, metadata

    // Gold accent
    static let gold = Color(red: 0.82, green: 0.70, blue: 0.36)     // #D1B35C — slightly brighter
    static let goldDim = Color(red: 0.82, green: 0.70, blue: 0.36).opacity(0.45)
}
