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
    private let _fullImageURL: URL?
    private var _cachedFullImage: NSImage?
    let formattedTimestamp: String
    
    /// Small thumbnail for grid display (200x112) - always in memory
    var thumbnail: NSImage {
        return _thumbnail
    }
    
    /// Full resolution image for preview/export - loaded on-demand
    var image: NSImage {
        // Try to load from file URL
        if let fullImageURL = _fullImageURL,
           let fullImage = NSImage(contentsOf: fullImageURL) {
            return fullImage
        }
        
        // Return cached image if available (from legacy constructor)
        if let cached = _cachedFullImage {
            return cached
        }
        
        // Fallback to thumbnail
        return _thumbnail
    }
    
    /// Load full image into cache for immediate access (e.g., for export)
    mutating func loadFullImageIntoCache() {
        if _cachedFullImage == nil,
           let fullImageURL = _fullImageURL {
            _cachedFullImage = NSImage(contentsOf: fullImageURL)
        }
    }
    
    /// Clear cached full image to free memory
    mutating func clearFullImageCache() {
        _cachedFullImage = nil
    }
    
    init(timestamp: Double, thumbnail: NSImage, fullImageURL: URL? = nil) {
        self.id = UUID()
        self.timestamp = timestamp
        self._thumbnail = thumbnail
        self._fullImageURL = fullImageURL
        self._cachedFullImage = nil
        self.formattedTimestamp = Frame.formatTimestamp(timestamp)
    }
    
    init(id: UUID, timestamp: Double, thumbnail: NSImage, fullImageURL: URL? = nil) {
        self.id = id
        self.timestamp = timestamp
        self._thumbnail = thumbnail
        self._fullImageURL = fullImageURL
        self._cachedFullImage = nil
        self.formattedTimestamp = Frame.formatTimestamp(timestamp)
    }
    
    /// Legacy constructor for compatibility - keeps full image in memory
    /// Use sparingly, prefer URL-based constructors for better memory management
    init(timestamp: Double, image: NSImage) {
        self.id = UUID()
        self.timestamp = timestamp
        self._thumbnail = image.resizedToFit(maxSize: CGSize(width: 200, height: 112))
        self._fullImageURL = nil
        self._cachedFullImage = image // Keep in cache for compatibility
        self.formattedTimestamp = Frame.formatTimestamp(timestamp)
    }
    
    init(id: UUID, timestamp: Double, image: NSImage) {
        self.id = id
        self.timestamp = timestamp
        self._thumbnail = image.resizedToFit(maxSize: CGSize(width: 200, height: 112))
        self._fullImageURL = nil
        self._cachedFullImage = image // Keep in cache for compatibility
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
    
    /// Create temporary file URL for storing full resolution image
    static func createTempImageURL(for frameID: UUID) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        return tempDir.appendingPathComponent("frame_\(frameID.uuidString).jpg")
    }
    
    /// Save full image to temporary file and return Frame with URL reference
    static func createWithTempFile(timestamp: Double, thumbnail: NSImage, fullImage: NSImage) -> Frame {
        let frameID = UUID()
        let tempURL = createTempImageURL(for: frameID)
        
        // Save full image to temporary file
        if let imageData = fullImage.jpegData(compressionQuality: 0.95) {
            try? imageData.write(to: tempURL)
        }
        
        return Frame(id: frameID, timestamp: timestamp, thumbnail: thumbnail, fullImageURL: tempURL)
    }
}

// MARK: - NSImage Extension for Safety

extension NSImage {
    /// Check if the NSImage is valid and has proper representations
    var isValid: Bool {
        guard !representations.isEmpty else { return false }
        return size.width > 0 && size.height > 0
    }
    
    /// Convert NSImage to JPEG data for file storage
    func jpegData(compressionQuality: CGFloat = 0.8) -> Data? {
        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        return bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality])
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