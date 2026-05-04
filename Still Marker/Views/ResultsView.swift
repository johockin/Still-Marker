//
//  ResultsView.swift
//  Still Marker
//
//  Created by Claude Code on 2025-01-17.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers


enum ViewMode {
    case grid
    case framePreview
}

enum PreviewScaleMode {
    case fit
    case actual
}

enum ExportFormat: String, CaseIterable {
    case png = "PNG (default)"
    case jpeg = "JPEG (100% Quality)"
    case tiff = "TIFF"

    var fileExtension: String {
        switch self {
        case .jpeg: return "jpg"
        case .png: return "png"
        case .tiff: return "tiff"
        }
    }

    var contentType: UTType {
        switch self {
        case .jpeg: return .jpeg
        case .png: return .png
        case .tiff: return .tiff
        }
    }
}

enum ToastType {
    case success
    case error
}

/// Tracks each grid cell's position in a shared coordinate space so the hover-preview
/// overlay can render at the right spot. SwiftUI's LazyVGrid doesn't respect zIndex
/// across rows; an inline scaleEffect gets clipped by neighbouring cells.
struct CellFramePreference: PreferenceKey {
    static var defaultValue: [UUID: CGRect] = [:]
    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}

// MARK: - Results View

struct ResultsView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var selectedFrame: Frame?
    @State private var hoveredExportAllButton: Bool = false
    @State private var hoveredNewVideoButton: Bool = false
    @State private var viewMode: ViewMode = .grid
    @State private var isGridReady: Bool = false
    @State private var visibleFrameCount: Int = 0
    @State private var hoveredFrameID: UUID? = nil
    @State private var previewFrame: Frame?
    @State private var previewScaleMode: PreviewScaleMode = .fit
    @State private var selectedExportFormat: ExportFormat = .png
    @State private var currentFrameIndex: Int = 0

    // Frame refinement state
    @State private var refinedTimestamp: Double? = nil
    @State private var refinedFrame: Frame? = nil
    @State private var isRefining: Bool = false

    // Nudge gear
    @State private var currentGear: NudgeGear = .fine

    // Pick system state
    @State private var pickedFrames: [Frame] = []
    @State private var pickedSourceIndices: Set<Int> = []
    @State private var scrollToIndex: Int? = nil

    // M9 teleprompter: auto-scroll the grid to follow streaming frames during extraction
    @State private var isAutoScrolling: Bool = false
    @State private var lastTeleprompterScroll: Date = .distantPast

    // Hover-preview overlay: track each cell's position so we can render the magnified
    // preview as a top-level overlay (LazyVGrid doesn't respect zIndex across rows,
    // so inline scaleEffect gets clipped by neighbours).
    @State private var cellFrames: [UUID: CGRect] = [:]

    // Drag and drop state
    @State private var isDragOverGrid: Bool = false

    // Toast notification state
    @State private var toastMessage: String = ""
    @State private var toastType: ToastType = .success
    @State private var showToast: Bool = false


    // Use VideoProcessor.shared (AVFoundation primary, FFmpeg fallback) directly at call sites.

    /// User-controlled grid thumbnail size, persisted in UserDefaults. Adaptive default
    /// based on frame count if no user preference yet.
    @AppStorage("gridZoom") private var gridZoom: Double = 0  // 0 = auto / not set

    private static let zoomMin: Double = 100
    private static let zoomMax: Double = 320
    private static let zoomStep: Double = 40

    private var effectiveMinSize: CGFloat {
        if gridZoom > 0 { return CGFloat(gridZoom) }
        // Auto mode: bigger defaults than before — user feedback was "too small"
        let count = viewModel.extractedFrames.count
        switch count {
        case 0..<60:    return 220
        case 60..<200:  return 180
        case 200..<400: return 140
        default:        return 120
        }
    }

    private var columns: [GridItem] {
        let minSize = effectiveMinSize
        return [GridItem(.adaptive(minimum: minSize, maximum: max(minSize, 360)), spacing: 6)]
    }

    var body: some View {
        ZStack {
            Theme.background
                .ignoresSafeArea()

            switch viewMode {
            case .grid:
                gridView
            case .framePreview:
                if let frame = previewFrame {
                    framePreviewView(frame: frame)
                }
            }

            // Toast notification overlay
            if showToast {
                VStack {
                    Spacer()
                    toastView
                    Spacer()
                        .frame(height: 100)
                }
                .animation(.easeInOut(duration: 0.3), value: showToast)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

        }
        .navigationTitle("")
        .onAppear {
            // Restore picks from a previous session, if one is pending. Runs once per
            // ResultsView lifetime; consumePendingRestore nils the value out.
            if let restore = viewModel.consumePendingRestore() {
                applyRestore(restore)
            }
            // Theatrical picks (made during M9 extraction view) flow in here.
            let theatricalPicks = viewModel.consumeTheatricalPicks()
            if !theatricalPicks.isEmpty {
                applyTheatricalPicks(theatricalPicks)
            }
        }
        .onChange(of: pickedFrames.count) { _ in persistCurrentState() }
        .onChange(of: viewMode) { _ in persistCurrentState() }
        .onChange(of: currentFrameIndex) { _ in persistCurrentState() }
        .onChange(of: selectedExportFormat) { _ in persistCurrentState() }
    }

    /// Write current view state to disk. Cheap, atomic. Called on every meaningful change.
    private func persistCurrentState() {
        let viewModeStr: String = (viewMode == .grid) ? "grid" : "framePreview"
        viewModel.persistSession(
            pickTimestamps: pickedFrames.map { $0.timestamp },
            pickSourceIndices: Array(pickedSourceIndices).sorted(),
            viewMode: viewModeStr,
            frameIndex: currentFrameIndex,
            format: selectedExportFormat.rawValue
        )
    }

    /// Re-attach the picks from a restored session by matching timestamps against the
    /// freshly-extracted frames. Saved index is the fast path; fallback is closest-by-timestamp
    /// within 1.5s tolerance (covers cases where the extraction interval changed).
    private func applyRestore(_ restore: PersistedSession) {
        if let format = ExportFormat.allCases.first(where: { $0.rawValue == restore.selectedExportFormat }) {
            selectedExportFormat = format
        }
        let frames = viewModel.extractedFrames
        var restoredPicks: [Frame] = []
        var restoredIndices: Set<Int> = []
        for (i, ts) in restore.pickTimestamps.enumerated() {
            let savedIdx = i < restore.pickSourceIndices.count ? restore.pickSourceIndices[i] : -1
            if savedIdx >= 0, savedIdx < frames.count, abs(frames[savedIdx].timestamp - ts) < 0.5 {
                restoredPicks.append(frames[savedIdx])
                restoredIndices.insert(savedIdx)
                continue
            }
            if let (closestIdx, frame) = frames.enumerated().min(by: { abs($0.element.timestamp - ts) < abs($1.element.timestamp - ts) }),
               abs(frame.timestamp - ts) < 1.5 {
                restoredPicks.append(frame)
                restoredIndices.insert(closestIdx)
            }
        }
        pickedFrames = restoredPicks
        pickedSourceIndices = restoredIndices

        if !restoredPicks.isEmpty {
            showToastNotification(message: "Restored \(restoredPicks.count) pick\(restoredPicks.count == 1 ? "" : "s") from last session", type: .success)
        }
    }

    // MARK: - Grid Landing (smooth scroll-to-target on appear)

    /// Called from the ScrollView's .onAppear. Decides where to land:
    /// - If scrollToIndex is set (Esc-from-preview-after-extraction, or pick-return),
    ///   scroll to that frame.
    /// - If extraction is in progress and no specific target, land at the bottom
    ///   (latest extracted frame) and engage teleprompter auto-scroll.
    /// - Otherwise (extraction done, no target), let the grid show naturally.
    private func handleGridLanding(proxy: ScrollViewProxy) {
        let frames = viewModel.extractedFrames

        if let target = scrollToIndex {
            scrollToIndex = nil
            if target >= visibleFrameCount {
                visibleFrameCount = min(target + 1, frames.count)
            }
            // Use a real delay (200ms) so SwiftUI has time to lay out the LazyVGrid
            // with the bumped visibleFrameCount before scrollTo runs. Animated so
            // the user reads it as intentional motion.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    proxy.scrollTo(target, anchor: .center)
                }
            }
            return
        }

        if !viewModel.isExtractionComplete && !frames.isEmpty {
            // Engage auto-scroll synchronously so the .onReceive subscriber will fire
            // for subsequent frames. Also do an initial scroll to bottom.
            isAutoScrolling = true
            visibleFrameCount = max(visibleFrameCount, frames.count)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                let lastIdx = max(0, viewModel.extractedFrames.count - 1)
                withAnimation(.easeInOut(duration: 0.4)) {
                    proxy.scrollTo(lastIdx, anchor: .bottom)
                }
            }
            return
        }

        // No specific target, no auto-scroll case — natural top is fine.
    }

    // MARK: - Grid Zoom

    private var currentZoom: Double {
        gridZoom > 0 ? gridZoom : Double(effectiveMinSize)
    }
    private var canZoomIn: Bool { currentZoom < Self.zoomMax - 0.5 }
    private var canZoomOut: Bool { currentZoom > Self.zoomMin + 0.5 }

    private func zoomIn() {
        let target = min(Self.zoomMax, currentZoom + Self.zoomStep)
        gridZoom = target
    }
    private func zoomOut() {
        let target = max(Self.zoomMin, currentZoom - Self.zoomStep)
        gridZoom = target
    }

    /// Carry picks made during theatrical extraction into the grid's pickedFrames state.
    /// Theatrical picks are real Frame objects but their source-grid index needs to be
    /// looked up in the just-extracted frames array.
    private func applyTheatricalPicks(_ picks: [Frame]) {
        let frames = viewModel.extractedFrames
        var added = 0
        for pick in picks {
            // Skip if already picked (e.g., picked during theater AND restored from prior session)
            if pickedFrames.contains(where: { abs($0.timestamp - pick.timestamp) < 0.01 }) { continue }

            if let idx = frames.firstIndex(where: { abs($0.timestamp - pick.timestamp) < 0.01 }) {
                pickedFrames.append(frames[idx])
                pickedSourceIndices.insert(idx)
            } else {
                // Picked frame doesn't match any grid frame exactly (shouldn't happen in
                // Phase 1+2 since picks ARE grid frames), but handle defensively.
                pickedFrames.append(pick)
            }
            added += 1
        }
        if added > 0 {
            showToastNotification(message: "\(added) pick\(added == 1 ? "" : "s") from extraction", type: .success)
        }
    }

    private var gridView: some View {
        VStack(spacing: 0) {
            headerView

            Group {
                if !isGridReady {
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.5)

                        Text("Loading \(viewModel.extractedFrames.count) frames...")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textDim)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            isGridReady = true
                            loadFramesProgressively()
                        }
                    }
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            ZStack(alignment: .topLeading) {
                            LazyVGrid(columns: columns, spacing: 6) {
                                ForEach(0..<min(visibleFrameCount, viewModel.extractedFrames.count), id: \.self) { index in
                                    let frame = viewModel.extractedFrames[index]
                                    let isCardHovered = hoveredFrameID == frame.id
                                    Group {
                                        if frame.thumbnail.isValid && !frame.formattedTimestamp.isEmpty {
                                            FrameCard(
                                                frame: frame,
                                                isSelected: selectedFrame?.id == frame.id,
                                                isHovered: isCardHovered,
                                                isPicked: pickedSourceIndices.contains(index),
                                                onTap: {
                                                    isAutoScrolling = false  // user took control
                                                    selectedFrame = frame
                                                    previewFrame = frame
                                                    currentFrameIndex = index
                                                    withAnimation(.easeInOut(duration: 0.3)) {
                                                        viewMode = .framePreview
                                                    }
                                                },
                                                onDoubleTap: {
                                                    isAutoScrolling = false
                                                    selectedFrame = frame
                                                    previewFrame = frame
                                                    currentFrameIndex = index
                                                    withAnimation(.easeInOut(duration: 0.3)) {
                                                        viewMode = .framePreview
                                                    }
                                                },
                                                onHover: { isHovering in
                                                    hoveredFrameID = isHovering ? frame.id : nil
                                                }
                                            )
                                            // Last-cell visibility is the override mechanism for
                                            // teleprompter mode. While extraction is running:
                                            //   last-cell visible (user at bottom)  → auto-scroll ON
                                            //   last-cell off-screen (user scrolled up) → auto-scroll OFF
                                            .onAppear {
                                                if !viewModel.isExtractionComplete,
                                                   index == viewModel.extractedFrames.count - 1 {
                                                    isAutoScrolling = true
                                                }
                                            }
                                            .onDisappear {
                                                if !viewModel.isExtractionComplete,
                                                   index == viewModel.extractedFrames.count - 1 {
                                                    isAutoScrolling = false
                                                }
                                            }
                                        } else {
                                            VStack {
                                                Image(systemName: "exclamationmark.triangle")
                                                    .font(.system(size: 24, weight: .light))
                                                    .foregroundStyle(.red.opacity(0.7))
                                                    .symbolRenderingMode(.hierarchical)
                                                Text("Invalid Frame")
                                                    .font(.caption)
                                                    .foregroundStyle(Theme.textGhost)
                                            }
                                            .frame(height: 150)
                                        }
                                    }
                                    // Track this cell's position so the hover-preview overlay
                                    // can render at the right spot. (Inline scaleEffect was
                                    // getting clipped by other rows — LazyVGrid doesn't
                                    // respect zIndex across rows.)
                                    .background(GeometryReader { geo in
                                        Color.clear.preference(
                                            key: CellFramePreference.self,
                                            value: [frame.id: geo.frame(in: .named("gridContent"))]
                                        )
                                    })
                                    .id(index)
                                }
                            }
                            .padding(.horizontal, 40)
                            .padding(.top, 20)
                            .padding(.bottom, 24)

                            // Floating hover-preview overlay. Renders ABOVE the LazyVGrid
                            // (in same ZStack) so it isn't clipped by sibling rows.
                            // Position is read from the cell's reported frame.
                            if viewModel.isExtractionComplete,
                               let hoveredID = hoveredFrameID,
                               let cellRect = cellFrames[hoveredID],
                               let hoveredFrame = viewModel.extractedFrames.first(where: { $0.id == hoveredID }) {
                                Image(nsImage: hoveredFrame.thumbnail)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: cellRect.width * 1.8, height: cellRect.height * 1.8)
                                    .clipShape(RoundedRectangle(cornerRadius: 2))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 2)
                                            .strokeBorder(Theme.gold, lineWidth: 1.5)
                                    )
                                    .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
                                    .offset(
                                        x: cellRect.midX - cellRect.width * 0.9,
                                        y: cellRect.midY - cellRect.height * 0.9
                                    )
                                    .allowsHitTesting(false)
                            }
                            }
                            .coordinateSpace(name: "gridContent")
                        }
                        .onPreferenceChange(CellFramePreference.self) { newFrames in
                            cellFrames = newFrames
                        }
                        .onAppear {
                            handleGridLanding(proxy: proxy)
                        }
                        // Subscribe directly to the @Published value — more reliable than
                        // .onChange(of: count) for nested-conditional views.
                        .onReceive(viewModel.$extractedFrames) { newFrames in
                            guard isAutoScrolling, !newFrames.isEmpty, viewMode == .grid else { return }
                            // Hardware video decode can extract frames at 50-200 fps.
                            // Triggering an animated scrollTo per frame overwhelms SwiftUI
                            // and produces stepping. Rate-limit to ~2Hz; each scroll runs
                            // a 600ms animation so successive scrolls overlap into
                            // continuous motion.
                            let now = Date()
                            guard now.timeIntervalSince(lastTeleprompterScroll) > 0.5 else { return }
                            lastTeleprompterScroll = now
                            DispatchQueue.main.async {
                                withAnimation(.linear(duration: 0.6)) {
                                    proxy.scrollTo(newFrames.count - 1, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
            }
            .background(Color.clear)
            .onChange(of: viewModel.extractedFrames.count) { newCount in
                if newCount == 0 {
                    // Genuine reset (new video loaded). Restart progressive load.
                    isGridReady = false
                    visibleFrameCount = 0
                } else if isGridReady {
                    // Background extraction added more frames after we already entered
                    // the grid (e.g., user pressed Esc to skip the theater). Just keep
                    // visibleFrameCount in sync — don't reset, don't restart progressive
                    // load, don't show the spinner. LazyVGrid handles incremental adds.
                    visibleFrameCount = newCount
                }
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $isDragOverGrid) { providers in
            handleDrop(providers: providers)
        }
        .overlay(dropOverlay)
    }

    @ViewBuilder
    private var dropOverlay: some View {
        if isDragOverGrid {
            Theme.overlayScrim
                .overlay(
                    VStack(spacing: 12) {
                        Text("Drop to load new video")
                            .font(.body)
                            .foregroundStyle(Theme.goldDim)
                    }
                )
                .animation(.easeInOut(duration: 0.2), value: isDragOverGrid)
        }
    }

    private var gridDescription: String {
        let count = viewModel.extractedFrames.count
        let interval = viewModel.extractionInterval

        let intervalStr: String
        if interval < 1 {
            intervalStr = "1 every \(String(format: "%.1f", interval))s"
        } else if interval == floor(interval) {
            intervalStr = "1 every \(Int(interval))s"
        } else {
            intervalStr = "1 every \(String(format: "%.1f", interval))s"
        }

        let dur = viewModel.videoDuration
        if dur > 600 {
            let durStr = formatDurationShort(dur)
            return "\(count) moments \u{00B7} \(intervalStr) across \(durStr)"
        } else {
            return "\(count) frames \u{00B7} \(intervalStr)"
        }
    }

    private func formatDurationShort(_ seconds: Double) -> String {
        let totalMinutes = Int(seconds / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    private var headerView: some View {
        HStack(spacing: 12) {
            Button(action: {
                viewModel.resetToUpload()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 10, weight: .medium))
                    Text("new video")
                        .font(.system(size: 13))
                }
                .foregroundStyle(hoveredNewVideoButton ? Theme.text : Theme.textSecondary)
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { hovering in
                hoveredNewVideoButton = hovering
            }

            Spacer()

            Text(gridDescription)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textDim)

            Spacer()

            // Zoom controls. Click - / + to step thumbnail size; persists.
            HStack(spacing: 4) {
                Button(action: zoomOut) {
                    Image(systemName: "minus")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(canZoomOut ? Theme.textSecondary : Theme.textDim.opacity(0.3))
                        .frame(width: 22, height: 22)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!canZoomOut)
                .help("Smaller thumbnails")

                Button(action: zoomIn) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(canZoomIn ? Theme.textSecondary : Theme.textDim.opacity(0.3))
                        .frame(width: 22, height: 22)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!canZoomIn)
                .help("Larger thumbnails")
            }
            .padding(.trailing, 12)

            Button(action: {
                if pickedFrames.isEmpty {
                    exportAllFrames()
                } else {
                    exportPickedFrames()
                }
            }) {
                Text(pickedFrames.isEmpty ? "export all" : "export \(pickedFrames.count) pick\(pickedFrames.count == 1 ? "" : "s")")
                    .font(.system(size: 13))
                    .foregroundStyle(hoveredExportAllButton ? Theme.gold : Theme.goldDim)
                    .underline(hoveredExportAllButton)
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { hovering in
                hoveredExportAllButton = hovering
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .frame(height: 44)
    }

    private var toastView: some View {
        Text(toastMessage)
            .font(.system(size: 12))
            .foregroundStyle(toastType == .success ? Theme.gold : .red)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.toastBackground)
            )
            .padding(.horizontal, 40)
    }

    private func loadFramesProgressively() {
        let batchSize = 8
        let totalFrames = viewModel.extractedFrames.count

        visibleFrameCount = min(batchSize, totalFrames)

        guard totalFrames > batchSize else { return }

        _ = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            DispatchQueue.main.async {
                self.visibleFrameCount = min(self.visibleFrameCount + batchSize, totalFrames)
                if self.visibleFrameCount >= totalFrames {
                    timer.invalidate()
                }
            }
        }
    }

    private func exportFrame(_ frame: Frame) {
        let currentFormat = selectedExportFormat
        let currentFormatExtension = currentFormat.fileExtension
        let currentFormatIndex = ExportFormat.allCases.firstIndex(of: currentFormat) ?? 0

        let savePanel = NSSavePanel()
        savePanel.title = "Export Frame"
        savePanel.showsResizeIndicator = true
        savePanel.showsHiddenFiles = false
        savePanel.canCreateDirectories = true
        savePanel.allowedContentTypes = []

        savePanel.nameFieldStringValue = "\(generateFilename(for: frame)).\(currentFormatExtension)"

        let formatSelector = NSPopUpButton()
        for format in ExportFormat.allCases {
            formatSelector.addItem(withTitle: format.rawValue)
        }
        formatSelector.selectItem(at: currentFormatIndex)

        let accessoryView = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 30))
        let label = NSTextField(labelWithString: "Format:")
        label.frame = NSRect(x: 0, y: 5, width: 60, height: 20)
        formatSelector.frame = NSRect(x: 70, y: 0, width: 130, height: 30)

        accessoryView.addSubview(label)
        accessoryView.addSubview(formatSelector)
        savePanel.accessoryView = accessoryView

        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                let selectedFormat = ExportFormat.allCases[formatSelector.indexOfSelectedItem]
                let finalURL = url.deletingPathExtension().appendingPathExtension(selectedFormat.fileExtension)

                Task { await self.exportSingleFrameAtSourceResolution(frame: frame, format: selectedFormat, to: finalURL) }
            }
        }
    }

    /// Re-extracts the frame from the source video at native resolution and encodes
    /// directly to the chosen format. Bypasses the lossy 1080p JPEG preview cache.
    private func exportSingleFrameAtSourceResolution(frame: Frame, format: ExportFormat, to url: URL) async {
        guard let videoURL = viewModel.selectedVideoURL else {
            await MainActor.run { showToastNotification(message: "No source video", type: .error) }
            return
        }
        do {
            let image = try await VideoProcessor.shared.extractSingleFrame(from: videoURL, at: frame.timestamp)
            guard let data = convertImageToData(image, format: format) else {
                await MainActor.run { showToastNotification(message: "Failed to encode \(format.rawValue)", type: .error) }
                return
            }
            try data.write(to: url)
            await MainActor.run { showToastNotification(message: "Exported: \(url.lastPathComponent)", type: .success) }
        } catch {
            await MainActor.run { showToastNotification(message: "Export failed: \(error.localizedDescription)", type: .error) }
        }
    }

    private func exportAllFrames() {
        guard !viewModel.extractedFrames.isEmpty else {
            showToastNotification(message: "No frames to export", type: .error)
            return
        }

        let openPanel = NSOpenPanel()
        openPanel.title = "Select Export Folder"
        openPanel.showsResizeIndicator = true
        openPanel.showsHiddenFiles = false
        openPanel.canCreateDirectories = true
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false

        let formatSelector = NSPopUpButton()
        for format in ExportFormat.allCases {
            formatSelector.addItem(withTitle: format.rawValue)
        }
        formatSelector.selectItem(at: ExportFormat.allCases.firstIndex(of: selectedExportFormat) ?? 0)

        let accessoryView = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 40))
        let label = NSTextField(labelWithString: "Export Format:")
        label.frame = NSRect(x: 0, y: 10, width: 100, height: 20)
        formatSelector.frame = NSRect(x: 110, y: 5, width: 180, height: 30)

        accessoryView.addSubview(label)
        accessoryView.addSubview(formatSelector)
        openPanel.accessoryView = accessoryView
        openPanel.isAccessoryViewDisclosed = true

        openPanel.begin { response in
            if response == .OK, let folderURL = openPanel.url {
                let selectedFormat = ExportFormat.allCases[formatSelector.indexOfSelectedItem]
                self.performBatchExport(to: folderURL, format: selectedFormat, frames: self.viewModel.extractedFrames)
            }
        }
    }

    private func performBatchExport(to folderURL: URL, format: ExportFormat, frames: [Frame], clearPicksOnSuccess: Bool = false) {
        let count = frames.count
        showToastNotification(message: "Exporting \(count) frame\(count == 1 ? "" : "s")...", type: .success)

        guard let videoURL = viewModel.selectedVideoURL else {
            showToastNotification(message: "No source video", type: .error)
            return
        }

        Task {
            var successCount = 0
            var errorCount = 0

            for frame in frames {
                let filename = "\(self.generateFilename(for: frame)).\(format.fileExtension)"
                let fileURL = folderURL.appendingPathComponent(filename)

                do {
                    // Re-extract from source at native resolution for true lossless export.
                    let image = try await VideoProcessor.shared.extractSingleFrame(from: videoURL, at: frame.timestamp)
                    if let imageData = self.convertImageToData(image, format: format) {
                        try imageData.write(to: fileURL)
                        successCount += 1
                    } else {
                        print("Failed to convert frame \(frame.formattedTimestamp) to \(format.rawValue)")
                        errorCount += 1
                    }
                } catch {
                    print("Failed to extract/save frame \(frame.formattedTimestamp): \(error)")
                    errorCount += 1
                }
            }

            await MainActor.run {
                if errorCount == 0 {
                    self.showToastNotificationLong(message: "Exported \(successCount) frame\(successCount == 1 ? "" : "s") to \(folderURL.lastPathComponent)", type: .success)
                    if clearPicksOnSuccess {
                        self.pickedFrames = []
                        self.pickedSourceIndices = []
                    }
                } else {
                    self.showToastNotificationLong(message: "Export: \(successCount) ok, \(errorCount) failed", type: .error)
                }
            }
        }
    }

    private func exportPickedFrames() {
        guard !pickedFrames.isEmpty else {
            showToastNotification(message: "No picks to export", type: .error)
            return
        }

        let openPanel = NSOpenPanel()
        openPanel.title = "Select Export Folder"
        openPanel.showsResizeIndicator = true
        openPanel.showsHiddenFiles = false
        openPanel.canCreateDirectories = true
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false

        let formatSelector = NSPopUpButton()
        for format in ExportFormat.allCases {
            formatSelector.addItem(withTitle: format.rawValue)
        }
        formatSelector.selectItem(at: ExportFormat.allCases.firstIndex(of: selectedExportFormat) ?? 0)

        let accessoryView = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 40))
        let label = NSTextField(labelWithString: "Export Format:")
        label.frame = NSRect(x: 0, y: 10, width: 100, height: 20)
        formatSelector.frame = NSRect(x: 110, y: 5, width: 180, height: 30)

        accessoryView.addSubview(label)
        accessoryView.addSubview(formatSelector)
        openPanel.accessoryView = accessoryView
        openPanel.isAccessoryViewDisclosed = true

        openPanel.begin { response in
            if response == .OK, let folderURL = openPanel.url {
                let selectedFormat = ExportFormat.allCases[formatSelector.indexOfSelectedItem]
                self.performBatchExport(to: folderURL, format: selectedFormat, frames: self.pickedFrames, clearPicksOnSuccess: true)
            }
        }
    }

}

// MARK: - Frame Preview View

extension ResultsView {
    private func framePreviewView(frame: Frame) -> some View {
        let displayFrame = refinedFrame ?? frame

        return VStack(spacing: 0) {
            FramePreviewHeader(
                currentFrameIndex: currentFrameIndex,
                totalFrames: viewModel.extractedFrames.count,
                onBack: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        resetRefinement()
                        viewMode = .grid
                    }
                },
                onExportAll: {
                    exportAllFrames()
                }
            )

            Spacer()

            FrameNavigationView(
                frame: displayFrame,
                isRefining: isRefining,
                currentFrameIndex: currentFrameIndex,
                totalFrames: viewModel.extractedFrames.count,
                onPrevious: navigateToPreviousFrame,
                onNext: navigateToNextFrame
            )

            // Filmstrip
            FilmstripView(
                frames: viewModel.extractedFrames,
                currentIndex: currentFrameIndex,
                onSelect: { index in
                    currentFrameIndex = index
                    previewFrame = viewModel.extractedFrames[index]
                    selectedFrame = previewFrame
                    resetRefinement()
                }
            )
            .padding(.top, 10)

            FrameControlsView(
                frame: displayFrame,
                refinedTimestamp: refinedTimestamp,
                isRefining: isRefining,
                isPicked: pickedSourceIndices.contains(currentFrameIndex),
                videoDuration: viewModel.videoDuration,
                currentGear: currentGear,
                onNudge: { amount in refineByAmount(amount) },
                onCycleGear: cycleGear,
                onPick: pickCurrentFrame,
                onExport: { exportFrame(displayFrame) }
            )
        }
        .background(
            KeyEventHandlingView(
                onLeftArrow: { refineByAmount(-currentGear.tightAmount) },
                onRightArrow: { refineByAmount(currentGear.tightAmount) },
                onShiftLeftArrow: { refineByAmount(-currentGear.shiftTightAmount) },
                onShiftRightArrow: { refineByAmount(currentGear.shiftTightAmount) },
                onUpArrow: { refineByAmount(-currentGear.wideAmount) },
                onDownArrow: { refineByAmount(currentGear.wideAmount) },
                onEscape: handleEscapeKey,
                onPick: pickCurrentFrame
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        )
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers: providers)
        }
    }

    // MARK: - Gear Control

    private func cycleGear() {
        currentGear = currentGear.next()
    }

    private func handleEscapeKey() {
        guard !isRefining else { return }
        // Esc from preview ALWAYS lands on the frame the user was looking at, and
        // disengages teleprompter mode. They explicitly chose to look at this frame;
        // don't yank them back to the bottom. They can scroll down to re-engage.
        scrollToIndex = currentFrameIndex
        isAutoScrolling = false
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.3)) {
                resetRefinement()
                viewMode = .grid
            }
        }
    }

    // MARK: - Frame Navigation

    private func navigateToPreviousFrame() {
        guard !isRefining else { return }
        guard currentFrameIndex > 0 else { return }
        currentFrameIndex -= 1
        previewFrame = viewModel.extractedFrames[currentFrameIndex]
        selectedFrame = previewFrame
        resetRefinement()
    }

    private func navigateToNextFrame() {
        guard !isRefining else { return }
        guard currentFrameIndex < viewModel.extractedFrames.count - 1 else { return }
        currentFrameIndex += 1
        previewFrame = viewModel.extractedFrames[currentFrameIndex]
        selectedFrame = previewFrame
        resetRefinement()
    }

    // MARK: - Frame Refinement

    private func refineByAmount(_ seconds: Double) {
        guard let frame = previewFrame,
              let videoURL = viewModel.selectedVideoURL else {
            return
        }

        let currentTimestamp = refinedTimestamp ?? frame.timestamp
        let duration = viewModel.videoDuration
        let unclamped = currentTimestamp + seconds
        var newTimestamp = max(0, unclamped)
        if duration > 0 {
            newTimestamp = min(newTimestamp, max(0, duration - 0.1))
        }
        if seconds > 0 && duration > 0 && unclamped >= duration - 0.1 {
            showToastNotification(message: "End of video reached", type: .success)
        } else if seconds < 0 && unclamped <= 0 {
            showToastNotification(message: "Beginning of video reached", type: .success)
        }

        if newTimestamp != currentTimestamp {
            Task { @MainActor in
                refineToTimestamp(newTimestamp, videoURL: videoURL)
            }
        }
    }

    private func refineToTimestamp(_ timestamp: Double, videoURL: URL) {
        guard !isRefining else { return }

        isRefining = true

        Task {
            do {
                let refinedImage = try await extractFrameAtTimestamp(timestamp, from: videoURL)

                await MainActor.run {
                    refinedTimestamp = timestamp
                    refinedFrame = Frame(
                        id: UUID(),
                        timestamp: timestamp,
                        image: refinedImage
                    )
                    isRefining = false
                }
            } catch {
                await MainActor.run {
                    showToastNotification(message: "Failed to refine frame: \(error.localizedDescription)", type: .error)
                    isRefining = false
                }
            }
        }
    }

    private func resetRefinement() {
        refinedTimestamp = nil
        refinedFrame = nil
        isRefining = false
    }

    // MARK: - Pick System

    private func pickCurrentFrame() {
        guard !isRefining else { return }
        guard let frame = previewFrame else { return }
        let displayFrame = refinedFrame ?? frame

        // Check if this source index is already picked — toggle unpick
        if pickedSourceIndices.contains(currentFrameIndex) {
            unpickCurrentFrame()
            return
        }

        // Avoid duplicates by timestamp proximity
        let isDuplicate = pickedFrames.contains { abs($0.timestamp - displayFrame.timestamp) < 0.01 }
        guard !isDuplicate else {
            showToastNotification(message: "Already picked", type: .success)
            return
        }

        pickedFrames.append(displayFrame)
        pickedSourceIndices.insert(currentFrameIndex)

        showToastNotification(message: "Picked \u{00B7} \(pickedFrames.count) total", type: .success)

        // Set scroll target before transitioning back to grid
        scrollToIndex = currentFrameIndex

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.3)) {
                resetRefinement()
                viewMode = .grid
            }
        }
    }

    private func unpickCurrentFrame() {
        // Remove by source index
        pickedFrames.removeAll { frame in
            // Find the pick that corresponds to this source index
            let sourceFrame = viewModel.extractedFrames[currentFrameIndex]
            return abs(frame.timestamp - sourceFrame.timestamp) < 0.01 ||
                   (refinedTimestamp != nil && abs(frame.timestamp - (refinedTimestamp ?? 0)) < 0.01)
        }
        pickedSourceIndices.remove(currentFrameIndex)
        showToastNotification(message: "Unpicked", type: .success)
    }

    private func extractFrameAtTimestamp(_ timestamp: Double, from videoURL: URL) async throws -> NSImage {
        return try await VideoProcessor.shared.extractSingleFrame(from: videoURL, at: timestamp)
    }

    // MARK: - Toast Notification Helpers

    private func showToastNotification(message: String, type: ToastType) {
        toastMessage = message
        toastType = type

        withAnimation(.easeInOut(duration: 0.3)) {
            showToast = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showToast = false
            }
        }
    }

    private func showToastNotificationLong(message: String, type: ToastType) {
        toastMessage = message
        toastType = type

        withAnimation(.easeInOut(duration: 0.3)) {
            showToast = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showToast = false
            }
        }
    }

    // MARK: - Image Export Utilities

    private func generateFilename(for frame: Frame) -> String {
        guard let videoURL = viewModel.selectedVideoURL else {
            let timestampForFilename = Frame.formatTimestampForFilename(frame.timestamp)
            return "frame_\(timestampForFilename)"
        }

        let videoName = videoURL.deletingPathExtension().lastPathComponent
        let timestampForFilename = Frame.formatTimestampForFilename(frame.timestamp)

        return "\(videoName)_frame_\(timestampForFilename)"
    }

    private func convertImageToData(_ image: NSImage, format: ExportFormat) -> Data? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }

        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)

        switch format {
        case .jpeg:
            return bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 1.0])
        case .png:
            return bitmapRep.representation(using: .png, properties: [:])
        case .tiff:
            return bitmapRep.representation(using: .tiff, properties: [:])
        }
    }

    // MARK: - Drag and Drop in Grid View

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (urlData, error) in
            DispatchQueue.main.async {
                if let urlData = urlData as? Data,
                   let url = URL(dataRepresentation: urlData, relativeTo: nil) {
                    self.processVideoFile(url: url)
                }
            }
        }
        return true
    }

    private func processVideoFile(url: URL) {
        // VideoProcessor handles AVFoundation (mov/mp4/m4v native) + FFmpeg fallback for the rest.
        // Camera RAW formats need vendor SDKs and aren't supported.
        let supportedExtensions: Set<String> = [
            "mp4", "mov", "m4v",
            "mkv", "webm",
            "avi", "wmv", "flv", "asf",
            "mts", "m2ts",
            "mxf",
            "ts", "mpg", "mpeg", "vob",
            "ogv", "ogg",
            "3gp", "3g2"
        ]
        let fileExtension = url.pathExtension.lowercased()

        guard supportedExtensions.contains(fileExtension) else {
            showToastNotification(message: "Unsupported file type: .\(fileExtension)", type: .error)
            return
        }

        viewModel.resetToUpload()
        viewModel.startProcessing(videoURL: url)
    }

}
