//
//  Frame.swift
//  Still Marker
//
//  Created by Claude Code on 2025-01-17.
//

import Foundation
import SwiftUI
import AppKit

/// Represents a single extracted frame from a video
struct Frame: Identifiable, Hashable {
    let id: UUID
    let timestamp: Double
    private let _thumbnail: NSImage
    private let _fullImage: NSImage?
    let formattedTimestamp: String
    
    /// Small thumbnail for grid display (200x112)
    var thumbnail: NSImage {
        return _thumbnail
    }
    
    /// Full resolution image for preview/export
    var image: NSImage {
        return _fullImage ?? _thumbnail
    }
    
    init(timestamp: Double, thumbnail: NSImage, fullImage: NSImage? = nil) {
        self.id = UUID()
        self.timestamp = timestamp
        self._thumbnail = thumbnail
        self._fullImage = fullImage
        self.formattedTimestamp = Frame.formatTimestamp(timestamp)
    }
    
    init(id: UUID, timestamp: Double, thumbnail: NSImage, fullImage: NSImage? = nil) {
        self.id = id
        self.timestamp = timestamp
        self._thumbnail = thumbnail
        self._fullImage = fullImage
        self.formattedTimestamp = Frame.formatTimestamp(timestamp)
    }
    
    /// Legacy constructor for compatibility
    init(timestamp: Double, image: NSImage) {
        self.id = UUID()
        self.timestamp = timestamp
        self._thumbnail = image.resizedToFit(maxSize: CGSize(width: 200, height: 112))
        self._fullImage = image
        self.formattedTimestamp = Frame.formatTimestamp(timestamp)
    }
    
    init(id: UUID, timestamp: Double, image: NSImage) {
        self.id = id
        self.timestamp = timestamp
        self._thumbnail = image.resizedToFit(maxSize: CGSize(width: 200, height: 112))
        self._fullImage = image
        self.formattedTimestamp = Frame.formatTimestamp(timestamp)
    }
    
    /// Format timestamp for display (e.g., "00:03.2")
    static func formatTimestamp(_ timestamp: Double) -> String {
        // Round to 1 decimal place to avoid floating point precision issues
        let roundedTimestamp = (timestamp * 10).rounded() / 10
        let minutes = Int(roundedTimestamp / 60)
        let seconds = roundedTimestamp.truncatingRemainder(dividingBy: 60)
        
        return String(format: "%02d:%04.1f", minutes, seconds)
    }
    
    /// Format timestamp for safe filename usage (e.g., "00-03-2")
    static func formatTimestampForFilename(_ timestamp: Double) -> String {
        // Round to 1 decimal place to avoid floating point precision issues
        let roundedTimestamp = (timestamp * 10).rounded() / 10
        let minutes = Int(roundedTimestamp / 60)
        let seconds = roundedTimestamp.truncatingRemainder(dividingBy: 60)
        
        // Replace colons and dots with dashes for safe filenames
        return String(format: "%02d-%04.1f", minutes, seconds)
            .replacingOccurrences(of: ".", with: "-")
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

// MARK: - NSImage Extension for Safety

extension NSImage {
    /// Check if the NSImage is valid and has proper representations
    var isValid: Bool {
        guard !representations.isEmpty else { return false }
        return size.width > 0 && size.height > 0
    }
    
    /// Resize image to fit within maxSize while maintaining aspect ratio
    func resizedToFit(maxSize: CGSize) -> NSImage {
        let originalSize = self.size
        
        // Calculate scale factor to fit within maxSize
        let scaleX = maxSize.width / originalSize.width
        let scaleY = maxSize.height / originalSize.height
        let scale = min(scaleX, scaleY)
        
        let newSize = CGSize(
            width: originalSize.width * scale,
            height: originalSize.height * scale
        )
        
        let resizedImage = NSImage(size: newSize)
        resizedImage.lockFocus()
        
        let context = NSGraphicsContext.current
        context?.imageInterpolation = .high
        
        self.draw(in: NSRect(origin: .zero, size: newSize),
                  from: NSRect(origin: .zero, size: originalSize),
                  operation: .copy,
                  fraction: 1.0)
        
        resizedImage.unlockFocus()
        return resizedImage
    }
}