//
//  UploadProcessingView.swift
//  Still Marker
//
//  Created by Claude Code on 2025-01-17.
//

import SwiftUI
import AppKit

// MARK: - Eye View

struct EyeView: View {
    let isDragOver: Bool
    let progress: Double?

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let cx = w / 2
            let cy = h / 2

            // Eye outline
            var eyePath = Path()
            eyePath.move(to: CGPoint(x: w * 0.025, y: cy))
            eyePath.addQuadCurve(
                to: CGPoint(x: cx, y: h * 0.05),
                control: CGPoint(x: w * 0.25, y: h * 0.05)
            )
            eyePath.addQuadCurve(
                to: CGPoint(x: w * 0.975, y: cy),
                control: CGPoint(x: w * 0.75, y: h * 0.05)
            )
            eyePath.addQuadCurve(
                to: CGPoint(x: cx, y: h * 0.95),
                control: CGPoint(x: w * 0.75, y: h * 0.95)
            )
            eyePath.addQuadCurve(
                to: CGPoint(x: w * 0.025, y: cy),
                control: CGPoint(x: w * 0.25, y: h * 0.95)
            )
            context.stroke(
                eyePath,
                with: .color(.white.opacity(0.18)),
                lineWidth: 1.5
            )

            // Pupil
            let pupilRadius: CGFloat = isDragOver ? w * 0.15 : w * 0.1
            let pupilRect = CGRect(
                x: cx - pupilRadius,
                y: cy - pupilRadius,
                width: pupilRadius * 2,
                height: pupilRadius * 2
            )
            let pupilPath = Path(ellipseIn: pupilRect)
            context.fill(pupilPath, with: .color(.white.opacity(0.08)))
            context.stroke(pupilPath, with: .color(.white.opacity(0.22)), lineWidth: 1.5)

            // Catchlight
            let catchR: CGFloat = w * 0.025
            let catchPath = Path(ellipseIn: CGRect(
                x: cx - pupilRadius * 0.4 - catchR,
                y: cy - pupilRadius * 0.4 - catchR,
                width: catchR * 2,
                height: catchR * 2
            ))
            context.fill(catchPath, with: .color(.white.opacity(0.3)))
        }
        .frame(width: 160, height: 80)
        .animation(.easeOut(duration: 0.4), value: isDragOver)
    }
}

// MARK: - Gold Ring View

struct GoldRingView: View {
    let visible: Bool
    let progress: Double?

    @State private var trimEnd: CGFloat = 0

    var body: some View {
        Circle()
            .trim(from: 0, to: trimEnd)
            .stroke(Theme.gold, lineWidth: 1.5)
            .frame(width: 50, height: 50)
            .rotationEffect(.degrees(-90))
            .opacity(visible ? 1 : 0)
            .onChange(of: visible) { newValue in
                withAnimation(.easeOut(duration: 0.6)) {
                    trimEnd = newValue ? 1.0 : 0.0
                }
            }
            .onChange(of: progress) { newValue in
                if let p = newValue {
                    withAnimation(.easeOut(duration: 0.2)) {
                        trimEnd = CGFloat(p)
                    }
                }
            }
    }
}

// MARK: - Upload Processing View

struct UploadProcessingView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var isDragOver = false
    @State private var showingFilePicker = false
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            Theme.background
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
        Button(action: { showingFilePicker = true }) {
            VStack(spacing: 32) {
                Spacer()

                ZStack {
                    EyeView(isDragOver: isDragOver, progress: nil)

                    GoldRingView(visible: isDragOver, progress: nil)
                        .offset(y: 0)
                }

                Text("Show me what you saw")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Theme.textDim)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var processingView: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                EyeView(isDragOver: true, progress: viewModel.processingProgress)
                    .scaleEffect(pulseScale)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                            pulseScale = 1.08
                        }
                    }

                GoldRingView(visible: true, progress: viewModel.processingProgress)
            }

            VStack(spacing: 12) {
                Text(viewModel.processingMessage)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Theme.textDim)

                if let videoURL = viewModel.selectedVideoURL {
                    Text(videoURL.lastPathComponent)
                        .font(.caption)
                        .foregroundStyle(Theme.textGhost)
                }
            }

            Spacer()
        }
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
