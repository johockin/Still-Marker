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
            // Background with cinematic dark mode - permanent lifted blacks
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.11), // #1a1a1d lifted black
                    Color(red: 0.08, green: 0.08, blue: 0.09) // Deeper black for depth
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
            // App Title - Architectural Element (Chris Marker inspired)
            VStack(spacing: 24) {
                // Vertical stacking exploration: S T I L L / M A R K E R
                VStack(spacing: 4) {
                    Text("S T I L L")
                        .font(.system(size: 48, weight: .ultraLight, design: .monospaced))
                        .foregroundColor(.white.opacity(0.9)) // High contrast white for dark mode
                        .kerning(16) // Extreme letter spacing
                        .tracking(8)
                    
                    Text("M A R K E R")
                        .font(.system(size: 48, weight: .ultraLight, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7)) // Hierarchy through opacity
                        .kerning(16)
                        .tracking(8)
                }
                
                Text("A tool for filmmakers")
                    .font(.system(size: 16, weight: .light, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5)) // Documentary typewriter aesthetic
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
            .padding(.top, 80)
            
            // Drop Zone - The Star of the Show
            dropZone
            
            Spacer()
            
            // Privacy Notice - Dark mode styling
            HStack(spacing: 10) {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(.white.opacity(0.5))
                    .font(.system(size: 16, weight: .medium))
                
                Text("Your videos are processed locally and never leave your Mac")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.bottom, 60)
        }
        .padding(.horizontal, 80)
    }
    
    private var dropZone: some View {
        Button(action: { showingFilePicker = true }) {
            ZStack {
                // Glass morphism done right - high-end camera filter aesthetic
                RoundedRectangle(cornerRadius: 20)
                    .fill(.thinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                isDragOver ? Color.white.opacity(0.4) : Color.white.opacity(0.1),
                                lineWidth: isDragOver ? 2 : 1
                            )
                    )
                    .shadow(
                        color: Color.black.opacity(0.4),
                        radius: isDragOver ? 25 : 15,
                        x: 0,
                        y: isDragOver ? 12 : 8
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
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .scaleEffect(isDragOver ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragOver)
                    
                    // Text
                    VStack(spacing: 8) {
                        Text(isDragOver ? "Drop your video here" : "Drag or click to select video")
                            .font(.system(size: 20, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text("Up to 10GB+ supported • All formats")
                            .font(.system(size: 14, weight: .regular, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding(.vertical, 60)
                .scaleEffect(isDragOver ? 1.02 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isDragOver)
            }
        }
        .buttonStyle(PlainButtonStyle())
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
                    .foregroundColor(.white.opacity(0.7))
                    .rotationEffect(.degrees(viewModel.processingProgress * 360))
                    .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: viewModel.processingProgress)
            }
            
            // Progress
            VStack(spacing: 16) {
                Text(viewModel.processingMessage)
                    .font(.system(size: 24, weight: .light, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
                
                ProgressView(value: viewModel.processingProgress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(maxWidth: 400)
                    .accentColor(.accentColor)
            }
            
            // File Info
            if let videoURL = viewModel.selectedVideoURL {
                VStack(spacing: 8) {
                    Text("Processing: \(videoURL.lastPathComponent)")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("Intelligently selecting optimal frames")
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
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