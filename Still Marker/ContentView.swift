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
///
/// `videoBookmark` is a security-scoped bookmark that re-grants file access on a
/// new launch. Without it, files picked from TCC-protected locations (Movies,
/// Documents, Downloads) can't be re-opened by the relaunched process.
/// `videoPath` is kept as a fallback / display value.
struct PersistedSession: Codable {
    var videoPath: String
    var videoBookmark: Data?
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

// MARK: - Video Processor (AVFoundation primary, FFmpeg fallback)

/// Unified video extraction backend. Tries AVFoundation first (fast, native, hardware-decoded,
/// frame-accurate). On failure — typically MKV / MXF / WebM / older AVI codecs that AVFoundation
/// doesn't support — falls back to the bundled FFmpeg binary. Backend choice is cached per video
/// URL so we don't probe twice.
final class VideoProcessor {
    static let shared = VideoProcessor()

    enum Backend: String { case avFoundation, ffmpeg }

    private let avProcessor = AVFoundationProcessor()
    private let ffmpegProcessor = FFmpegProcessor()
    private var backendForURL: [URL: Backend] = [:]

    /// Last backend used for any operation; useful for diagnostics / status display.
    private(set) var lastBackendUsed: Backend = .avFoundation

    private init() {}

    func calculateAdaptiveInterval(duration: Double) -> Double {
        avProcessor.calculateAdaptiveInterval(duration: duration)
    }

    /// Determine which backend handles this video. Cached after first probe.
    private func chooseBackend(for videoURL: URL) async -> Backend {
        if let cached = backendForURL[videoURL] { return cached }
        let chosen: Backend
        do {
            _ = try await avProcessor.getVideoDuration(videoURL: videoURL)
            chosen = .avFoundation
        } catch {
            print("AVFoundation can't read \(videoURL.lastPathComponent): \(error). Falling back to FFmpeg.")
            chosen = .ffmpeg
        }
        backendForURL[videoURL] = chosen
        return chosen
    }

    func getVideoDuration(videoURL: URL) async throws -> Double {
        switch await chooseBackend(for: videoURL) {
        case .avFoundation:
            return try await avProcessor.getVideoDuration(videoURL: videoURL)
        case .ffmpeg:
            return try await ffmpegProcessor.getDurationViaFFmpeg(videoURL: videoURL)
        }
    }

    func extractFrames(from videoURL: URL,
                       onFrame: ((Frame) -> Void)? = nil,
                       progressCallback: @escaping (Double, String) -> Void) async throws -> [Frame] {
        let backend = await chooseBackend(for: videoURL)
        lastBackendUsed = backend
        switch backend {
        case .avFoundation:
            return try await avProcessor.extractFrames(from: videoURL, onFrame: onFrame, progressCallback: progressCallback)
        case .ffmpeg:
            return try await ffmpegProcessor.extractFrames(from: videoURL, onFrame: onFrame) { p, m in
                progressCallback(p, "[FFmpeg] " + m)
            }
        }
    }

    /// Returns a full-resolution NSImage for nudge / export. AVFoundation returns an in-memory
    /// CGImage (lossless); FFmpeg writes a temp PNG and loads it (also lossless).
    func extractSingleFrame(from videoURL: URL, at timestamp: Double) async throws -> NSImage {
        let backend = backendForURL[videoURL] ?? .avFoundation
        switch backend {
        case .avFoundation:
            do {
                return try await avProcessor.extractSingleFrame(from: videoURL, at: timestamp)
            } catch {
                // Per-frame fallback — rare but possible if a single timestamp hits a problem
                // AVFoundation can't decode but FFmpeg can.
                backendForURL[videoURL] = .ffmpeg
                lastBackendUsed = .ffmpeg
                return try await ffmpegSingleFrame(from: videoURL, at: timestamp)
            }
        case .ffmpeg:
            return try await ffmpegSingleFrame(from: videoURL, at: timestamp)
        }
    }

    private func ffmpegSingleFrame(from videoURL: URL, at timestamp: Double) async throws -> NSImage {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("smframe_\(UUID().uuidString).png")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        try await ffmpegProcessor.extractSingleFrame(from: videoURL, at: timestamp, outputURL: tempURL, lossless: true)
        guard let image = NSImage(contentsOf: tempURL), image.isValid else {
            throw FFmpegError.frameExtractionFailed
        }
        return image
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

    /// One-shot: set in startProcessing if we have persisted picks for the URL the user
    /// just opened. ResultsView reads this once after extraction completes, restores
    /// the picks, then nils it out.
    var pendingRestore: PersistedSession?

    /// Picks made during theatrical extraction (state == .processing). One-shot:
    /// ResultsView consumes these on appear and merges into its pickedFrames state.
    /// (Currently dormant — picking from theatrical is disabled, machinery kept for future re-enable.)
    @Published var theatricalPicks: [Frame] = []

    /// Set to true when extraction finishes. The theatrical view watches this so it
    /// can finish playing through its display queue at its own pace before handing
    /// off to the grid. Resets on new video / reset.
    @Published var isExtractionComplete: Bool = false

    /// Tracks the in-flight processing Task so a new startProcessing can cancel it.
    private var processingTask: Task<Void, Never>?

    private let processor = VideoProcessor.shared

    init() {
        // No auto-resume on launch. Persisted picks are restored only when the user
        // explicitly re-opens the same video (drag-drop, file picker, or Finder
        // Open With). See startProcessing for the per-URL restore check.
    }

    /// Build a security-scoped bookmark for a video URL. Returns nil if the URL doesn't
    /// support bookmarking (rare). For non-sandboxed apps this still works and the
    /// bookmark re-grants ad-hoc TCC permission across launches.
    private func makeBookmark(for url: URL) -> Data? {
        return try? url.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
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
        theatricalPicks = []
        isExtractionComplete = false
        sessionStore.clear()  // intentional reset by user
    }

    func startProcessing(videoURL: URL) {
        // Cancel any in-flight extraction so two videos can't process in parallel
        // (e.g., user opens a new file via Finder Open With while one is loading).
        processingTask?.cancel()
        processingTask = nil

        selectedVideoURL = videoURL
        state = .processing
        processingProgress = 0.0
        processingMessage = "Starting extraction..."
        isExtractionComplete = false
        theatricalPicks = []
        extractedFrames = []

        // If we have a persisted session for THIS exact video, queue its picks for
        // ResultsView to restore. Otherwise, start fresh and overwrite session.json
        // with an empty record for this video.
        if let saved = sessionStore.load(), saved.videoPath == videoURL.path {
            pendingRestore = saved
        } else {
            pendingRestore = nil
            let session = PersistedSession(
                videoPath: videoURL.path,
                videoBookmark: makeBookmark(for: videoURL),
                pickTimestamps: [],
                pickSourceIndices: [],
                lastViewMode: "grid",
                lastFrameIndex: 0,
                selectedExportFormat: "PNG (default)",
                savedAt: Date()
            )
            sessionStore.save(session)
        }

        processingTask = Task {
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
        // Reuse the existing bookmark if we already have one (avoid regenerating
        // every change). Generate one if missing.
        let existingBookmark = sessionStore.load()?.videoBookmark
        let session = PersistedSession(
            videoPath: videoURL.path,
            videoBookmark: existingBookmark ?? makeBookmark(for: videoURL),
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

    /// Read-and-clear theatrical picks. ResultsView calls this on appear.
    func consumeTheatricalPicks() -> [Frame] {
        let picks = theatricalPicks
        theatricalPicks = []
        return picks
    }

    /// Add a pick made during theatrical extraction. Persists immediately so picks
    /// survive even if the user quits before extraction completes.
    func addTheatricalPick(_ frame: Frame) {
        // Avoid duplicates by timestamp proximity (matches ResultsView's pick logic)
        if theatricalPicks.contains(where: { abs($0.timestamp - frame.timestamp) < 0.01 }) {
            return
        }
        theatricalPicks.append(frame)

        // Best-effort persistence so quit-during-theater doesn't lose picks.
        // (Currently dormant — picks from theater are disabled in UI.)
        guard let videoURL = selectedVideoURL else { return }
        let existingBookmark = sessionStore.load()?.videoBookmark
        let session = PersistedSession(
            videoPath: videoURL.path,
            videoBookmark: existingBookmark ?? makeBookmark(for: videoURL),
            pickTimestamps: theatricalPicks.map { $0.timestamp },
            pickSourceIndices: theatricalPicks.compactMap { pick in
                extractedFrames.firstIndex(where: { abs($0.timestamp - pick.timestamp) < 0.01 })
            },
            lastViewMode: "grid",
            lastFrameIndex: 0,
            selectedExportFormat: "PNG (default)",
            savedAt: Date()
        )
        sessionStore.save(session)
    }

    @MainActor
    private func processVideo(videoURL: URL) async {
        do {
            // Goes through VideoProcessor — tries AVFoundation, falls back to FFmpeg.
            self.videoDuration = try await processor.getVideoDuration(videoURL: videoURL)

            // Store the extraction interval for display in the header
            self.extractionInterval = processor.calculateAdaptiveInterval(duration: self.videoDuration)

            // Stream frames into extractedFrames as they're extracted, so TheaterView
            // can show them in real time. Drains the prior extractedFrames first.
            self.extractedFrames = []
            let frames = try await processor.extractFrames(
                from: videoURL,
                onFrame: { frame in
                    DispatchQueue.main.async {
                        self.extractedFrames.append(frame)
                    }
                },
                progressCallback: { progress, message in
                    DispatchQueue.main.async {
                        self.processingProgress = progress
                        self.processingMessage = message
                    }
                }
            )

            // Defensive: ensure final array matches what onFrame produced (no-op if it does).
            if self.extractedFrames.count != frames.count {
                self.extractedFrames = frames
            }

            // Hand off to the theatrical view (or to .results if there is no theater).
            // TheaterView watches isExtractionComplete and transitions to .results once
            // it has shown its last frame at its own pace. For users who already pressed
            // Esc to skip to grid, state is already .results; this is a no-op.
            self.isExtractionComplete = true
            if self.state == .processing && self.extractedFrames.isEmpty {
                // Edge case: no frames extracted at all. Fall back to results immediately
                // so we don't strand the user in processing forever.
                try await Task.sleep(nanoseconds: 300_000_000)
                self.state = .results
            }
            
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
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        switch viewModel.state {
        case .upload:
            UploadProcessingView(viewModel: viewModel)
        case .processing:
            // Theatrical view kicks in once the first frame is extracted.
            // Until then, the eye-icon "Analyzing..." view is shown.
            if viewModel.extractedFrames.isEmpty {
                UploadProcessingView(viewModel: viewModel)
            } else {
                TheaterView(viewModel: viewModel)
            }
        case .results:
            ResultsView(viewModel: viewModel)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(viewModel: AppViewModel())
    }
}

// MARK: - Theater View (M9 Phase 1+2)

/// Full-bleed cinematic view shown during extraction. Frames are displayed at a
/// controlled, contemplative pace (not as fast as they're extracted). This is
/// pure viewing — no picking. When caught up to the last extracted frame AND
/// extraction is complete, transitions to .results. Esc skips to grid early.
struct TheaterView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var displayedIndex: Int = 0

    /// Seconds per frame in theater. ~1.5s feels contemplative, not flickery.
    /// Independent of how fast extraction is actually running.
    private static let secondsPerFrame: Double = 1.5

    /// Always derive from state — never store displayed frame separately. Avoids
    /// race between .onAppear and view-body evaluation.
    private var displayedFrame: Frame? {
        let frames = viewModel.extractedFrames
        guard !frames.isEmpty else { return nil }
        return frames[min(displayedIndex, frames.count - 1)]
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // The frame itself, full-bleed with breathing room.
            if let frame = displayedFrame {
                Image(nsImage: frame.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(.horizontal, 48)
                    .padding(.vertical, 64)
                    .id(frame.id)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.5), value: frame.id)
            }

            // Top row: filename + frame counter
            VStack {
                HStack {
                    if let url = viewModel.selectedVideoURL {
                        Text(url.lastPathComponent)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.35))
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    Spacer()
                    let total = viewModel.extractedFrames.count
                    let shownIdx = min(displayedIndex + 1, total)
                    Text(viewModel.isExtractionComplete
                         ? "\(shownIdx) of \(total)"
                         : "\(shownIdx) of \(total)+ extracting…")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.35))
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                Spacer()
            }

            // Current frame's timecode, bottom-left
            if let frame = displayedFrame {
                VStack {
                    Spacer()
                    HStack {
                        Text(frame.formattedTimestamp)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.45))
                            .padding(.leading, 24)
                            .padding(.bottom, 24)
                        Spacer()
                    }
                }
            }

            // Hint, bottom-right — viewing only, esc to grid
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("Esc to grid")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.28))
                        .padding(.trailing, 24)
                        .padding(.bottom, 24)
                }
            }

            // Thin progress at the very bottom (extraction progress, not display progress)
            VStack {
                Spacer()
                Rectangle()
                    .fill(.white.opacity(0.06))
                    .frame(height: 2)
                    .overlay(alignment: .leading) {
                        GeometryReader { geo in
                            Rectangle()
                                .fill(Color(red: 0.85, green: 0.7, blue: 0.35))
                                .frame(width: geo.size.width * CGFloat(viewModel.processingProgress))
                                .animation(.easeOut(duration: 0.2), value: viewModel.processingProgress)
                        }
                    }
            }
            .ignoresSafeArea(edges: .bottom)

            // Keyboard input layer (invisible). Esc only — no picking from theater.
            KeyEventHandlingView(
                onLeftArrow: {},
                onRightArrow: {},
                onShiftLeftArrow: {},
                onShiftRightArrow: {},
                onUpArrow: {},
                onDownArrow: {},
                onEscape: { viewModel.state = .results },
                onPick: {} // disabled in theater
            )
            .frame(width: 0, height: 0)
            .allowsHitTesting(false)
        }
        .task(id: "theater-pacing") {
            // Drive paced advancement. .task is cancelled automatically when view goes
            // away (e.g., transition to .results). The id pins the task to this view's
            // lifecycle so it doesn't get recreated on every body evaluation.
            await runPacingLoop()
        }
    }

    private func runPacingLoop() async {
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: UInt64(Self.secondsPerFrame * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await MainActor.run { advance() }
        }
    }

    private func advance() {
        let count = viewModel.extractedFrames.count
        if displayedIndex + 1 < count {
            displayedIndex += 1
        } else if viewModel.isExtractionComplete {
            // Caught up + extraction done. Hand off to grid.
            withAnimation(.easeInOut(duration: 0.4)) {
                viewModel.state = .results
            }
        }
        // Else: hold on current frame, wait for more to be extracted.
    }
}