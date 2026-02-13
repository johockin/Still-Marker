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
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()

            if viewModel.state == .upload {
                uploadView
            } else {
                processingView
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $isDragOver) { providers in
            handleDrop(providers: providers)
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.state)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.movie, .video],
            onCompletion: handleFileSelection
        )
    }

    private var uploadView: some View {
        VStack(spacing: 0) {
            Spacer()

            // App Title
            VStack(spacing: 12) {
                Text("Still Marker")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(.primary)

                Text("Extract moments from time")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
                .frame(height: 48)

            // Drop Zone — hero action
            dropZone

            Spacer()

            // Privacy Notice
            HStack(spacing: 8) {
                Image(systemName: "lock.shield")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Text("Videos are processed locally and never leave your Mac")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 60)
    }

    private var dropZone: some View {
        Button(action: { showingFilePicker = true }) {
            VStack(spacing: 20) {
                Image(systemName: "film")
                    .font(.system(size: 36, weight: .ultraLight))
                    .foregroundStyle(isDragOver ? .primary : .secondary)
                    .scaleEffect(isDragOver ? 1.08 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragOver)

                VStack(spacing: 6) {
                    Text(isDragOver ? "Drop your video here" : "Drag or click to select video")
                        .font(.body)
                        .foregroundStyle(.primary)

                    Text("All formats supported")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: 480)
            .padding(.vertical, 52)
            .padding(.horizontal, 40)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(isDragOver ? 0.08 : 0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        Color.white.opacity(isDragOver ? 0.2 : 0.08),
                        lineWidth: 1
                    )
            )
            .animation(.easeInOut(duration: 0.15), value: isDragOver)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var processingView: some View {
        VStack(spacing: 32) {
            Spacer()

            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)

            VStack(spacing: 12) {
                Text(viewModel.processingMessage)
                    .font(.title3)
                    .foregroundStyle(.primary)

                ProgressView(value: viewModel.processingProgress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(maxWidth: 360)
                    .tint(.accentColor)
            }

            if let videoURL = viewModel.selectedVideoURL {
                Text(videoURL.lastPathComponent)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 8)
            }

            Spacer()
        }
        .padding(.horizontal, 60)
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
        let allowedExtensions = ["mp4", "mov", "avi", "mkv", "m4v", "wmv", "flv", "webm"]
        let fileExtension = url.pathExtension.lowercased()

        guard allowedExtensions.contains(fileExtension) else {
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
