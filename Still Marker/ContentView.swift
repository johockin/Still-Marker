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

    /// One-shot: set on launch if a previous session exists and its video file is still
    /// accessible. ResultsView reads this once after extraction completes, restores the
    /// picks, then nils it out.
    var pendingRestore: PersistedSession?

    /// Picks made during theatrical extraction (state == .processing). One-shot:
    /// ResultsView consumes these on appear and merges into its pickedFrames state.
    @Published var theatricalPicks: [Frame] = []

    private let processor = VideoProcessor.shared

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

        // Persist the video URL immediately so a crash / kill mid-extraction can still
        // recover on next launch. Picks start empty; ResultsView will rewrite once frames
        // are extracted and the user starts working.
        let emptySession = PersistedSession(
            videoPath: videoURL.path,
            pickTimestamps: [],
            pickSourceIndices: [],
            lastViewMode: "grid",
            lastFrameIndex: 0,
            selectedExportFormat: "PNG (default)",
            savedAt: Date()
        )
        sessionStore.save(emptySession)

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

        // Best-effort persistence so quit-during-theater doesn't lose picks
        guard let videoURL = selectedVideoURL else { return }
        let session = PersistedSession(
            videoPath: videoURL.path,
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

            try await Task.sleep(nanoseconds: 300_000_000)
            self.state = .results
            
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
        ContentView()
    }
}

// MARK: - Theater View (M9 Phase 1+2)

/// Full-bleed cinematic view shown during extraction. Frames appear as they're
/// extracted, crossfading in. Press P or Space to pick the current frame, Esc
/// to skip to the grid (extraction continues in background).
struct TheaterView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var displayedFrame: Frame?
    @State private var pickedTimestamps: Set<Double> = []
    @State private var pickFlash: Bool = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // The frame itself, full-bleed-ish with breathing room.
            if let frame = displayedFrame {
                Image(nsImage: frame.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(.horizontal, 64)
                    .padding(.vertical, 80)
                    .id(frame.id)
                    .transition(.opacity)
            }

            // Pick flash — brief gold tint when a pick lands
            if pickFlash {
                Color(red: 0.85, green: 0.7, blue: 0.35)
                    .opacity(0.10)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .allowsHitTesting(false)
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
                    Text("\(viewModel.extractedFrames.count) frames extracted")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.35))
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // Pick count, sits below the filename row when > 0
                if !pickedTimestamps.isEmpty {
                    HStack {
                        Spacer()
                        Text("\(pickedTimestamps.count) pick\(pickedTimestamps.count == 1 ? "" : "s")")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color(red: 0.85, green: 0.7, blue: 0.35))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(.black.opacity(0.4)))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                }
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

            // Hint, bottom-right
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("P or Space to pick · Esc to skip to grid")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.28))
                        .padding(.trailing, 24)
                        .padding(.bottom, 24)
                }
            }

            // Thin progress at the very bottom
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

            // Keyboard input layer (invisible)
            KeyEventHandlingView(
                onLeftArrow: {},
                onRightArrow: {},
                onShiftLeftArrow: {},
                onShiftRightArrow: {},
                onUpArrow: {},
                onDownArrow: {},
                onEscape: { viewModel.state = .results },
                onPick: pickCurrent
            )
            .frame(width: 0, height: 0)
            .allowsHitTesting(false)
        }
        .onAppear {
            displayedFrame = viewModel.extractedFrames.last
        }
        .onChange(of: viewModel.extractedFrames.count) { _ in
            withAnimation(.easeInOut(duration: 0.4)) {
                displayedFrame = viewModel.extractedFrames.last
            }
        }
    }

    private func pickCurrent() {
        guard let frame = displayedFrame else { return }
        guard !pickedTimestamps.contains(frame.timestamp) else { return }
        pickedTimestamps.insert(frame.timestamp)
        viewModel.addTheatricalPick(frame)

        withAnimation(.easeOut(duration: 0.08)) { pickFlash = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(.easeIn(duration: 0.25)) { pickFlash = false }
        }
    }
}