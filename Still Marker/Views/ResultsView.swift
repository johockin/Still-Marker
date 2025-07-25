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
    case frameRefinement
}

enum PreviewScaleMode {
    case fit
    case actual
}

enum ExportFormat: String, CaseIterable {
    case jpeg = "JPEG"
    case png = "PNG" 
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

struct ResultsView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var selectedFrame: Frame?
    @State private var hoveredFrame: Frame?
    @State private var viewMode: ViewMode = .grid
    @State private var previewFrame: Frame?
    @State private var previewScaleMode: PreviewScaleMode = .fit
    @State private var selectedExportFormat: ExportFormat = .jpeg
    @State private var currentFrameIndex: Int = 0
    
    // Frame Refinement properties
    @State private var refinementFrames: [Int: Frame] = [:]
    @State private var refinementBaseFrame: Frame?
    @State private var selectedRefinementFrame: Frame?
    @State private var isLoadingRefinement = false
    
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
            case .frameRefinement:
                if let baseFrame = refinementBaseFrame {
                    frameRefinementView(baseFrame: baseFrame)
                }
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
                        Image(systemName: "arrow.clockwise")
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
    
    private func exportFrame(_ frame: Frame) {
        // Placeholder
    }
    
    private func exportAllFrames() {
        // Placeholder
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
                
                Button("Refine") {
                    startFrameRefinement(frame)
                }
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(.blue)
            }
            .padding()
            
            // Frame display
            Spacer()
            
            Image(nsImage: frame.image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Spacer()
            
            // Frame info
            Text("Frame at \(frame.formattedTimestamp)")
                .foregroundColor(.white.opacity(0.7))
                .padding()
        }
    }
    
    private func startFrameRefinement(_ frame: Frame) {
        refinementBaseFrame = frame
        selectedRefinementFrame = frame
        
        // For now, just create a simple static set of frames around the base
        refinementFrames = [0: frame] // Center frame
        
        withAnimation(.easeInOut(duration: 0.3)) {
            viewMode = .frameRefinement
        }
    }
    
    private func frameRefinementView(baseFrame: Frame) -> some View {
        VStack {
            // Header
            HStack {
                Button("← Back") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewMode = .framePreview
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(.white)
                
                Spacer()
                
                Text("Frame Refinement - \(baseFrame.formattedTimestamp)")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Select") {
                    if let selected = selectedRefinementFrame {
                        // Replace the frame and go back
                        previewFrame = selected
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewMode = .framePreview
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(.green)
            }
            .padding()
            
            Spacer()
            
            // Main viewer - show selected frame
            if let selectedFrame = selectedRefinementFrame {
                Image(nsImage: selectedFrame.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            Spacer()
            
            // Simple timeline strip - just show available frames
            HStack(spacing: 8) {
                ForEach(refinementFrames.keys.sorted(), id: \.self) { index in
                    if let frame = refinementFrames[index] {
                        Button(action: {
                            selectedRefinementFrame = frame
                        }) {
                            Rectangle()
                                .fill(selectedRefinementFrame?.id == frame.id ? Color.blue : Color.gray)
                                .frame(width: 60, height: 34)
                                .overlay(
                                    Text("\(index)")
                                        .foregroundColor(.white)
                                        .font(.caption)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding()
        }
        .background(Color(red: 0.1, green: 0.1, blue: 0.11))
    }
}

struct FrameCard: View {
    let frame: Frame
    let isSelected: Bool
    let isHovered: Bool
    let onExport: () -> Void
    
    var body: some View {
        Rectangle()
            .fill(Color.gray)
            .frame(width: 200, height: 112)
            .overlay(
                Text("Frame")
                    .foregroundColor(.white)
            )
    }
}