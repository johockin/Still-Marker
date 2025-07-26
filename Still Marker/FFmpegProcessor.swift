//
//  FFmpegProcessor.swift
//  Still Marker
//
//  Created by Claude Code on 2025-01-17.
//

import Foundation
import AppKit
import AVFoundation

class FFmpegProcessor: ObservableObject {
    private lazy var ffmpegPath: String = {
        guard let path = Bundle.main.path(forResource: "ffmpeg", ofType: nil) else {
            fatalError("FFmpeg binary not found in app bundle")
        }
        return path
    }()
    
    /// Pre-warm FFmpeg path during initialization
    init() {
        // Access ffmpegPath to trigger lazy initialization
        _ = ffmpegPath
    }
    
    /// Extract frames from video using adaptive interval selection
    func extractFrames(from videoURL: URL, 
                      offset: Double = 0.0,
                      progressCallback: @escaping (Double, String) -> Void) async throws -> [Frame] {
        
        progressCallback(0.1, "Analyzing video...")
        
        // Get video duration first
        let duration = try await getVideoDuration(videoURL: videoURL)
        progressCallback(0.2, "Video duration: \(Int(duration))s")
        
        // Calculate intelligent interval based on video duration
        let adaptiveInterval = calculateAdaptiveInterval(duration: duration)
        let estimatedFrames = Int(duration / adaptiveInterval)
        progressCallback(0.25, "Optimized for \(estimatedFrames) frames every \(String(format: "%.1f", adaptiveInterval))s")
        
        // Calculate timestamps for frame extraction using adaptive interval
        let timestamps = calculateTimestamps(duration: duration, offset: offset, interval: adaptiveInterval)
        progressCallback(0.3, "Extracting \(timestamps.count) frames...")
        
        // Create temporary directory for frames
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("stillmarker-\(UUID().uuidString)")
        
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        var frames: [Frame] = []
        
        // Extract frames
        for (index, timestamp) in timestamps.enumerated() {
            let progress = 0.3 + (Double(index) / Double(timestamps.count)) * 0.6
            progressCallback(progress, "Extracting frame at \(String(format: "%.1f", timestamp))s...")
            
            let frameURL = tempDir.appendingPathComponent("frame_\(Frame.formatTimestampForFilename(timestamp)).jpg")
            
            do {
                try await extractSingleFrame(
                    from: videoURL,
                    at: timestamp,
                    outputURL: frameURL
                )
                
                // Load the extracted frame ONLY to create thumbnail
                if let fullImage = NSImage(contentsOf: frameURL) {
                    // Generate thumbnail for memory efficiency
                    let thumbnail = fullImage.resizedToFit(maxSize: CGSize(width: 200, height: 112))
                    
                    // Create permanent file for full image storage
                    let frameID = UUID()
                    let permanentURL = Frame.createTempImageURL(for: frameID)
                    
                    // Move the extracted file to permanent location
                    try? FileManager.default.moveItem(at: frameURL, to: permanentURL)
                    
                    // Create frame with URL reference (no full image in memory)
                    let frame = Frame(id: frameID, timestamp: timestamp, thumbnail: thumbnail, fullImageURL: permanentURL) 
                    frames.append(frame)
                } else {
                    // Clean up failed extraction file
                    try? FileManager.default.removeItem(at: frameURL)
                }
                
            } catch {
                print("Failed to extract frame at \(timestamp)s: \(error)")
            }
        }
        
        // Clean up temp directory
        try? FileManager.default.removeItem(at: tempDir)
        
        progressCallback(1.0, "Extraction complete!")
        return frames
    }
    
    /// Get video duration using AVFoundation (fast!)
    private func getVideoDuration(videoURL: URL) async throws -> Double {
        let asset = AVAsset(url: videoURL)
        
        do {
            let duration = try await asset.load(.duration)
            let durationSeconds = CMTimeGetSeconds(duration)
            return durationSeconds
        } catch {
            print("❌ Failed to get duration via AVFoundation: \(error)")
            throw FFmpegError.invalidDuration
        }
    }
    
    /// Parse duration string in format HH:MM:SS.ss to seconds
    private func parseDurationString(_ durationString: String) -> Double? {
        let components = durationString.split(separator: ":")
        guard components.count >= 3 else { return nil }
        
        guard let hours = Double(components[0]),
              let minutes = Double(components[1]),
              let seconds = Double(components[2]) else {
            return nil
        }
        
        return hours * 3600 + minutes * 60 + seconds
    }
    
    /// Extract a single frame at specified timestamp
    func extractSingleFrame(from videoURL: URL, at timestamp: Double, outputURL: URL) async throws {
        let process = Process()
        let errorPipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: ffmpegPath)
        process.arguments = [
            "-ss", String(timestamp),  // FAST SEEK: Move -ss BEFORE -i for direct seeking
            "-i", videoURL.path,
            "-vframes", "1",
            "-q:v", "2", // High quality JPEG (scale 2-31, lower is better)
            "-y", // Overwrite output file
            outputURL.path
        ]
        process.standardOutput = Pipe() // Suppress output
        process.standardError = errorPipe // Capture error output for debugging
        
        return try await withCheckedThrowingContinuation { continuation in
            do {
                print("🚀 FFmpeg FAST-SEEK Command: \(ffmpegPath) -ss \(timestamp) -i \"\(videoURL.path)\" -vframes 1 -q:v 2 -y \"\(outputURL.path)\"")
                try process.run()
                
                process.terminationHandler = { process in
                    if process.terminationStatus == 0 {
                        print("✅ Frame extracted successfully at \(timestamp)s")
                        continuation.resume()
                    } else {
                        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                        let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
                        print("❌ Frame extraction failed at \(timestamp)s: \(errorOutput)")
                        continuation.resume(throwing: FFmpegError.frameExtractionFailed)
                    }
                }
            } catch {
                print("❌ Failed to run FFmpeg frame extraction: \(error)")
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Calculate adaptive interval based on video duration
    /// Philosophy: ~30 frames per video for optimal coverage without overwhelming the user
    private func calculateAdaptiveInterval(duration: Double) -> Double {
        let targetFrames = 30.0
        let maxFrames = 40.0
        let minInterval = 0.33  // Don't extract more than 3 frames per second
        
        // Very short videos (<30s): every 1 second for granular coverage
        if duration < 30 {
            return 1.0
        }
        
        // Medium videos (30s - 5min): aim for ~30 frames with dynamic interval
        if duration <= 300 {  // 5 minutes
            let calculatedInterval = duration / targetFrames
            // Round to 1 decimal place for clean timestamps
            return max(round(calculatedInterval * 10) / 10, minInterval)
        }
        
        // Long videos (>5min): cap at 40 frames for performance
        let calculatedInterval = duration / maxFrames
        return max(round(calculatedInterval * 10) / 10, minInterval)
    }
    
    /// Calculate timestamps for frame extraction
    private func calculateTimestamps(duration: Double, offset: Double, interval: Double) -> [Double] {
        var timestamps: [Double] = []
        let startTime = max(0, offset)
        let endTime = duration
        
        var currentTime = startTime
        while currentTime < endTime {
            timestamps.append(currentTime)
            currentTime += interval
        }
        
        return timestamps
    }
}

enum FFmpegError: Error, LocalizedError {
    case binaryNotFound
    case invalidDuration
    case frameExtractionFailed
    
    var errorDescription: String? {
        switch self {
        case .binaryNotFound:
            return "FFmpeg binary not found in app bundle"
        case .invalidDuration:
            return "Could not determine video duration"
        case .frameExtractionFailed:
            return "Failed to extract frame from video"
        }
    }
}