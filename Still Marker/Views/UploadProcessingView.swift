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
            // Background with spotlight gradient and texture
            ZStack {
                // Base dark background - lifted blacks
                Color(red: 0.1, green: 0.1, blue: 0.11)
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
                
                // Crimson spotlight in bottom right corner
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.8, green: 0.1, blue: 0.2).opacity(0.6),     // Crimson center
                        Color(red: 0.6, green: 0.08, blue: 0.15).opacity(0.4),   // Mid crimson
                        Color(red: 0.4, green: 0.05, blue: 0.1).opacity(0.2),    // Fading crimson
                        Color.clear                                               // Fade out
                    ]),
                    center: UnitPoint(x: 0.85, y: 0.85),  // Bottom right corner position
                    startRadius: 40,
                    endRadius: 350
                )
                .ignoresSafeArea()
                
            }
            
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
                
                Text("Extract moments from time")
                    .font(.system(size: 16, weight: .light, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6)) // More prominent but still subtle
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
                // Enhanced glass morphism with multiple layers
                ZStack {
                    // Base glass panel - more visible
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.thinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.white.opacity(0.1))
                        )
                    
                    // Inner glass highlight - more prominent
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.25),
                                    Color.white.opacity(0.1),
                                    Color.clear
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Border with enhanced glow - more visible
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    isDragOver ? Color.white.opacity(0.8) : Color.white.opacity(0.4),
                                    isDragOver ? Color.white.opacity(0.5) : Color.white.opacity(0.2)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isDragOver ? 3 : 2
                        )
                }
                .shadow(
                    color: Color.black.opacity(0.3),
                    radius: isDragOver ? 30 : 20,
                    x: 0,
                    y: isDragOver ? 15 : 10
                )
                .shadow(
                    color: Color.white.opacity(isDragOver ? 0.1 : 0.05),
                    radius: isDragOver ? 5 : 3,
                    x: 0,
                    y: isDragOver ? -2 : -1
                )
                
                // Content
                VStack(spacing: 24) {
                    // Enhanced icon with glass effect
                    ZStack {
                        // Outer glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.1),
                                        Color.clear
                                    ]),
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 50
                                )
                            )
                            .frame(width: 100, height: 100)
                        
                        // Glass circle - more visible
                        Circle()
                            .fill(.thinMaterial)
                            .overlay(
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                            )
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.white.opacity(0.3),
                                                Color.white.opacity(0.1)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "film")
                            .font(.system(size: 32, weight: .ultraLight))
                            .foregroundColor(.white.opacity(0.8))
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
                // Enhanced processing icon with glass morphism
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.08),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                    
                    // Glass circle - more visible
                    Circle()
                        .fill(.thinMaterial)
                        .overlay(
                            Circle()
                                .fill(Color.white.opacity(0.08))
                        )
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.2),
                                            Color.white.opacity(0.05)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .frame(width: 120, height: 120)
                }
                
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