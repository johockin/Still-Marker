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
    
    // Toast notification state
    @State private var toastMessage: String = ""
    @State private var toastType: ToastType = .success
    @State private var showToast: Bool = false
    
    
    private let columns = [
        GridItem(.adaptive(minimum: 200, maximum: 280), spacing: 16)
    ]
    
    var body: some View {
        ZStack {
            // Background with cinematic dark aesthetic
            Color(red: 0.1, green: 0.1, blue: 0.11) // #1a1a1d lifted black
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
                        .frame(height: 80) // Bottom margin
                }
                .animation(.easeInOut(duration: 0.3), value: showToast)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationTitle("Extracted Frames")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("New Video") {
                    viewModel.resetToUpload()
                }
                .foregroundColor(.white)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
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
            
            Divider()
                .padding(.vertical, 8)
            
            // Frames grid
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(Array(viewModel.extractedFrames.enumerated()), id: \.element.id) { index, frame in
                        FrameCard(
                            frame: frame,
                            isSelected: selectedFrame?.id == frame.id,
                            isHovered: hoveredFrame?.id == frame.id,
                            onExport: { exportFrame(frame) }
                        )
                        .onTapGesture {
                            selectedFrame = frame
                            previewFrame = frame
                            currentFrameIndex = index
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewMode = .framePreview
                            }
                        }
                        .onHover { hovering in
                            hoveredFrame = hovering ? frame : nil
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
            // Frame count and video info - High contrast for dark edit suites
            VStack(alignment: .leading, spacing: 4) {
                Text("\(viewModel.extractedFrames.count) frames extracted")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.9)) // High contrast white text
                
                if let videoURL = viewModel.selectedVideoURL {
                    Text("from \(videoURL.lastPathComponent)")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white.opacity(0.7)) // Readable secondary text
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
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.9)) // High contrast for dark backgrounds
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Export all button
                Button(action: {
                    exportAllFrames()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 14))
                        Text("Export All")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.blue)
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
        
        // Generate filename with timestamp
        let timestampForFilename = frame.formattedTimestamp
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: ".", with: "-")
        savePanel.nameFieldStringValue = "frame_\(timestampForFilename)"
        
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
                // Generate filename with timestamp
                let timestampForFilename = frame.formattedTimestamp
                    .replacingOccurrences(of: ":", with: "-")
                    .replacingOccurrences(of: ".", with: "-")
                let filename = "frame_\(timestampForFilename).\(format.fileExtension)"
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
        VStack {
            // Back button
            HStack {
                Button("← Back to Grid") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewMode = .grid
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(.white)
                
                Spacer()
                
                Text("Frame Preview")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Export") {
                    exportFrame(frame)
                }
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(.blue)
            }
            .padding()
            
            // Frame display with navigation
            Spacer()
            
            HStack {
                // Previous frame button
                Button(action: navigateToPreviousFrame) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .padding()
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(currentFrameIndex <= 0)
                .opacity(currentFrameIndex <= 0 ? 0.3 : 1.0)
                
                Spacer()
                
                Image(nsImage: frame.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Spacer()
                
                // Next frame button
                Button(action: navigateToNextFrame) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .padding()
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(currentFrameIndex >= viewModel.extractedFrames.count - 1)
                .opacity(currentFrameIndex >= viewModel.extractedFrames.count - 1 ? 0.3 : 1.0)
            }
            
            Spacer()
            
            // Frame info with navigation
            VStack(spacing: 8) {
                Text("Frame at \(frame.formattedTimestamp)")
                    .foregroundColor(.white.opacity(0.7))
                
                Text("\(currentFrameIndex + 1) of \(viewModel.extractedFrames.count)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
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
    }
    
    private func navigateToNextFrame() {
        guard currentFrameIndex < viewModel.extractedFrames.count - 1 else { return }
        currentFrameIndex += 1
        previewFrame = viewModel.extractedFrames[currentFrameIndex]
        selectedFrame = previewFrame
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
        VStack(spacing: 0) {
            // Frame image
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.ultraThinMaterial)
                    .aspectRatio(16/9, contentMode: .fit)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                isSelected ? Color.accentColor : Color.primary.opacity(0.1),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
                
                // Real frame image from video
                Image(nsImage: frame.image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .cornerRadius(8)
                
                // Hover overlay
                if isHovered {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.1))
                        .overlay(
                            Image(systemName: "eye")
                                .font(.system(size: 24, weight: .light))
                                .foregroundColor(.white)
                        )
                }
            }
            
            // Frame info
            VStack(spacing: 4) {
                Text(frame.formattedTimestamp)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                Button(action: onExport) {
                    Text("Export")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.primary.opacity(0.05))
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.vertical, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(
                    color: Color.black.opacity(0.1),
                    radius: isHovered ? 8 : 4,
                    x: 0,
                    y: isHovered ? 4 : 2
                )
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
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