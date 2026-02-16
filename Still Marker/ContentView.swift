//
//  ContentView.swift
//  Still Marker
//
//  Created by Claude Code on 2025-01-17.
//

import SwiftUI
import AVFoundation

enum AppState {
    case upload
    case processing
    case results
}

class AppViewModel: ObservableObject {
    @Published var state: AppState = .upload
    @Published var selectedVideoURL: URL?
    @Published var extractedFrames: [Frame] = []
    @Published var videoDuration: Double = 0.0
    @Published var extractionInterval: Double = 0.0
    @Published var processingProgress: Double = 0.0
    @Published var processingMessage: String = ""
    
    private let processor = AVFoundationProcessor()
    
    func resetToUpload() {
        state = .upload
        selectedVideoURL = nil
        extractedFrames = []
        videoDuration = 0.0
        extractionInterval = 0.0
        processingProgress = 0.0
        processingMessage = ""
    }
    
    func startProcessing(videoURL: URL) {
        selectedVideoURL = videoURL
        state = .processing
        processingProgress = 0.0
        processingMessage = "Starting extraction..."
        
        Task {
            await processVideo(videoURL: videoURL)
        }
    }

    @MainActor
    private func processVideo(videoURL: URL) async {
        do {
            // Get video duration for UI boundary indicators
            let asset = AVAsset(url: videoURL)
            let duration = try await asset.load(.duration)
            self.videoDuration = CMTimeGetSeconds(duration)

            // Store the extraction interval for display in the header
            self.extractionInterval = processor.calculateAdaptiveInterval(duration: self.videoDuration)

            let frames = try await processor.extractFrames(
                from: videoURL
            ) { progress, message in
                DispatchQueue.main.async {
                    self.processingProgress = progress
                    self.processingMessage = message
                }
            }
            
            // Update UI with extracted frames
            print("🔄 Setting extractedFrames with \(frames.count) frames")
            self.extractedFrames = frames
            
            // Brief pause to show completion
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            print("📱 Transitioning to .results state")
            self.state = .results
            print("✅ State transition complete")
            
        } catch {
            self.processingMessage = "Error: \(error.localizedDescription)"
            self.processingProgress = 0.0
            
            // Show error for 3 seconds, then return to upload
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.resetToUpload()
            }
        }
    }
    
}

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()
    
    var body: some View {
        switch viewModel.state {
        case .upload, .processing:
            UploadProcessingView(viewModel: viewModel)
        case .results:
            ResultsView(viewModel: viewModel)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}