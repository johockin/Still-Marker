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
    
    var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
}

struct ResultsView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var selectedFrame: Frame?
    @State private var hoveredFrame: Frame?
    @State private var viewMode: ViewMode = .grid
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
        let _ = print("🏁 ResultsView.body called with \(viewModel.extractedFrames.count) frames")
        return ZStack {
            // More visible dark mode with lifted blacks
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.12, green: 0.12, blue: 0.13), // Lifted black
                        Color(red: 0.1, green: 0.1, blue: 0.11) // Slightly deeper
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Warm spotlight overlay for visibility
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.22, green: 0.20, blue: 0.18).opacity(0.5),
                        Color.clear
                    ]),
                    center: UnitPoint(x: 0.5, y: 0.1),
                    startRadius: 100,
                    endRadius: 600
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
                        .frame(height: 80) // Bottom margin
                }
                .animation(.easeInOut(duration: 0.3), value: showToast)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("New Video") {
                    viewModel.resetToUpload()
                }
                .foregroundColor(.white.opacity(0.9))
                .font(.system(size: 14, weight: .medium, design: .monospaced))
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
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var gridView: some View {
        VStack(spacing: 0) {
            // Header with controls
            headerView
            
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)
                .padding(.vertical, 8)
            
            // Frames grid with error handling
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(Array(viewModel.extractedFrames.enumerated()), id: \.element.id) { index, frame in
                        Group {
                            if frame.thumbnail.isValid && !frame.formattedTimestamp.isEmpty {
                                FrameCard(
                                    frame: frame,
                                    isSelected: selectedFrame?.id == frame.id,
                                    isHovered: hoveredFrame?.id == frame.id,
                                    onExport: { exportFrame(frame) }
                                )
                            } else {
                                // Error card for invalid frames
                                VStack {
                                    Image(systemName: "exclamationmark.triangle")
                                        .font(.system(size: 24, weight: .light))
                                        .foregroundColor(.red.opacity(0.7))
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
                        .onTapGesture {
                            selectedFrame = frame
                            previewFrame = frame
                            currentFrameIndex = index
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewMode = .framePreview
                            }
                        }
                        .onHover { hovering in
                            let _ = print("🖱️ HOVER: Frame \(frame.formattedTimestamp) hovering=\(hovering)")
                            hoveredFrame = hovering ? frame : nil
                            let _ = print("🖱️ HOVER SET: hoveredFrame=\(hoveredFrame?.formattedTimestamp ?? "nil")")
                        }
                        .opacity(1.0)
                        .animation(.easeIn(duration: 0.4).delay(Double(index) * 0.1), value: viewModel.extractedFrames.count)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .background(Color.clear)
        }
    }
    
    private var headerView: some View {
        HStack {
            // Frame count and video info - Professional dark edit suite hierarchy
            VStack(alignment: .leading, spacing: 4) {
                Text("\(viewModel.extractedFrames.count) frames extracted")
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9)) // High contrast for professionals
                
                if let videoURL = viewModel.selectedVideoURL {
                    Text("from \(videoURL.lastPathComponent)")
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5)) // Clean hierarchy
                }
            }
            
            Spacer()
            
            // Controls
            HStack(spacing: 12) {
                // Offset control
                Button(action: {
                    viewModel.shiftOffset()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 14))
                        Text("Shift +\(viewModel.currentOffset + 1)s")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                    }
                    .foregroundColor(.white.opacity(0.9)) // High contrast for dark backgrounds
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
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
                
                // Export all button - Warm Emulsion with maximum glass
                Button(action: {
                    exportAllFrames()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 14))
                        Text("Export All")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 0.8, green: 0.561, blue: 0.173)) // Warm Emulsion #CC8F2C
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.thinMaterial) // Maximum glass morphism
                                    .blendMode(.overlay)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: Color(red: 0.8, green: 0.561, blue: 0.173).opacity(0.3), radius: 4, x: 0, y: 2)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
    
    private var toastView: some View {
        HStack(spacing: 12) {
            Image(systemName: toastType.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Text(toastMessage)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(toastType.color.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(toastType.color, lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 24)
    }
    
    private func exportFrame(_ frame: Frame) {
        let savePanel = NSSavePanel()
        savePanel.title = "Export Frame"
        savePanel.showsResizeIndicator = true
        savePanel.showsHiddenFiles = false
        savePanel.canCreateDirectories = true
        // Allow all content types so format selection works properly
        savePanel.allowedContentTypes = []
        
        // Generate enhanced filename with video name prefix
        savePanel.nameFieldStringValue = generateFilename(for: frame)
        
        // Create accessory view for format selection
        let formatSelector = NSPopUpButton()
        for format in ExportFormat.allCases {
            formatSelector.addItem(withTitle: format.rawValue)
        }
        formatSelector.selectItem(at: ExportFormat.allCases.firstIndex(of: selectedExportFormat) ?? 0)
        
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
    
    private func framePreviewView(frame: Frame) -> some View {
        let displayFrame = refinedFrame ?? frame
        let displayTimestamp = refinedTimestamp ?? frame.timestamp
        
        return VStack {
            // Back button
            HStack {
                Button("← Back to Grid") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        resetRefinement()
                        viewMode = .grid
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                Text("Frame Preview")
                    .font(.system(size: 18, weight: .light, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
                
                Spacer()
            }
            .padding()
            
            // Frame display with navigation
            Spacer()
            
            HStack {
                // Previous frame button
                Button(action: navigateToPreviousFrame) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .padding()
                        .background(.thinMaterial)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(currentFrameIndex <= 0)
                .opacity(currentFrameIndex <= 0 ? 0.3 : 1.0)
                
                Spacer()
                
                // Frame image with refinement overlay
                ZStack {
                    Image(nsImage: displayFrame.image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Loading overlay for refinement
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
                
                Spacer()
                
                // Next frame button
                Button(action: navigateToNextFrame) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .padding()
                        .background(.thinMaterial)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(currentFrameIndex >= viewModel.extractedFrames.count - 1)
                .opacity(currentFrameIndex >= viewModel.extractedFrames.count - 1 ? 0.3 : 1.0)
            }
            
            // Frame refinement and export controls
            VStack(spacing: 16) {
                // Refinement controls: << < timecode > >>
                HStack(spacing: 12) {
                    // << Coarse backward (0.5s)
                    Button(action: refineBackwardCoarse) {
                        Image(systemName: "chevron.left.2")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.thinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isRefining || displayTimestamp <= 0)
                    .opacity(isRefining || displayTimestamp <= 0 ? 0.5 : 1.0)
                    
                    // < Fine backward (1 frame)
                    Button(action: refineBackwardFine) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.thinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isRefining || displayTimestamp <= 0)
                    .opacity(isRefining || displayTimestamp <= 0 ? 0.5 : 1.0)
                    
                    // Current timestamp display
                    VStack(spacing: 4) {
                        Text(refinedTimestamp != nil ? "Refined" : "Original")
                            .font(.system(size: 11, weight: .light, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text(Frame.formatTimestamp(displayTimestamp))
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                            .foregroundColor(refinedTimestamp != nil ? .white.opacity(0.9) : .white.opacity(0.7))
                            .padding(.horizontal, 12)
                    }
                    
                    // > Fine forward (1 frame)
                    Button(action: refineForwardFine) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.thinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isRefining)
                    .opacity(isRefining ? 0.5 : 1.0)
                    
                    // >> Coarse forward (0.5s)
                    Button(action: refineForwardCoarse) {
                        Image(systemName: "chevron.right.2")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.thinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isRefining)
                    .opacity(isRefining ? 0.5 : 1.0)
                }
                
                // Export button - Warm Emulsion with maximum glass
                Button("Export This Frame") {
                    exportFrame(displayFrame)
                }
                .buttonStyle(PlainButtonStyle())
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(red: 0.8, green: 0.561, blue: 0.173)) // Warm Emulsion #CC8F2C
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.thinMaterial) // Maximum glass morphism
                                .blendMode(.overlay)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: Color(red: 0.8, green: 0.561, blue: 0.173).opacity(0.3), radius: 4, x: 0, y: 2)
                )
                .disabled(isRefining)
                .opacity(isRefining ? 0.5 : 1.0)
            }
            .padding(.vertical, 16)
            
            Spacer()
            
            // Frame info with navigation
            VStack(spacing: 8) {
                Text("\(currentFrameIndex + 1) of \(viewModel.extractedFrames.count)")
                    .font(.system(size: 12, weight: .light, design: .monospaced))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding()
        }
        .background(
            // Keyboard event capture overlay
            KeyEventHandlingView(
                onLeftArrow: navigateToPreviousFrame,
                onRightArrow: navigateToNextFrame,
                onEscape: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        resetRefinement()
                        viewMode = .grid
                    }
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        )
    }
    
    // MARK: - Navigation Functions
    
    private func navigateToPreviousFrame() {
        guard currentFrameIndex > 0 else { return }
        currentFrameIndex -= 1
        previewFrame = viewModel.extractedFrames[currentFrameIndex]
        selectedFrame = previewFrame
        resetRefinement()
    }
    
    private func navigateToNextFrame() {
        guard currentFrameIndex < viewModel.extractedFrames.count - 1 else { return }
        currentFrameIndex += 1
        previewFrame = viewModel.extractedFrames[currentFrameIndex]
        selectedFrame = previewFrame
        resetRefinement()
    }
    
    // MARK: - Frame Refinement Functions
    
    private func refineBackwardCoarse() {
        refineByAmount(-0.5) // Back 0.5 seconds
    }
    
    private func refineBackwardFine() {
        refineByAmount(-0.033) // Back 1 frame (assuming ~30fps)
    }
    
    private func refineForwardFine() {
        refineByAmount(0.033) // Forward 1 frame (assuming ~30fps)
    }
    
    private func refineForwardCoarse() {
        refineByAmount(0.5) // Forward 0.5 seconds
    }
    
    private func refineByAmount(_ seconds: Double) {
        guard let frame = previewFrame,
              let videoURL = viewModel.selectedVideoURL else { return }
        
        let currentTimestamp = refinedTimestamp ?? frame.timestamp
        let newTimestamp = max(0, currentTimestamp + seconds)
        
        if newTimestamp != currentTimestamp {
            refineToTimestamp(newTimestamp, videoURL: videoURL)
        }
    }
    
    private func refineToTimestamp(_ timestamp: Double, videoURL: URL) {
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
    
}

struct FrameCard: View {
    let frame: Frame
    let isSelected: Bool
    let isHovered: Bool
    let onExport: () -> Void
    
    var body: some View {
        let _ = print("🎴 FrameCard.body: \(frame.formattedTimestamp) isHovered=\(isHovered) isSelected=\(isSelected)")
        return VStack {
            ZStack {
                Image(nsImage: frame.image)
                    .resizable()
                    .frame(width: 200, height: 112)
                    .cornerRadius(8)
                
                // Hover overlay with eye icon
                if isHovered {
                    let _ = print("🎯 HOVER OVERLAY showing for \(frame.formattedTimestamp)")
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.3))
                        .frame(width: 200, height: 112)
                        .overlay(
                            Image(systemName: "eye")
                                .font(.system(size: 24, weight: .light))
                                .foregroundColor(.white.opacity(0.9))
                        )
                }
            }
            
            Text(frame.formattedTimestamp)
            
            Button("Export") {
                onExport()
            }
            .foregroundColor(Color(red: 0.8, green: 0.561, blue: 0.173))
        }
    }
}

// MARK: - Keyboard Event Handling

struct KeyEventHandlingView: NSViewRepresentable {
    let onLeftArrow: () -> Void
    let onRightArrow: () -> Void
    let onEscape: () -> Void
    
    func makeNSView(context: Context) -> KeyCaptureView {
        let view = KeyCaptureView()
        view.onLeftArrow = onLeftArrow
        view.onRightArrow = onRightArrow
        view.onEscape = onEscape
        return view
    }
    
    func updateNSView(_ nsView: KeyCaptureView, context: Context) {
        nsView.onLeftArrow = onLeftArrow
        nsView.onRightArrow = onRightArrow
        nsView.onEscape = onEscape
    }
}

class KeyCaptureView: NSView {
    var onLeftArrow: (() -> Void)?
    var onRightArrow: (() -> Void)?
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
        print("🎹 Key pressed: \(event.keyCode)")
        
        switch event.keyCode {
        case 123: // Left arrow
            print("⬅️ Left arrow pressed")
            onLeftArrow?()
        case 124: // Right arrow
            print("➡️ Right arrow pressed") 
            onRightArrow?()
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