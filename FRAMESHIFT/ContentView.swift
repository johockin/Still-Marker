//
//  ContentView.swift
//  Still Marker
//
//  Created by Claude Code on 2025-01-17.
//

import SwiftUI

enum AppState {
    case upload
    case processing
    case results
}

class AppViewModel: ObservableObject {
    @Published var state: AppState = .upload
    @Published var selectedVideoURL: URL?
    @Published var extractedFrames: [Frame] = []
    @Published var currentOffset: Int = 0
    @Published var processingProgress: Double = 0.0
    @Published var processingMessage: String = ""
    
    private let ffmpegProcessor = FFmpegProcessor()
    
    func resetToUpload() {
        state = .upload
        selectedVideoURL = nil
        extractedFrames = []
        currentOffset = 0
        processingProgress = 0.0
        processingMessage = ""
    }
    
    func startProcessing(videoURL: URL) {
        selectedVideoURL = videoURL
        state = .processing
        processingProgress = 0.0
        processingMessage = "Starting extraction..."
        
        // Process video with FFmpeg
        Task {
            await processVideoWithFFmpeg(videoURL: videoURL)
        }
    }
    
    @MainActor
    private func processVideoWithFFmpeg(videoURL: URL) async {
        do {
            let frames = try await ffmpegProcessor.extractFrames(
                from: videoURL,
                offset: Double(currentOffset),
                interval: 3.0
            ) { progress, message in
                DispatchQueue.main.async {
                    self.processingProgress = progress
                    self.processingMessage = message
                }
            }
            
            // Update UI with extracted frames
            self.extractedFrames = frames
            
            // Brief pause to show completion
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            self.state = .results
            
        } catch {
            self.processingMessage = "Error: \(error.localizedDescription)"
            self.processingProgress = 0.0
            
            // Show error for 3 seconds, then return to upload
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.resetToUpload()
            }
        }
    }
    
    /// Re-extract frames with offset
    func shiftOffset() {
        guard let videoURL = selectedVideoURL else { return }
        
        currentOffset += 1
        state = .processing
        processingProgress = 0.0
        processingMessage = "Re-extracting with +\(currentOffset)s offset..."
        
        Task {
            await processVideoWithFFmpeg(videoURL: videoURL)
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()
    
    var body: some View {
        NavigationView {
            switch viewModel.state {
            case .upload, .processing:
                UploadProcessingView(viewModel: viewModel)
            case .results:
                ResultsView(viewModel: viewModel)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .background(Color.clear)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}