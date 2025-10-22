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
                    gradient: Gradient(colors: [
                        Color(red: 0.12, green: 0.12, blue: 0.13), // Lifted black
                        Color(red: 0.1, green: 0.1, blue: 0.11) // Slightly deeper
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Warmer spotlight gradient - smaller, dimmer, moved left
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.32, green: 0.28, blue: 0.24).opacity(1.0),  // 20% dimmer warm cream center
                        Color(red: 0.24, green: 0.21, blue: 0.18).opacity(0.8),  // Dimmer mid tone
                        Color(red: 0.16, green: 0.14, blue: 0.13).opacity(0.5),  // Dimmer transition
                        Color.clear                                               // Fade out
                    ]),
                    center: UnitPoint(x: 0.3, y: 0.45),  // Moved 20% to the left (from 0.5 to 0.3)
                    startRadius: 60,   // Smaller radius
                    endRadius: 400     // Smaller coverage
                )
                .ignoresSafeArea()
                
                // Crimson spotlight in bottom right corner - 40% dimmer
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.8, green: 0.1, blue: 0.2).opacity(0.36),    // Crimson center
                        Color(red: 0.6, green: 0.08, blue: 0.15).opacity(0.24),  // Mid crimson
                        Color(red: 0.4, green: 0.05, blue: 0.1).opacity(0.12),   // Fading crimson
                        Color.clear                                               // Fade out
                    ]),
                    center: UnitPoint(x: 0.85, y: 0.85),  // Bottom right corner position
                    startRadius: 40,
                    endRadius: 350
                )
                .ignoresSafeArea()
                
                // Additional subtle glass morphism layer
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.02),
                        Color.clear,
                        Color.black.opacity(0.02)
                    ]),
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
    
    private func loadFramesProgressively() {
        let batchSize = 8  // Load 8 frames at a time
        let totalFrames = viewModel.extractedFrames.count
        
        // Start with first batch
        visibleFrameCount = min(batchSize, totalFrames)
        
        // Continue loading in batches if there are more frames
        guard totalFrames > batchSize else { return }
        
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            DispatchQueue.main.async {
                self.visibleFrameCount = min(self.visibleFrameCount + batchSize, totalFrames)
                if self.visibleFrameCount >= totalFrames {
                    timer.invalidate()
                }
            }
        }
    }
    
    private func exportFrame(_ frame: Frame) {
        let savePanel = NSSavePanel()
        savePanel.title = "Export Frame"
        savePanel.showsResizeIndicator = true
        savePanel.showsHiddenFiles = false
        savePanel.canCreateDirectories = true
        // Allow all content types so format selection works properly
        savePanel.allowedContentTypes = []
        
        // Generate enhanced filename with video name prefix AND extension
        savePanel.nameFieldStringValue = "\(generateFilename(for: frame)).\(selectedExportFormat.fileExtension)"
        
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
            // Compact header - minimal structure
            HStack {
                // Back to Grid button - simplified styling
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        resetRefinement()
                        viewMode = .grid
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .medium))
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
                
                // Title text aligned to the right
                HStack {
                    Spacer()
                    Text("Frame \(currentFrameIndex + 1) of \(viewModel.extractedFrames.count)")
                        .font(.system(size: 12, weight: .light, design: .monospaced))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .padding(.leading, 60)  // Move button more to the right
            .padding(.trailing, 60) // Split the difference - halfway between 40 and 80
            .padding(.top, 16)      // Reduced top padding
            .padding(.bottom, 32)   // Keep bottom padding
            
            // Frame display with navigation
            Spacer()
            
            HStack(spacing: 0) {
                // Outer spacer (lower priority - less space)
                Spacer()
                    .frame(maxWidth: .infinity)
                    .layoutPriority(1)
                
                // Previous frame button
                Button(action: navigateToPreviousFrame) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .medium))  // Half the size
                        .foregroundColor(.white.opacity(0.7))
                        .padding()
                        .background(.thinMaterial)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(currentFrameIndex <= 0)
                .opacity(currentFrameIndex <= 0 ? 0.3 : 1.0)
                
                // Inner spacer (higher priority - more space, moves button closer to center)
                Spacer()
                    .frame(maxWidth: .infinity)
                    .layoutPriority(2)
                
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
                .layoutPriority(3)  // Highest priority - ensure image gets space
                
                // Inner spacer (higher priority - more space, moves button closer to center)
                Spacer()
                    .frame(maxWidth: .infinity)
                    .layoutPriority(2)
                
                // Next frame button
                Button(action: navigateToNextFrame) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))  // Half the size
                        .foregroundColor(.white.opacity(0.7))
                        .padding()
                        .background(.thinMaterial)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(currentFrameIndex >= viewModel.extractedFrames.count - 1)
                .opacity(currentFrameIndex >= viewModel.extractedFrames.count - 1 ? 0.3 : 1.0)
                
                // Outer spacer (lower priority - less space)
                Spacer()
                    .frame(maxWidth: .infinity)
                    .layoutPriority(1)
            }
            
            // Frame refinement and export controls
            VStack(spacing: 16) {
                // Refinement controls: <<<< <<< << < timecode > >> >>> >>>>
                HStack(spacing: 8) {
                    // <<<< 10s backward
                    Button(action: refineBackward10s) {
                        Text("10s")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(.thinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.white.opacity(0.4), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isRefining || displayTimestamp <= 0)
                    .opacity(isRefining || displayTimestamp <= 0 ? 0.5 : 1.0)
                    
                    // <<< 2s backward
                    Button(action: refineBackward2s) {
                        Text("2s")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(.thinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.white.opacity(0.35), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isRefining || displayTimestamp <= 0)
                    .opacity(isRefining || displayTimestamp <= 0 ? 0.5 : 1.0)
                    
                    // << 0.5s backward
                    Button(action: refineBackwardCoarse) {
                        Image(systemName: "chevron.left.2")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(.thinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isRefining || displayTimestamp <= 0)
                    .opacity(isRefining || displayTimestamp <= 0 ? 0.5 : 1.0)
                    
                    // < 1 frame backward
                    Button(action: refineBackwardFine) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(.thinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
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
                    
                    // > 1 frame forward
                    Button(action: refineForwardFine) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(.thinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isRefining)
                    .opacity(isRefining ? 0.5 : 1.0)
                    
                    // >> 0.5s forward
                    Button(action: refineForwardCoarse) {
                        Image(systemName: "chevron.right.2")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(.thinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isRefining)
                    .opacity(isRefining ? 0.5 : 1.0)
                    
                    // >>> 2s forward
                    Button(action: refineForward2s) {
                        Text("2s")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(.thinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.white.opacity(0.35), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isRefining)
                    .opacity(isRefining ? 0.5 : 1.0)
                    
                    // >>>> 10s forward
                    Button(action: refineForward10s) {
                        Text("10s")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(.thinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.white.opacity(0.4), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isRefining)
                    .opacity(isRefining ? 0.5 : 1.0)
                }
                
                // Export button with Kodak Gold hover
                Button("Export This Frame") {
                    exportFrame(displayFrame)
                }
                .buttonStyle(FilmExportButtonStyle(isHovered: hoveredFramePreviewExportButton && !isRefining))
                .onHover { hovering in
                    hoveredFramePreviewExportButton = hovering
                }
                .disabled(isRefining)
                .opacity(isRefining ? 0.5 : 1.0)
            }
            .padding(.vertical, 16)
            
            Spacer()
            
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
    
    private func refineBackward10s() {
        refineByAmount(-10.0) // Back 10 seconds
    }
    
    private func refineBackward2s() {
        refineByAmount(-2.0) // Back 2 seconds
    }
    
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
    
    private func refineForward2s() {
        refineByAmount(2.0) // Forward 2 seconds
    }
    
    private func refineForward10s() {
        refineByAmount(10.0) // Forward 10 seconds
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
    
    // NO @State variables at all!
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Image(nsImage: frame.thumbnail)
                    .resizable()
                    .frame(width: 200, height: 112)
                    .cornerRadius(8)
                
                // Hover overlay (no animation for Step 1)
                if isHovered {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.4))
                        .overlay(
                            Image(systemName: "eye.fill")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                        )
                }
                
                // Selection border
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(hex: "#E6A532"), lineWidth: 3)
                }
            }
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