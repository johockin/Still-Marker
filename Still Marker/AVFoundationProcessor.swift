//
//  AVFoundationProcessor.swift
//  Still Marker
//
//  Native AVFoundation frame extraction — replaces FFmpeg subprocesses.
//  10-50x faster for batch extraction and frame-accurate nudging.
//

import Foundation
import AppKit
import AVFoundation

class AVFoundationProcessor: ObservableObject {
    private var cachedGenerator: AVAssetImageGenerator?
    private var cachedAsset: AVAsset?
    private var cachedVideoURL: URL?

    /// Calculate adaptive interval based on video duration (shared with FFmpegProcessor)
    func calculateAdaptiveInterval(duration: Double) -> Double {
        switch duration {
        case ..<60:         return 1.0
        case ..<300:        return 2.0
        case ..<1800:       return 5.0
        case ..<5400:       return 10.0
        default:            return 15.0
        }
    }

    /// Get video duration
    func getVideoDuration(videoURL: URL) async throws -> Double {
        let asset = AVAsset(url: videoURL)
        let duration = try await asset.load(.duration)
        return CMTimeGetSeconds(duration)
    }

    /// Batch extract frames at calculated timestamps
    func extractFrames(from videoURL: URL,
                       offset: Double = 0.0,
                       progressCallback: @escaping (Double, String) -> Void) async throws -> [Frame] {

        progressCallback(0.1, "Analyzing video...")

        let duration = try await getVideoDuration(videoURL: videoURL)
        progressCallback(0.2, "Video duration: \(Int(duration))s")

        let interval = calculateAdaptiveInterval(duration: duration)
        let timestamps = calculateTimestamps(duration: duration, offset: offset, interval: interval)
        progressCallback(0.25, "Extracting \(timestamps.count) frames...")

        let asset = AVAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 1920, height: 1080)
        // Relaxed tolerance for batch extraction (snaps to nearest keyframe = fast)
        generator.requestedTimeToleranceBefore = CMTime(seconds: 0.5, preferredTimescale: 600)
        generator.requestedTimeToleranceAfter = CMTime(seconds: 0.5, preferredTimescale: 600)

        var frames: [Frame] = []

        for (index, timestamp) in timestamps.enumerated() {
            let progress = 0.3 + (Double(index) / Double(timestamps.count)) * 0.65
            progressCallback(progress, "Extracting frame \(index + 1) of \(timestamps.count)...")

            let time = CMTime(seconds: timestamp, preferredTimescale: 600)

            do {
                let (cgImage, _) = try await generator.image(at: time)
                let nsImage = NSImage(cgImage: cgImage, size: NSSize(
                    width: CGFloat(cgImage.width),
                    height: CGFloat(cgImage.height)
                ))

                let thumbnail = nsImage.resizedToFit(maxSize: CGSize(width: 200, height: 112))

                // Save full image to temp file for memory efficiency
                let frameID = UUID()
                let permanentURL = Frame.createTempImageURL(for: frameID)
                if let imageData = nsImage.jpegData(compressionQuality: 0.95) {
                    try? imageData.write(to: permanentURL)
                }

                let frame = Frame(id: frameID, timestamp: timestamp, thumbnail: thumbnail, fullImageURL: permanentURL)
                frames.append(frame)
            } catch {
                print("Failed to extract frame at \(timestamp)s: \(error)")
            }
        }

        progressCallback(1.0, "Extraction complete!")
        return frames
    }

    /// Extract a single frame at exact timestamp (for nudge/refine)
    /// Keeps generator cached for repeated calls on the same video.
    func extractSingleFrame(from videoURL: URL, at timestamp: Double) async throws -> NSImage {
        let generator = getOrCreateGenerator(for: videoURL)
        // Zero tolerance for frame-accurate refinement
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero

        let time = CMTime(seconds: timestamp, preferredTimescale: 600)
        let (cgImage, _) = try await generator.image(at: time)

        return NSImage(cgImage: cgImage, size: NSSize(
            width: CGFloat(cgImage.width),
            height: CGFloat(cgImage.height)
        ))
    }

    // MARK: - Private

    private func getOrCreateGenerator(for videoURL: URL) -> AVAssetImageGenerator {
        if let cached = cachedGenerator, cachedVideoURL == videoURL {
            return cached
        }

        let asset = AVAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 1920, height: 1080)

        cachedAsset = asset
        cachedGenerator = generator
        cachedVideoURL = videoURL
        return generator
    }

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
