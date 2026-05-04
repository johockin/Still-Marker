//
//  UploadProcessingView.swift
//  Still Marker
//
//  Created by Claude Code on 2025-01-17.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Eye View

struct EyeView: View {
    let isDragOver: Bool
    let progress: Double?

    @Environment(\.colorScheme) private var colorScheme

    private var strokeBase: Color {
        colorScheme == .dark ? .white : .black
    }

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
                with: .color(strokeBase.opacity(0.18)),
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
            context.fill(pupilPath, with: .color(strokeBase.opacity(0.08)))
            context.stroke(pupilPath, with: .color(strokeBase.opacity(0.22)), lineWidth: 1.5)

            // Catchlight
            let catchR: CGFloat = w * 0.025
            let catchPath = Path(ellipseIn: CGRect(
                x: cx - pupilRadius * 0.4 - catchR,
                y: cy - pupilRadius * 0.4 - catchR,
                width: catchR * 2,
                height: catchR * 2
            ))
            context.fill(catchPath, with: .color(strokeBase.opacity(0.3)))
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
            allowedContentTypes: Self.pickerContentTypes,
            onCompletion: handleFileSelection
        )
    }

    /// File-picker UTType list. `.audiovisualContent` covers AVFoundation-native types;
    /// the explicit extensions add formats Apple doesn't have a registered UTI for
    /// (MKV, MXF, WebM, etc.) so they're not greyed out in the picker.
    private static let pickerContentTypes: [UTType] = {
        var types: [UTType] = [.audiovisualContent, .movie, .video]
        let extraExtensions = [
            "mkv", "webm", "mxf", "mts", "m2ts",
            "ts", "vob", "ogv", "ogg", "asf", "flv", "wmv", "avi",
            "mpg", "mpeg", "3gp", "3g2"
        ]
        for ext in extraExtensions {
            if let t = UTType(filenameExtension: ext) {
                types.append(t)
            }
        }
        return types
    }()

    private var uploadView: some View {
        Button(action: { showingFilePicker = true }) {
            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    EyeView(isDragOver: isDragOver, progress: nil)

                    GoldRingView(visible: isDragOver, progress: nil)
                        .offset(y: 0)
                }

                Spacer()
                    .frame(height: 32)

                Text("Show me what you saw")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(Theme.text)

                Spacer()
                    .frame(height: 10)

                Text("Pull beautiful stills from any video.")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textSecondary)

                Spacer()
                    .frame(height: 20)

                Text("Drop a video or click to browse")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textDim)

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: "lock.shield")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textDim)
                    Text("All processing happens locally — nothing leaves your Mac")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textDim)
                }
                .padding(.bottom, 24)
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
            // SwiftUI's fileImporter returns a security-scoped URL (it does this even for
            // non-sandboxed apps for sandbox-compatibility). In-process AVFoundation handles
            // this transparently, but spawned processes (FFmpeg) can't inherit the scope.
            // We claim the scope here and intentionally never release it for the lifetime
            // of the session — small leak, cleared on app quit.
            _ = url.startAccessingSecurityScopedResource()
            processVideoFile(url: url)
        case .failure(let error):
            print("File selection failed: \(error)")
        }
    }

    private func processVideoFile(url: URL) {
        // VideoProcessor handles AVFoundation (mov/mp4/m4v native) + FFmpeg fallback for the rest.
        // Camera RAW formats (r3d/ari/braw/crm) need vendor SDKs; we don't pretend to support them.
        let supportedExtensions: Set<String> = [
            "mp4", "mov", "m4v",                 // AVFoundation native
            "mkv", "webm",                        // Matroska (FFmpeg)
            "avi", "wmv", "flv", "asf",          // older containers (FFmpeg)
            "mts", "m2ts",                        // AVCHD (FFmpeg/AVFoundation)
            "mxf",                                // broadcast (FFmpeg)
            "ts", "mpg", "mpeg", "vob",          // MPEG-TS / DVD (FFmpeg)
            "ogv", "ogg",                         // Theora (FFmpeg)
            "3gp", "3g2"                          // mobile (FFmpeg/AVFoundation)
        ]
        let fileExtension = url.pathExtension.lowercased()

        guard supportedExtensions.contains(fileExtension) else {
            print("Unsupported file type: .\(fileExtension)")
            // TODO: surface a toast here once the upload screen has a toast surface
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
