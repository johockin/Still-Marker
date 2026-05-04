//
//  ContentView.swift
//  Still Marker
//
//  Created by Claude Code on 2025-01-17.
//

import SwiftUI
import AVFoundation
import AppKit

// MARK: - Session Persistence

/// On-disk shape for the last-active session. Picks are stored as parallel arrays
/// of timestamps + the source-grid indices they had at save time, so we can restore
/// even if the extraction interval changes (timestamp wins, index is a hint).
struct PersistedSession: Codable {
    var videoPath: String
    var pickTimestamps: [Double]
    var pickSourceIndices: [Int]
    var lastViewMode: String          // "grid" | "framePreview"
    var lastFrameIndex: Int
    var selectedExportFormat: String  // ExportFormat raw value
    var savedAt: Date
}

final class SessionStore {
    private let fileURL: URL

    init() {
        let appSupport = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
        let dir = appSupport.appendingPathComponent("Still Marker", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("session.json")
    }

    func save(_ session: PersistedSession) {
        do {
            let data = try JSONEncoder().encode(session)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            print("Session save failed: \(error)")
        }
    }

    func load() -> PersistedSession? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(PersistedSession.self, from: data)
    }

    func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}

// MARK: - App State

enum AppState {
    case upload
    case processing
    case results
}

class AppViewModel: ObservableObject {
    @Published var state: AppState = .upload
    @Published var selectedVideoURL: URL?
    @Published var extractedFrames: [Frame] = []
    @Published var videoDuration: Double = 0.0
    @Published var extractionInterval: Double = 0.0
    @Published var processingProgress: Double = 0.0
    @Published var processingMessage: String = ""

    let sessionStore = SessionStore()

    /// One-shot: set on launch if a previous session exists and its video file is still
    /// accessible. ResultsView reads this once after extraction completes, restores the
    /// picks, then nils it out.
    var pendingRestore: PersistedSession?

    private let processor = AVFoundationProcessor()

    init() {
        // Restore previous session if present and the video file still exists.
        if let session = sessionStore.load(),
           FileManager.default.fileExists(atPath: session.videoPath) {
            pendingRestore = session
            // Defer to next runloop tick so @StateObject/SwiftUI is fully wired up.
            let url = URL(fileURLWithPath: session.videoPath)
            DispatchQueue.main.async { [weak self] in
                self?.startProcessing(videoURL: url)
            }
        } else if sessionStore.load() != nil {
            // Stale session (file moved/deleted) — drop it.
            sessionStore.clear()
        }
    }

    func resetToUpload() {
        state = .upload
        selectedVideoURL = nil
        extractedFrames = []
        videoDuration = 0.0
        extractionInterval = 0.0
        processingProgress = 0.0
        processingMessage = ""
        pendingRestore = nil
        sessionStore.clear()  // intentional reset by user
    }

    func startProcessing(videoURL: URL) {
        selectedVideoURL = videoURL
        state = .processing
        processingProgress = 0.0
        processingMessage = "Starting extraction..."

        Task {
            await processVideo(videoURL: videoURL)
        }
    }

    /// Persist the current pick + view state. Called by ResultsView whenever picks,
    /// view mode, frame index, or export format change. Cheap (small JSON, atomic write).
    func persistSession(pickTimestamps: [Double],
                        pickSourceIndices: [Int],
                        viewMode: String,
                        frameIndex: Int,
                        format: String) {
        guard let videoURL = selectedVideoURL else { return }
        let session = PersistedSession(
            videoPath: videoURL.path,
            pickTimestamps: pickTimestamps,
            pickSourceIndices: pickSourceIndices,
            lastViewMode: viewMode,
            lastFrameIndex: frameIndex,
            selectedExportFormat: format,
            savedAt: Date()
        )
        sessionStore.save(session)
    }

    /// Read-and-clear the pending restore. ResultsView calls this exactly once after
    /// the new video's frames have finished extracting.
    func consumePendingRestore() -> PersistedSession? {
        let restore = pendingRestore
        pendingRestore = nil
        return restore
    }

    @MainActor
    private func processVideo(videoURL: URL) async {
        do {
            // Get video duration for UI boundary indicators
            let asset = AVAsset(url: videoURL)
            let duration = try await asset.load(.duration)
            self.videoDuration = CMTimeGetSeconds(duration)

            // Store the extraction interval for display in the header
            self.extractionInterval = processor.calculateAdaptiveInterval(duration: self.videoDuration)

            let frames = try await processor.extractFrames(
                from: videoURL
            ) { progress, message in
                DispatchQueue.main.async {
                    self.processingProgress = progress
                    self.processingMessage = message
                }
            }
            
            // Update UI with extracted frames
            print("🔄 Setting extractedFrames with \(frames.count) frames")
            self.extractedFrames = frames
            
            // Brief pause to show completion
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            print("📱 Transitioning to .results state")
            self.state = .results
            print("✅ State transition complete")
            
        } catch {
            self.processingMessage = "Error: \(error.localizedDescription)"
            self.processingProgress = 0.0
            
            // Show error for 3 seconds, then return to upload
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.resetToUpload()
            }
        }
    }
    
}

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()
    
    var body: some View {
        switch viewModel.state {
        case .upload, .processing:
            UploadProcessingView(viewModel: viewModel)
        case .results:
            ResultsView(viewModel: viewModel)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}