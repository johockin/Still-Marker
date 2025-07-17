//
//  ContentView.swift
//  FRAMESHIFT
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
        
        // TODO: M2 - Integrate FFmpeg processing
        // For now, simulate processing
        simulateProcessing()
    }
    
    private func simulateProcessing() {
        // Simulate processing for M1 - replace with real FFmpeg in M2
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.processingProgress = 0.5
            self.processingMessage = "Extracting frames..."
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.processingProgress = 1.0
                self.processingMessage = "Complete!"
                
                // Create sample frames for M1
                self.createSampleFrames()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.state = .results
                }
            }
        }
    }
    
    private func createSampleFrames() {
        // Create sample frames for M1 skeleton
        let sampleImage = NSImage(size: NSSize(width: 320, height: 180))
        sampleImage.lockFocus()
        NSColor.systemBlue.set()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: 320, height: 180)).fill()
        sampleImage.unlockFocus()
        
        extractedFrames = [
            Frame(timestamp: 0.0, image: sampleImage),
            Frame(timestamp: 3.0, image: sampleImage),
            Frame(timestamp: 6.0, image: sampleImage),
            Frame(timestamp: 9.0, image: sampleImage),
            Frame(timestamp: 12.0, image: sampleImage),
            Frame(timestamp: 15.0, image: sampleImage)
        ]
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