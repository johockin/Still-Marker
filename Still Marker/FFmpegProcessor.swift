//
//  FFmpegProcessor.swift
//  Still Marker
//
//  Created by Claude Code on 2025-01-17.
//

import Foundation
import AppKit
import AVFoundation

// Thread-safe state manager for continuation resume
private final class ResumeState: @unchecked Sendable {
    let lock = NSLock()
    var hasResumed = false
    
    func attemptResume() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if hasResumed { return false }
        hasResumed = true
        return true
    }
}

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

        // Get video duration via FFmpeg (no AVFoundation dependency — this matters
        // when we're the fallback for formats AVFoundation can't read at all).
        let duration = try await getDurationViaFFmpeg(videoURL: videoURL)
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
                    outputURL: frameURL,
                    lossless: false   // batch thumbnail intermediate; export uses PNG re-extract path
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
    
    /// Get video duration via FFmpeg by parsing stderr from `ffmpeg -i file`.
    /// Always works for any container FFmpeg recognizes — does not depend on AVFoundation.
    /// FFmpeg exits with status 1 when no output is specified; that's expected.
    func getDurationViaFFmpeg(videoURL: URL) async throws -> Double {
        let process = Process()
        let stderrPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: ffmpegPath)
        process.arguments = ["-i", videoURL.path]
        process.standardOutput = Pipe()
        process.standardError = stderrPipe

        return try await withCheckedThrowingContinuation { continuation in
            let state = ResumeState()

            process.terminationHandler = { _ in
                guard state.attemptResume() else { return }

                let errData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                let errStr = String(data: errData, encoding: .utf8) ?? ""

                // Look for "Duration: HH:MM:SS.cc"
                if let range = errStr.range(of: #"Duration:\s+(\d+):(\d+):(\d+\.\d+)"#, options: .regularExpression) {
                    let match = String(errStr[range])
                        .replacingOccurrences(of: "Duration:", with: "")
                        .trimmingCharacters(in: .whitespaces)
                    if let duration = self.parseDurationString(match) {
                        continuation.resume(returning: duration)
                        return
                    }
                }
                continuation.resume(throwing: FFmpegError.invalidDuration)
            }

            DispatchQueue.global().asyncAfter(deadline: .now() + 5.0) {
                guard state.attemptResume() else { return }
                process.terminate()
                continuation.resume(throwing: FFmpegError.invalidDuration)
            }

            do {
                try process.run()
            } catch {
                guard state.attemptResume() else { return }
                continuation.resume(throwing: error)
            }
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
    
    /// Extract a single frame at specified timestamp.
    /// `lossless: true` writes PNG (used for export). `lossless: false` writes high-quality
    /// JPEG (used for the in-batch thumbnail intermediate, where the JPEG is decoded to a
    /// thumbnail and then deleted).
    func extractSingleFrame(from videoURL: URL, at timestamp: Double, outputURL: URL, lossless: Bool = true) async throws {
        let process = Process()
        let errorPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: ffmpegPath)
        let codecArgs: [String] = lossless
            ? ["-c:v", "png"]              // lossless PNG; matches output URL ending in .png
            : ["-q:v", "2"]                // high-quality JPEG (scale 2-31, lower is better)
        process.arguments = [
            "-ss", String(timestamp),       // FAST SEEK: -ss before -i = direct seek
            "-i", videoURL.path,
            "-vframes", "1"
        ] + codecArgs + [
            "-y",                           // Overwrite output file
            outputURL.path
        ]
        process.standardOutput = Pipe() // Suppress output
        process.standardError = errorPipe // Capture error output for debugging
        
        return try await withCheckedThrowingContinuation { continuation in
            let state = ResumeState()
            
            // Set termination handler BEFORE running process to avoid race condition
            process.terminationHandler = { process in
                guard state.attemptResume() else { return }
                
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
            
            // Timeout after 10 seconds to prevent indefinite hangs
            DispatchQueue.global().asyncAfter(deadline: .now() + 10.0) {
                guard state.attemptResume() else { return }
                print("⏱️ FFmpeg timeout at \(timestamp)s - killing process")
                process.terminate()
                continuation.resume(throwing: FFmpegError.frameExtractionFailed)
            }
            
            do {
                print("🚀 FFmpeg FAST-SEEK Command: \(ffmpegPath) -ss \(timestamp) -i \"\(videoURL.path)\" -vframes 1 -q:v 2 -y \"\(outputURL.path)\"")
                try process.run()
            } catch {
                guard state.attemptResume() else { return }
                print("❌ Failed to run FFmpeg frame extraction: \(error)")
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Calculate adaptive interval based on video duration
    /// Dense grids for short videos, progressively wider intervals for longer content
    func calculateAdaptiveInterval(duration: Double) -> Double {
        switch duration {
        case ..<60:         // < 1 min: every 1s → 30-60 frames
            return 1.0
        case ..<300:        // 1-5 min: every 2s → 30-150 frames
            return 2.0
        case ..<1800:       // 5-30 min: every 5s → 60-360 frames
            return 5.0
        case ..<5400:       // 30-90 min: every 10s → 180-540 frames
            return 10.0
        default:            // 90+ min: every 15s → up to 600
            return 15.0
        }
    }
    
    /// Calculate timestamps for frame extraction (hard cap: 600 frames)
    private func calculateTimestamps(duration: Double, offset: Double, interval: Double) -> [Double] {
        let maxFrames = 600
        var timestamps: [Double] = []
        let startTime = max(0, offset)
        let endTime = duration

        var currentTime = startTime
        while currentTime < endTime && timestamps.count < maxFrames {
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