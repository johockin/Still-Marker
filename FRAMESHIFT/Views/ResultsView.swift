//
//  ResultsView.swift
//  Still Marker
//
//  Created by Claude Code on 2025-01-17.
//

import SwiftUI
import AppKit

struct ResultsView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var selectedFrame: Frame?
    @State private var hoveredFrame: Frame?
    
    private let columns = [
        GridItem(.adaptive(minimum: 200, maximum: 280), spacing: 16)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with controls
            headerView
            
            Divider()
                .padding(.vertical, 8)
            
            // Frames grid
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.extractedFrames) { frame in
                        FrameCard(
                            frame: frame,
                            isSelected: selectedFrame?.id == frame.id,
                            isHovered: hoveredFrame?.id == frame.id
                        )
                        .onTapGesture {
                            selectedFrame = frame
                            showFrameDetail(frame: frame)
                        }
                        .onHover { hovering in
                            hoveredFrame = hovering ? frame : nil
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .background(Color.clear)
        }
        .navigationTitle("Extracted Frames")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("New Video") {
                    viewModel.resetToUpload()
                }
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            // Frame count and video info
            VStack(alignment: .leading, spacing: 4) {
                Text("\(viewModel.extractedFrames.count) frames extracted")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                if let videoURL = viewModel.selectedVideoURL {
                    Text("from \(videoURL.lastPathComponent)")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
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
                    .foregroundColor(.primary)
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
    
    private func showFrameDetail(frame: Frame) {
        // TODO: M3 - Implement frame detail view
        print("Show frame detail for timestamp: \(frame.timestamp)")
    }
    
    private func exportAllFrames() {
        // TODO: M4 - Implement export functionality
        print("Export all frames")
    }
}

struct FrameCard: View {
    let frame: Frame
    let isSelected: Bool
    let isHovered: Bool
    
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
                
                Button(action: {
                    exportFrame(frame)
                }) {
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
    
    private func exportFrame(_ frame: Frame) {
        // TODO: M4 - Implement individual frame export
        print("Export frame at \(frame.timestamp)s")
    }
}

struct ResultsView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = AppViewModel()
        viewModel.state = .results
        
        return ResultsView(viewModel: viewModel)
            .frame(width: 800, height: 600)
    }
}