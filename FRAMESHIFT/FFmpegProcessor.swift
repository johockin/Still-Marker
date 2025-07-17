//
//  FFmpegProcessor.swift
//  FRAMESHIFT
//
//  Created by Claude Code on 2025-01-17.
//

import Foundation
import AppKit

class FFmpegProcessor: ObservableObject {
    private var ffmpegPath: String {
        guard let path = Bundle.main.path(forResource: "ffmpeg", ofType: nil) else {
            fatalError("FFmpeg binary not found in app bundle")
        }
        return path
    }
    
    /// Extract frames from video at specified intervals
    func extractFrames(from videoURL: URL, 
                      offset: Double = 0.0, 
                      interval: Double = 3.0,
                      progressCallback: @escaping (Double, String) -> Void) async throws -> [Frame] {
        
        progressCallback(0.1, "Analyzing video...")
        
        // Get video duration first
        let duration = try await getVideoDuration(videoURL: videoURL)
        progressCallback(0.2, "Video duration: \(Int(duration))s")
        
        // Calculate timestamps for frame extraction
        let timestamps = calculateTimestamps(duration: duration, offset: offset, interval: interval)
        progressCallback(0.3, "Extracting \(timestamps.count) frames...")
        
        // Create temporary directory for frames
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("frameshift-\(UUID().uuidString)")
        
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        var frames: [Frame] = []
        
        // Extract frames
        for (index, timestamp) in timestamps.enumerated() {
            let progress = 0.3 + (Double(index) / Double(timestamps.count)) * 0.6
            progressCallback(progress, "Extracting frame at \(String(format: "%.1f", timestamp))s...")
            
            let frameURL = tempDir.appendingPathComponent("frame_\(timestamp).jpg")
            
            do {
                try await extractSingleFrame(
                    from: videoURL,
                    at: timestamp,
                    outputURL: frameURL
                )
                
                // Load the extracted frame
                if let image = NSImage(contentsOf: frameURL) {
                    let frame = Frame(timestamp: timestamp, image: image)
                    frames.append(frame)
                }
                
                // Clean up individual frame file
                try? FileManager.default.removeItem(at: frameURL)
                
            } catch {
                print("Failed to extract frame at \(timestamp)s: \(error)")
            }
        }
        
        // Clean up temp directory
        try? FileManager.default.removeItem(at: tempDir)
        
        progressCallback(1.0, "Extraction complete!")
        return frames
    }
    
    /// Get video duration using FFmpeg
    private func getVideoDuration(videoURL: URL) async throws -> Double {
        let process = Process()
        let pipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: ffmpegPath)
        process.arguments = [
            "-v", "error",
            "-show_entries", "format=duration",
            "-of", "default=noprint_wrappers=1:nokey=1",
            videoURL.path
        ]
        process.standardOutput = pipe
        process.standardError = Pipe() // Suppress error output
        
        return try await withCheckedThrowingContinuation { continuation in
            do {
                try process.run()
                
                process.terminationHandler = { process in
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    
                    if process.terminationStatus == 0, let duration = Double(output) {
                        continuation.resume(returning: duration)
                    } else {
                        continuation.resume(throwing: FFmpegError.invalidDuration)
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Extract a single frame at specified timestamp
    private func extractSingleFrame(from videoURL: URL, at timestamp: Double, outputURL: URL) async throws {
        let process = Process()
        
        process.executableURL = URL(fileURLWithPath: ffmpegPath)
        process.arguments = [
            "-i", videoURL.path,
            "-ss", String(timestamp),
            "-vframes", "1",
            "-q:v", "2", // High quality JPEG (scale 2-31, lower is better)
            "-y", // Overwrite output file
            outputURL.path
        ]
        process.standardOutput = Pipe() // Suppress output
        process.standardError = Pipe() // Suppress error output
        
        return try await withCheckedThrowingContinuation { continuation in
            do {
                try process.run()
                
                process.terminationHandler = { process in
                    if process.terminationStatus == 0 {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: FFmpegError.frameExtractionFailed)
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
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