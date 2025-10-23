//
//  ResultsView.swift
//  Still Marker
//
//  Created by Claude Code on 2025-01-17.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers
import AVFoundation

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

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
    
    var accentColor: Color {
        switch self {
        case .success: 
            // Warm film emulsion green - like developing photo paper
            return Color(red: 0.5, green: 0.75, blue: 0.55)
        case .error: 
            // Cinematic crimson - matches background spotlight
            return Color(red: 0.8, green: 0.2, blue: 0.25)
        }
    }
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Refine Button Component

/// Simplified button component for frame refinement controls
/// Reduces view complexity by encapsulating repeated button structure
struct RefineButton: View {
    let label: RefineButtonLabel
    let action: () -> Void
    let isDisabled: Bool
    let opacity: Double

    enum RefineButtonLabel {
        case text(String)
        case icon(String)

        var isText: Bool {
            if case .text = self { return true }
            return false
        }
    }

    var body: some View {
        Button(action: action) {
            Group {
                switch label {
                case .text(let text):
                    Text(text)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                case .icon(let iconName):
                    Image(systemName: iconName)
                        .font(.system(size: 14, weight: .medium))
                        .symbolRenderingMode(.hierarchical)
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, label.isText ? 6 : 8)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(.thinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white.opacity(strokeOpacity), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
        .opacity(opacity)
    }

    private var strokeOpacity: Double {
        switch label {
        case .text(let text):
            return text == "10s" ? 0.4 : 0.35
        case .icon(let icon):
            return icon.contains("2") ? 0.3 : 0.2
        }
    }
}

// MARK: - Frame Preview Header Component

/// Header for frame preview with back button and frame counter
struct FramePreviewHeader: View {
    let currentFrameIndex: Int
    let totalFrames: Int
    let onBack: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .medium))
                        .symbolRenderingMode(.hierarchical)
                    Text("Back to Grid")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                }
                .foregroundColor(.white.opacity(0.9))
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.thinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())

            HStack {
                Spacer()
                Text("Frame \(currentFrameIndex + 1) of \(totalFrames)")
                    .font(.system(size: 12, weight: .light, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .padding(.leading, 60)
        .padding(.trailing, 60)
        .padding(.top, 16)
        .padding(.bottom, 32)
    }
}

// MARK: - Frame Navigation View Component

/// Frame display with previous/next navigation arrows
struct FrameNavigationView: View {
    let frame: Frame
    let isRefining: Bool
    let currentFrameIndex: Int
    let totalFrames: Int
    let onPrevious: () -> Void
    let onNext: () -> Void

    private var prevButtonOpacity: Double {
        currentFrameIndex <= 0 ? 0.3 : 1.0
    }

    private var nextButtonOpacity: Double {
        currentFrameIndex >= totalFrames - 1 ? 0.3 : 1.0
    }

    var body: some View {
        HStack(spacing: 0) {
            Spacer()
                .frame(maxWidth: .infinity)
                .layoutPriority(1)

            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(currentFrameIndex <= 0)
            .opacity(prevButtonOpacity)

            Spacer()
                .frame(maxWidth: .infinity)
                .layoutPriority(2)

            ZStack {
                Image(nsImage: frame.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if isRefining {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.6))
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                        )
                }
            }
            .layoutPriority(3)

            Spacer()
                .frame(maxWidth: .infinity)
                .layoutPriority(2)

            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(currentFrameIndex >= totalFrames - 1)
            .opacity(nextButtonOpacity)

            Spacer()
                .frame(maxWidth: .infinity)
                .layoutPriority(1)
        }
    }
}

// MARK: - Frame Controls View Component

/// Refinement controls and export button for frame preview
struct FrameControlsView: View {
    let frame: Frame
    let refinedTimestamp: Double?
    let isRefining: Bool
    let isExportHovered: Bool
    let onRefineBackward10s: () -> Void
    let onRefineBackward2s: () -> Void
    let onRefineBackwardCoarse: () -> Void
    let onRefineBackwardFine: () -> Void
    let onRefineForwardFine: () -> Void
    let onRefineForwardCoarse: () -> Void
    let onRefineForward2s: () -> Void
    let onRefineForward10s: () -> Void
    let onExport: () -> Void
    let onExportHover: (Bool) -> Void

    private var displayTimestamp: Double {
        refinedTimestamp ?? frame.timestamp
    }

    private var buttonOpacity: Double {
        isRefining ? 0.5 : 1.0
    }

    private var refineButtonOpacity: Double {
        isRefining || displayTimestamp <= 0 ? 0.5 : 1.0
    }

    private var refineButtonsDisabled: Bool {
        isRefining || displayTimestamp <= 0
    }

    private var statusText: String {
        refinedTimestamp != nil ? "Refined" : "Original"
    }

    private var statusColor: Color {
        refinedTimestamp != nil ? Color.white.opacity(0.9) : Color.white.opacity(0.7)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Refinement controls
            HStack(spacing: 8) {
                // Left buttons - backward navigation
                RefineButton(
                    label: .text("10s"),
                    action: onRefineBackward10s,
                    isDisabled: refineButtonsDisabled,
                    opacity: refineButtonOpacity
                )

                RefineButton(
                    label: .text("2s"),
                    action: onRefineBackward2s,
                    isDisabled: refineButtonsDisabled,
                    opacity: refineButtonOpacity
                )

                RefineButton(
                    label: .icon("chevron.left.2"),
                    action: onRefineBackwardCoarse,
                    isDisabled: refineButtonsDisabled,
                    opacity: refineButtonOpacity
                )

                RefineButton(
                    label: .icon("chevron.left"),
                    action: onRefineBackwardFine,
                    isDisabled: refineButtonsDisabled,
                    opacity: refineButtonOpacity
                )

                // Current timestamp display
                VStack(spacing: 4) {
                    Text(statusText)
                        .font(.system(size: 11, weight: .light, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))

                    Text(Frame.formatTimestamp(displayTimestamp))
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .foregroundColor(statusColor)
                        .padding(.horizontal, 12)
                }

                // Right buttons - forward navigation
                RefineButton(
                    label: .icon("chevron.right"),
                    action: onRefineForwardFine,
                    isDisabled: isRefining,
                    opacity: buttonOpacity
                )

                RefineButton(
                    label: .icon("chevron.right.2"),
                    action: onRefineForwardCoarse,
                    isDisabled: isRefining,
                    opacity: buttonOpacity
                )

                RefineButton(
                    label: .text("2s"),
                    action: onRefineForward2s,
                    isDisabled: isRefining,
                    opacity: buttonOpacity
                )

                RefineButton(
                    label: .text("10s"),
                    action: onRefineForward10s,
                    isDisabled: isRefining,
                    opacity: buttonOpacity
                )
            }

            // Export button
            Button("Export This Frame", action: onExport)
                .buttonStyle(FilmExportButtonStyle(
                    isHovered: isExportHovered && !isRefining,
                    startsAsGrey: false
                ))
                .onHover(perform: onExportHover)
                .disabled(isRefining)
                .opacity(buttonOpacity)
        }
        .padding(.vertical, 16)
    }
}

struct ResultsView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var selectedFrame: Frame?
    @State private var hoveredExportAllButton: Bool = false
    @State private var hoveredNewVideoButton: Bool = false
    @State private var hoveredFramePreviewExportButton: Bool = false
    @State private var viewMode: ViewMode = .grid
    @State private var isGridReady: Bool = false
    @State private var visibleFrameCount: Int = 0
    @State private var hoveredFrameID: UUID? = nil
    @State private var hoveredExportButtonID: UUID? = nil
    @State private var previewFrame: Frame?
    @State private var previewScaleMode: PreviewScaleMode = .fit
    @State private var selectedExportFormat: ExportFormat = .png
    @State private var currentFrameIndex: Int = 0
    
    // Frame refinement state
    @State private var refinedTimestamp: Double? = nil
    @State private var refinedFrame: Frame? = nil
    @State private var isRefining: Bool = false
    
    // Toast notification state
    @State private var toastMessage: String = ""
    @State private var toastType: ToastType = .success
    @State private var showToast: Bool = false
    
    
    private let columns = [
        GridItem(.adaptive(minimum: 200, maximum: 280), spacing: 16)
    ]
    
    var body: some View {
        ZStack {
            // Enhanced glassy dark mode with dot paper texture
            ZStack {
                // Base lifted black gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.12, green: 0.12, blue: 0.13),
                        Color(red: 0.1, green: 0.1, blue: 0.11)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Warmer spotlight gradient
                RadialGradient(
                    colors: [
                        Color(red: 0.32, green: 0.28, blue: 0.24).opacity(1.0),
                        Color(red: 0.24, green: 0.21, blue: 0.18).opacity(0.8),
                        Color(red: 0.16, green: 0.14, blue: 0.13).opacity(0.5),
                        Color.clear
                    ],
                    center: UnitPoint(x: 0.3, y: 0.45),
                    startRadius: 60,
                    endRadius: 400
                )
                .ignoresSafeArea()
                
                // Crimson spotlight
                RadialGradient(
                    colors: [
                        Color(red: 0.8, green: 0.1, blue: 0.2).opacity(0.36),
                        Color(red: 0.6, green: 0.08, blue: 0.15).opacity(0.24),
                        Color(red: 0.4, green: 0.05, blue: 0.1).opacity(0.12),
                        Color.clear
                    ],
                    center: UnitPoint(x: 0.85, y: 0.85),
                    startRadius: 40,
                    endRadius: 350
                )
                .ignoresSafeArea()
                
                // Glass morphism layer
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.02),
                        Color.clear,
                        Color.black.opacity(0.02)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
            }
            
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
                        .frame(height: 180) // Bottom margin - high enough to clear refinement controls
                }
                .animation(.easeInOut(duration: 0.3), value: showToast)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
        }
        .navigationTitle("")
    }
    
    private var gridView: some View {
        VStack(spacing: 0) {
            // Header with controls
            headerView
            
            
            // Frames grid with loading state protection
            Group {
                if !isGridReady {
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        
                        Text("Loading \(viewModel.extractedFrames.count) frames...")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        // Delay grid rendering to prevent crash
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            isGridReady = true
                            // Start progressive loading with first batch
                            loadFramesProgressively()
                        }
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(0..<min(visibleFrameCount, viewModel.extractedFrames.count), id: \.self) { index in
                                let frame = viewModel.extractedFrames[index]
                                Group {
                                    if frame.thumbnail.isValid && !frame.formattedTimestamp.isEmpty {
                                        FrameCard(
                                            frame: frame,
                                            isSelected: selectedFrame?.id == frame.id,
                                            isHovered: hoveredFrameID == frame.id,
                                            isExportHovered: hoveredExportButtonID == frame.id,
                                            onTap: {
                                                selectedFrame = frame
                                                previewFrame = frame
                                                currentFrameIndex = index
                                                withAnimation(.easeInOut(duration: 0.3)) {
                                                    viewMode = .framePreview
                                                }
                                            },
                                            onDoubleTap: {
                                                selectedFrame = frame
                                                previewFrame = frame
                                                currentFrameIndex = index
                                                withAnimation(.easeInOut(duration: 0.3)) {
                                                    viewMode = .framePreview
                                                }
                                            },
                                            onExport: { exportFrame(frame) },
                                            onHover: { isHovering in
                                                hoveredFrameID = isHovering ? frame.id : nil
                                            },
                                            onExportHover: { isHovering in
                                                hoveredExportButtonID = isHovering ? frame.id : nil
                                            }
                                        )
                                    } else {
                                        // Error card for invalid frames
                                        VStack {
                                            Image(systemName: "exclamationmark.triangle")
                                                .font(.system(size: 24, weight: .light))
                                                .foregroundColor(.red.opacity(0.7))
                                                .symbolRenderingMode(.hierarchical)
                                            Text("Invalid Frame")
                                                .font(.system(size: 12, weight: .light, design: .monospaced))
                                                .foregroundColor(.white.opacity(0.5))
                                        }
                                        .frame(height: 150)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(.thinMaterial)
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 24)
                    }
                }
            }
            .background(Color.clear)
            .onChange(of: viewModel.extractedFrames.count) { _ in
                // Reset loading state when frames change
                isGridReady = false
                visibleFrameCount = 0
            }
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers: providers)
        }
    }
    
    private var headerView: some View {
        HStack(spacing: 12) {    // Slightly reduced spacing to help alignment
            // New Video button - matches grid cell width
            Button(action: {
                viewModel.resetToUpload()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .medium))
                        .symbolRenderingMode(.hierarchical)
                    Text("New Video")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                }
            }
            .frame(width: 200)
            .buttonStyle(GreyNavigationButtonStyle(isHovered: hoveredNewVideoButton))
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.1)) {
                    hoveredNewVideoButton = hovering
                }
            }
            
            Spacer()
            
            // Centered title and frame count
            VStack(spacing: 4) {
                Text("\(viewModel.extractedFrames.count) frames extracted")
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
                
                if let videoURL = viewModel.selectedVideoURL {
                    Text("from \(videoURL.lastPathComponent)")
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            Spacer()
            
            // Export All button - matches grid cell width
            Button(action: {
                exportAllFrames()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 12, weight: .medium))
                        .symbolRenderingMode(.hierarchical)
                    Text("Export All")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                }
            }
            .frame(width: 200)
            .buttonStyle(FilmExportButtonStyle(isHovered: hoveredExportAllButton, startsAsGrey: false))
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.1)) {
                    hoveredExportAllButton = hovering
                }
            }
        }
        .padding(.leading, -8)   // Move New Video button 1 final point left
        .padding(.trailing, -5)  // Move Export All button 1 more point left
        .padding(.top, 8)
        .padding(.bottom, 32)    // Double the previous padding for better balance
    }
    
    private var toastView: some View {
        HStack(spacing: 14) {
            // Icon with glassy circular background
            ZStack {
                Circle()
                    .fill(toastType.accentColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Circle()
                    .strokeBorder(toastType.accentColor.opacity(0.3), lineWidth: 1)
                    .frame(width: 36, height: 36)
                
                Image(systemName: toastType.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(toastType.accentColor)
                    .symbolRenderingMode(.hierarchical)
            }
            
            Text(toastMessage)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.95))
                .multilineTextAlignment(.leading)
                .lineLimit(2)
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            ZStack {
                // Frosted glass base
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)
                
                // Simple gradient overlay
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [
                                toastType.accentColor.opacity(0.08),
                                Color.clear,
                                Color.black.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Border with accent hint
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                toastType.accentColor.opacity(0.4),
                                Color.white.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
        )
        .shadow(color: toastType.accentColor.opacity(0.15), radius: 12, x: 0, y: 6)
        .shadow(color: Color.black.opacity(0.25), radius: 24, x: 0, y: 8)
        .padding(.horizontal, 40)
    }
    
    private func loadFramesProgressively() {
        let batchSize = 8  // Load 8 frames at a time
        let totalFrames = viewModel.extractedFrames.count
        
        // Start with first batch
        visibleFrameCount = min(batchSize, totalFrames)
        
        // Continue loading in batches if there are more frames
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
        // Extract @State values to avoid capture issues
        let currentFormat = selectedExportFormat
        let currentFormatExtension = currentFormat.fileExtension
        let currentFormatIndex = ExportFormat.allCases.firstIndex(of: currentFormat) ?? 0

        let savePanel = NSSavePanel()
        savePanel.title = "Export Frame"
        savePanel.showsResizeIndicator = true
        savePanel.showsHiddenFiles = false
        savePanel.canCreateDirectories = true
        // Allow all content types so format selection works properly
        savePanel.allowedContentTypes = []

        // Generate enhanced filename with video name prefix AND extension
        savePanel.nameFieldStringValue = "\(generateFilename(for: frame)).\(currentFormatExtension)"

        // Create accessory view for format selection
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
                
                // Create final URL with correct extension
                let finalURL = url.deletingPathExtension().appendingPathExtension(selectedFormat.fileExtension)
                
                if let imageData = convertImageToData(frame.image, format: selectedFormat) {
                    do {
                        try imageData.write(to: finalURL)
                        print("Frame exported successfully to: \(finalURL.path)")
                        showToast(message: "Frame exported: \(finalURL.lastPathComponent)", type: .success)
                    } catch {
                        print("Failed to save frame: \(error)")
                        showToast(message: "Export failed: \(error.localizedDescription)", type: .error)
                    }
                } else {
                    showToast(message: "Failed to convert image to \(selectedFormat.rawValue)", type: .error)
                }
            }
        }
    }
    
    private func exportAllFrames() {
        guard !viewModel.extractedFrames.isEmpty else {
            showToast(message: "No frames to export", type: .error)
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
        
        // Create accessory view for format selection
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
        
        // Ensure options are always visible
        openPanel.isAccessoryViewDisclosed = true
        
        openPanel.begin { response in
            if response == .OK, let folderURL = openPanel.url {
                let selectedFormat = ExportFormat.allCases[formatSelector.indexOfSelectedItem]
                self.performBatchExport(to: folderURL, format: selectedFormat)
            }
        }
    }
    
    private func performBatchExport(to folderURL: URL, format: ExportFormat) {
        // Show immediate feedback that export started
        showToast(message: "Exporting \(viewModel.extractedFrames.count) frames...", type: .success)
        
        DispatchQueue.global(qos: .userInitiated).async {
            var successCount = 0
            var errorCount = 0
            
            for frame in self.viewModel.extractedFrames {
                // Generate enhanced filename with video name prefix
                let filename = "\(self.generateFilename(for: frame)).\(format.fileExtension)"
                let fileURL = folderURL.appendingPathComponent(filename)
                
                if let imageData = self.convertImageToData(frame.image, format: format) {
                    do {
                        try imageData.write(to: fileURL)
                        successCount += 1
                    } catch {
                        print("Failed to save frame \(frame.formattedTimestamp): \(error)")
                        errorCount += 1
                    }
                } else {
                    print("Failed to convert frame \(frame.formattedTimestamp) to \(format.rawValue)")
                    errorCount += 1
                }
            }
            
            DispatchQueue.main.async {
                if errorCount == 0 {
                    self.showToastLong(message: "✅ Successfully exported \(successCount) frames to \(folderURL.lastPathComponent)", type: .success)
                } else {
                    self.showToastLong(message: "Export completed: \(successCount) successes, \(errorCount) errors", type: .error)
                }
            }
        }
    }

}

// MARK: - Frame Preview View

extension ResultsView {
    private func framePreviewView(frame: Frame) -> some View {
        let displayFrame = refinedFrame ?? frame

        return VStack {
            FramePreviewHeader(
                currentFrameIndex: currentFrameIndex,
                totalFrames: viewModel.extractedFrames.count,
                onBack: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        resetRefinement()
                        viewMode = .grid
                    }
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

            FrameControlsView(
                frame: displayFrame,
                refinedTimestamp: refinedTimestamp,
                isRefining: isRefining,
                isExportHovered: hoveredFramePreviewExportButton,
                onRefineBackward10s: refineBackward10s,
                onRefineBackward2s: refineBackward2s,
                onRefineBackwardCoarse: refineBackwardCoarse,
                onRefineBackwardFine: refineBackwardFine,
                onRefineForwardFine: refineForwardFine,
                onRefineForwardCoarse: refineForwardCoarse,
                onRefineForward2s: refineForward2s,
                onRefineForward10s: refineForward10s,
                onExport: { exportFrame(displayFrame) },
                onExportHover: { hovering in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        hoveredFramePreviewExportButton = hovering
                    }
                }
            )

            Spacer()

            // Keyboard shortcuts hint
            Text("← → frame  •  ⇧← ⇧→ 2s  •  ↑ ↓ photos  •  ESC exit")
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundColor(.white.opacity(0.4))
                .padding(.bottom, 20)
        }
        .background(
            KeyEventHandlingView(
                onLeftArrow: refineBackwardFine,        // ← = -1 frame
                onRightArrow: refineForwardFine,        // → = +1 frame
                onShiftLeftArrow: refineBackward2s,     // ⇧← = -2s
                onShiftRightArrow: refineForward2s,     // ⇧→ = +2s
                onUpArrow: navigateToPreviousFrame,     // ↑ = prev grid frame
                onDownArrow: navigateToNextFrame,       // ↓ = next grid frame
                onEscape: handleEscapeKey               // ESC = close preview
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        )
    }
    
    // MARK: - Navigation Functions
    
    private func navigateToPreviousFrame() {
        let refiningState = isRefining
        print("⬅️ navigateToPreviousFrame called - isRefining: \(refiningState)")
        // Don't interrupt active refinement
        guard !isRefining else {
            print("⛔️ Previous frame navigation blocked - refinement in progress")
            return
        }
        guard currentFrameIndex > 0 else { return }
        currentFrameIndex -= 1
        previewFrame = viewModel.extractedFrames[currentFrameIndex]
        selectedFrame = previewFrame
        resetRefinement()
    }
    
    private func navigateToNextFrame() {
        let refiningState = isRefining
        print("➡️ navigateToNextFrame called - isRefining: \(refiningState)")
        // Don't interrupt active refinement
        guard !isRefining else {
            print("⛔️ Next frame navigation blocked - refinement in progress")
            return
        }
        guard currentFrameIndex < viewModel.extractedFrames.count - 1 else { return }
        currentFrameIndex += 1
        previewFrame = viewModel.extractedFrames[currentFrameIndex]
        selectedFrame = previewFrame
        resetRefinement()
    }

    private func handleEscapeKey() {
        print("⚠️ Escape handler called")
        // Don't interrupt active refinement
        guard !isRefining else {
            print("⛔️ Escape blocked - refinement in progress")
            return
        }
        withAnimation(.easeInOut(duration: 0.3)) {
            resetRefinement()
            viewMode = .grid
        }
    }

    // MARK: - Frame Refinement Functions
    
    private func refineBackward10s() {
        print("🔵 refineBackward10s() called")
        refineByAmount(-10.0) // Back 10 seconds
    }
    
    private func refineBackward2s() {
        print("🔵🔵🔵 refineBackward2s() ENTERED 🔵🔵🔵")
        print("🔵 refineBackward2s() called")
        refineByAmount(-2.0) // Back 2 seconds
        print("🔵🔵🔵 refineBackward2s() EXITED 🔵🔵🔵")
    }
    
    private func refineBackwardCoarse() {
        print("🔵 refineBackwardCoarse() called")
        refineByAmount(-0.5) // Back 0.5 seconds
    }
    
    private func refineBackwardFine() {
        print("🔵 refineBackwardFine() called")
        refineByAmount(-0.033) // Back 1 frame (assuming ~30fps)
    }
    
    private func refineForwardFine() {
        print("🔵 refineForwardFine() called")
        refineByAmount(0.033) // Forward 1 frame (assuming ~30fps)
    }
    
    private func refineForwardCoarse() {
        print("🔵 refineForwardCoarse() called")
        refineByAmount(0.5) // Forward 0.5 seconds
    }
    
    private func refineForward2s() {
        print("🔵 refineForward2s() called")
        refineByAmount(2.0) // Forward 2 seconds
    }
    
    private func refineForward10s() {
        print("🔵 refineForward10s() called")
        refineByAmount(10.0) // Forward 10 seconds
    }
    
    private func refineByAmount(_ seconds: Double) {
        let refiningState = isRefining
        print("🟢🟢🟢 refineByAmount ENTERED - seconds: \(seconds), isRefining: \(refiningState) 🟢🟢🟢")
        print("🟢 refineByAmount called with \(seconds)s")
        guard let frame = previewFrame,
              let videoURL = viewModel.selectedVideoURL else {
            print("❌ No frame or video URL")
            return
        }
        
        print("🟢 Frame and video URL OK")
        let currentTimestamp = refinedTimestamp ?? frame.timestamp
        let newTimestamp = max(0, currentTimestamp + seconds)
        print("🟢 Timestamps calculated: current=\(currentTimestamp), new=\(newTimestamp)")
        
        if newTimestamp != currentTimestamp {
            print("🟢 Calling refineToTimestamp")
            // Dispatch to avoid blocking main thread
            Task { @MainActor in
                refineToTimestamp(newTimestamp, videoURL: videoURL)
            }
        } else {
            print("⚠️ Timestamps are the same, skipping refinement")
        }
        print("🟢🟢🟢 refineByAmount EXITED 🟢🟢🟢")
    }
    
    private func refineToTimestamp(_ timestamp: Double, videoURL: URL) {
        print("🟡 refineToTimestamp called with timestamp=\(timestamp)")
        // Guard against concurrent refinement requests
        guard !isRefining else {
            print("⚠️ Refinement already in progress, ignoring request")
            return
        }
        
        print("🟡 Setting isRefining = true")
        isRefining = true
        
        print("🟡 Creating Task")
        Task {
            print("🟡 Inside Task, about to extract frame")
            do {
                let refinedImage = try await extractFrameAtTimestamp(timestamp, from: videoURL)
                print("✅ Frame extracted successfully")
                
                await MainActor.run {
                    print("✅✅✅ Refinement complete, updating UI ✅✅✅")
                    refinedTimestamp = timestamp
                    refinedFrame = Frame(
                        id: UUID(),
                        timestamp: timestamp,
                        image: refinedImage
                    )
                    print("🔓 Setting isRefining = false")
                    isRefining = false
                    print("✅✅✅ UI updated successfully ✅✅✅")
                }
            } catch {
                await MainActor.run {
                    showToast(message: "Failed to refine frame: \(error.localizedDescription)", type: .error)
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
    
    private func extractFrameAtTimestamp(_ timestamp: Double, from videoURL: URL) async throws -> NSImage {
        // Create temporary file for the extracted frame
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("refined_frame_\(UUID().uuidString).jpg")
        
        defer {
            try? FileManager.default.removeItem(at: tempFile)
        }
        
        // Use FFmpeg to extract single frame
        let ffmpegProcessor = FFmpegProcessor()
        try await ffmpegProcessor.extractSingleFrame(from: videoURL, at: timestamp, outputURL: tempFile)
        
        // Load the image
        guard let image = NSImage(contentsOf: tempFile) else {
            throw NSError(domain: "FrameRefinement", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to load refined frame"])
        }
        
        return image
    }
    
    // MARK: - Toast Notification Helpers
    
    private func showToast(message: String, type: ToastType) {
        toastMessage = message
        toastType = type
        
        withAnimation(.easeInOut(duration: 0.3)) {
            showToast = true
        }
        
        // Auto-hide after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showToast = false
            }
        }
    }
    
    private func showToastLong(message: String, type: ToastType) {
        toastMessage = message
        toastType = type
        
        withAnimation(.easeInOut(duration: 0.3)) {
            showToast = true
        }
        
        // Auto-hide after 5 seconds for batch operations
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showToast = false
            }
        }
    }
    
    // MARK: - Image Export Utilities
    
    private func generateFilename(for frame: Frame) -> String {
        guard let videoURL = viewModel.selectedVideoURL else {
            // Fallback to simple filename if no video URL
            let timestampForFilename = Frame.formatTimestampForFilename(frame.timestamp)
            return "frame_\(timestampForFilename)"
        }
        
        // Get video filename without extension
        let videoName = videoURL.deletingPathExtension().lastPathComponent
        
        // Use the safe timestamp formatting method
        let timestampForFilename = Frame.formatTimestampForFilename(frame.timestamp)
        
        // Format: [video_name]_frame_[timestamp]
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
        // Basic validation
        let allowedExtensions = ["mp4", "mov", "avi", "mkv", "m4v", "wmv", "flv", "webm"]
        let fileExtension = url.pathExtension.lowercased()
        
        guard allowedExtensions.contains(fileExtension) else {
            showToast(message: "Unsupported file type: .\(fileExtension)", type: .error)
            return
        }
        
        // Reset to upload view and start processing new video
        viewModel.resetToUpload()
        viewModel.startProcessing(videoURL: url)
    }
    
}

struct GreyNavigationButtonStyle: ButtonStyle {
    let isHovered: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundColor(.white.opacity(0.9))
            .opacity(isHovered ? 1.0 : 0.85)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.4))
                    .overlay(
                        // Enhanced glassy hover overlay for grey buttons
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.ultraThinMaterial)
                            .opacity(isHovered ? 0.7 : 0.3)
                            .overlay(
                                // Gradient highlight + hard light combo
                                ZStack {
                                    // Subtle gradient background
                                    LinearGradient(
                                        colors: [.white.opacity(0.2), .clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    .opacity(isHovered ? 1.0 : 0.0)
                                    
                                    // Hard light edge on top
                                    VStack {
                                        Rectangle()
                                            .fill(.white.opacity(0.55))
                                            .frame(height: 2)
                                            .opacity(isHovered ? 1.0 : 0.0)
                                        Spacer()
                                    }
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            )
                    )
            )
            .animation(.easeInOut(duration: 0.1), value: isHovered)
    }
}

struct FilmExportButtonStyle: ButtonStyle {
    let isHovered: Bool
    let startsAsGrey: Bool // New parameter for grid vs main export buttons
    
    init(isHovered: Bool, startsAsGrey: Bool = false) {
        self.isHovered = isHovered
        self.startsAsGrey = startsAsGrey
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundColor(.black) // Black text works on both grey and gold
            .opacity(isHovered ? 1.0 : 0.85) // Subtle opacity change
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(buttonBackgroundColor) // Dynamic background color
                    .overlay(
                        // Glassy hover overlay
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.ultraThinMaterial) // Glass effect
                            .opacity(isHovered ? 0.7 : (startsAsGrey ? 0.3 : 0.0)) // Always subtle glass on grey buttons
                            .overlay(
                                // Gradient highlight + hard light combo
                                ZStack {
                                    // Subtle gradient background
                                    LinearGradient(
                                        colors: [.white.opacity(0.2), .clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    .opacity(isHovered ? 1.0 : 0.0)
                                    
                                    // Hard light edge on top
                                    VStack {
                                        Rectangle()
                                            .fill(.white.opacity(0.55)) // Split the difference
                                            .frame(height: 2) // Hard edge
                                            .opacity(isHovered ? 1.0 : 0.0)
                                        Spacer()
                                    }
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            )
                    )
            )
            .animation(.easeInOut(duration: 0.1), value: isHovered) // Fast transition, no scale
    }
    
    private var buttonBackgroundColor: Color {
        if startsAsGrey {
            // Grid buttons: Grey → Gold
            return isHovered ? Color(hex: "#E6A532") : Color.gray.opacity(0.4)
        } else {
            // Export All & Preview buttons: Always Gold
            return Color(hex: "#E6A532")
        }
    }
}

struct FrameCard: View {
    let frame: Frame
    let isSelected: Bool
    let isHovered: Bool
    let isExportHovered: Bool
    let onTap: () -> Void
    let onDoubleTap: () -> Void
    let onExport: () -> Void
    let onHover: (Bool) -> Void
    let onExportHover: (Bool) -> Void

    @Environment(\.accessibilityReduceMotion) var reduceMotion

    private var hoverAnimation: Animation {
        if reduceMotion {
            return .linear(duration: 0.1)
        } else {
            return .spring(response: 0.35, dampingFraction: 0.78, blendDuration: 0)
        }
    }

    private var exitAnimation: Animation {
        if reduceMotion {
            return .linear(duration: 0.1)
        } else {
            return .easeOut(duration: 0.18)
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Image(nsImage: frame.thumbnail)
                    .resizable()
                    .frame(width: 200, height: 112)
                    .cornerRadius(8)
                    .brightness(isHovered ? 0.08 : 0.0) // Light through film effect
                    .saturation(isHovered ? 1.05 : 1.0) // Subtle richness boost

                // Subtle luminous border on hover - like backlit film edge
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.98, blue: 0.94, opacity: isHovered ? 0.5 : 0.0),
                                Color(red: 1.0, green: 0.98, blue: 0.94, opacity: isHovered ? 0.3 : 0.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )

                // Selection border
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(hex: "#E6A532"), lineWidth: 3)
                }

                // Thick glass eye icon badge on hover
                if isHovered {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .overlay(
                            Image(systemName: "eye.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .symbolRenderingMode(.hierarchical)
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                        .shadow(color: Color.white.opacity(0.2), radius: 4, x: 0, y: 2)
                        .scaleEffect(isHovered ? 1.0 : 0.0)
                        .animation(
                            .spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0)
                                .delay(0.05),
                            value: isHovered
                        )
                }
            }
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .shadow(
                color: Color.white.opacity(isHovered ? 0.12 : 0),
                radius: 4,
                x: 0,
                y: 2
            )
            .shadow(
                color: isHovered ? Color(red: 0.32, green: 0.28, blue: 0.24).opacity(0.4) : Color.black.opacity(0.2),
                radius: isHovered ? 16 : 8,
                x: 0,
                y: isHovered ? 8 : 4
            )
            .animation(
                isHovered ? hoverAnimation : exitAnimation,
                value: isHovered
            )
            .onTapGesture(count: 2) { onDoubleTap() }
            .onTapGesture { onTap() }
            .onHover { hovering in
                onHover(hovering)
            }
            
            // Align timecode left and export button right
            HStack {
                Text(frame.formattedTimestamp)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                Button("Export") {
                    onExport()
                }
                .buttonStyle(FilmExportButtonStyle(isHovered: isExportHovered, startsAsGrey: true))
                .onHover { hovering in
                    onExportHover(hovering)
                }
            }
            .frame(width: 200) // Match the image width
        }
    }
}

// MARK: - Keyboard Event Handling

struct KeyEventHandlingView: NSViewRepresentable {
    let onLeftArrow: () -> Void
    let onRightArrow: () -> Void
    let onShiftLeftArrow: () -> Void
    let onShiftRightArrow: () -> Void
    let onUpArrow: () -> Void
    let onDownArrow: () -> Void
    let onEscape: () -> Void

    func makeNSView(context: Context) -> KeyCaptureView {
        let view = KeyCaptureView()
        view.onLeftArrow = onLeftArrow
        view.onRightArrow = onRightArrow
        view.onShiftLeftArrow = onShiftLeftArrow
        view.onShiftRightArrow = onShiftRightArrow
        view.onUpArrow = onUpArrow
        view.onDownArrow = onDownArrow
        view.onEscape = onEscape
        return view
    }

    func updateNSView(_ nsView: KeyCaptureView, context: Context) {
        nsView.onLeftArrow = onLeftArrow
        nsView.onRightArrow = onRightArrow
        nsView.onShiftLeftArrow = onShiftLeftArrow
        nsView.onShiftRightArrow = onShiftRightArrow
        nsView.onUpArrow = onUpArrow
        nsView.onDownArrow = onDownArrow
        nsView.onEscape = onEscape
    }
}

class KeyCaptureView: NSView {
    var onLeftArrow: (() -> Void)?
    var onRightArrow: (() -> Void)?
    var onShiftLeftArrow: (() -> Void)?
    var onShiftRightArrow: (() -> Void)?
    var onUpArrow: (() -> Void)?
    var onDownArrow: (() -> Void)?
    var onEscape: (() -> Void)?

    override var acceptsFirstResponder: Bool { true }
    override var canBecomeKeyView: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        // Delay to ensure the view is fully set up
        DispatchQueue.main.async { [weak self] in
            self?.window?.makeFirstResponder(self)
        }
    }

    override func mouseDown(with event: NSEvent) {
        // Make this view first responder when clicked
        window?.makeFirstResponder(self)
        super.mouseDown(with: event)
    }

    override func keyDown(with event: NSEvent) {
        let isShiftPressed = event.modifierFlags.contains(.shift)
        print("🎹 Key pressed: \(event.keyCode), Shift: \(isShiftPressed)")

        switch event.keyCode {
        case 123: // Left arrow
            if isShiftPressed {
                print("⬅️⇧ Shift+Left arrow pressed")
                onShiftLeftArrow?()
            } else {
                print("⬅️ Left arrow pressed")
                onLeftArrow?()
            }
        case 124: // Right arrow
            if isShiftPressed {
                print("➡️⇧ Shift+Right arrow pressed")
                onShiftRightArrow?()
            } else {
                print("➡️ Right arrow pressed")
                onRightArrow?()
            }
        case 125: // Down arrow
            print("⬇️ Down arrow pressed")
            onDownArrow?()
        case 126: // Up arrow
            print("⬆️ Up arrow pressed")
            onUpArrow?()
        case 53: // Escape
            print("🔙 Escape pressed")
            onEscape?()
        default:
            print("🔤 Other key: \(event.keyCode)")
            super.keyDown(with: event)
        }
    }

    // Accept all key events
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
}