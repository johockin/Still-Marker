//
//  Frame.swift
//  FRAMESHIFT
//
//  Created by Claude Code on 2025-01-17.
//

import Foundation
import SwiftUI

/// Represents a single extracted frame from a video
struct Frame: Identifiable, Hashable {
    let id = UUID()
    let timestamp: Double
    let image: NSImage
    let formattedTimestamp: String
    
    init(timestamp: Double, image: NSImage) {
        self.timestamp = timestamp
        self.image = image
        self.formattedTimestamp = Frame.formatTimestamp(timestamp)
    }
    
    /// Format timestamp for display (e.g., "1:23.5")
    private static func formatTimestamp(_ timestamp: Double) -> String {
        let minutes = Int(timestamp / 60)
        let seconds = timestamp.truncatingRemainder(dividingBy: 60)
        
        if minutes > 0 {
            return String(format: "%d:%04.1f", minutes, seconds)
        } else {
            return String(format: "%.1fs", seconds)
        }
    }
    
    /// Hash for Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    /// Equality for Hashable conformance
    static func == (lhs: Frame, rhs: Frame) -> Bool {
        lhs.id == rhs.id
    }
}