//
//  UploadProcessingView.swift
//  Still Marker
//
//  Created by Claude Code on 2025-01-17.
//

import SwiftUI
import AppKit

struct UploadProcessingView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var isDragOver = false
    @State private var showingFilePicker = false
    
    var body: some View {
        ZStack {
            // Background with subtle gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.02),
                    Color.black.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if viewModel.state == .upload {
                uploadView
            } else {
                processingView
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.state)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.movie, .video],
            onCompletion: handleFileSelection
        )
    }
    
    private var uploadView: some View {
        VStack(spacing: 40) {
            // App Title
            VStack(spacing: 16) {
                Text("STILL MARKER")
                    .font(.system(size: 48, weight: .ultraLight, design: .default))
                    .foregroundColor(.primary)
                    .kerning(4)
                
                Text("Extract high-quality stills from video")
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 60)
            
            // Drop Zone - The Star of the Show
            VStack(spacing: 24) {
                dropZone
                
                // Or divider
                HStack {
                    Rectangle()
                        .fill(Color.primary.opacity(0.1))
                        .frame(height: 1)
                    
                    Text("or")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                    
                    Rectangle()
                        .fill(Color.primary.opacity(0.1))
                        .frame(height: 1)
                }
                .padding(.horizontal, 60)
                
                // Browse Button
                Button(action: { showingFilePicker = true }) {
                    Text("Browse for video file")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.primary.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        // Hover effect handled by SwiftUI
                    }
                }
            }
            
            Spacer()
            
            // Privacy Notice
            HStack(spacing: 8) {
                Image(systemName: "lock.shield")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14))
                
                Text("Your videos are processed locally and never leave your Mac")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 80)
    }
    
    private var dropZone: some View {
        ZStack {
            // Frosted glass background using macOS materials
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isDragOver ? Color.accentColor : Color.primary.opacity(0.1),
                            lineWidth: isDragOver ? 2 : 1
                        )
                )
                .shadow(
                    color: Color.black.opacity(0.1),
                    radius: isDragOver ? 20 : 10,
                    x: 0,
                    y: isDragOver ? 10 : 5
                )
            
            // Content
            VStack(spacing: 24) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "film")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(.accentColor)
                }
                .scaleEffect(isDragOver ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragOver)
                
                // Text
                VStack(spacing: 8) {
                    Text(isDragOver ? "Drop your video here" : "Drag video file here")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text("Up to 10GB+ supported • All formats")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 60)
            .scaleEffect(isDragOver ? 1.02 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isDragOver)
        }
        .frame(maxWidth: 480, maxHeight: 280)
        .onDrop(of: [.fileURL], isTargeted: $isDragOver) { providers in
            handleDrop(providers: providers)
        }
    }
    
    private var processingView: some View {
        VStack(spacing: 40) {
            // Processing Icon
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
                
                Image(systemName: "gearshape.2")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(.accentColor)
                    .rotationEffect(.degrees(viewModel.processingProgress * 360))
                    .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: viewModel.processingProgress)
            }
            
            // Progress
            VStack(spacing: 16) {
                Text(viewModel.processingMessage)
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(.primary)
                
                ProgressView(value: viewModel.processingProgress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(maxWidth: 400)
                    .accentColor(.accentColor)
            }
            
            // File Info
            if let videoURL = viewModel.selectedVideoURL {
                VStack(spacing: 8) {
                    Text("Processing: \(videoURL.lastPathComponent)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text("Extracting frames at 3-second intervals")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
            }
        }
        .padding(.horizontal, 80)
    }
    
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
    
    private func handleFileSelection(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            processVideoFile(url: url)
        case .failure(let error):
            print("File selection failed: \(error)")
        }
    }
    
    private func processVideoFile(url: URL) {
        // Basic validation
        let allowedExtensions = ["mp4", "mov", "avi", "mkv", "m4v", "wmv", "flv", "webm"]
        let fileExtension = url.pathExtension.lowercased()
        
        guard allowedExtensions.contains(fileExtension) else {
            // TODO: Show error alert
            print("Unsupported file type")
            return
        }
        
        viewModel.startProcessing(videoURL: url)
    }
}

struct UploadProcessingView_Previews: PreviewProvider {
    static var previews: some View {
        UploadProcessingView(viewModel: AppViewModel())
            .frame(width: 800, height: 600)
    }
}