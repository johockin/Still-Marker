//
//  FramePreviewComponents.swift
//  Still Marker
//
//  Preview header and frame navigation.
//

import SwiftUI

// MARK: - Frame Preview Header Component

struct FramePreviewHeader: View {
    let currentFrameIndex: Int
    let totalFrames: Int
    let onBack: () -> Void
    let onExportAll: () -> Void

    @State private var backHovered = false
    @State private var exportHovered = false

    var body: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 10, weight: .medium))
                    Text("grid")
                        .font(.system(size: 13))
                }
                .foregroundStyle(backHovered ? Theme.text : Theme.textSecondary)
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { backHovered = $0 }

            Spacer()

            Text("\(currentFrameIndex + 1) of \(totalFrames)")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textDim)

            Spacer()

            Button(action: onExportAll) {
                Text("export all")
                    .font(.system(size: 13))
                    .foregroundStyle(exportHovered ? Theme.gold : Theme.goldDim)
                    .underline(exportHovered)
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { exportHovered = $0 }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .frame(height: 44)
    }
}

// MARK: - Frame Navigation View Component

struct FrameNavigationView: View {
    let frame: Frame
    let isRefining: Bool
    let currentFrameIndex: Int
    let totalFrames: Int
    let onPrevious: () -> Void
    let onNext: () -> Void

    @State private var prevHovered = false
    @State private var nextHovered = false

    private var prevButtonOpacity: Double {
        currentFrameIndex <= 0 ? 0.15 : (prevHovered ? 0.6 : 0.3)
    }

    private var nextButtonOpacity: Double {
        currentFrameIndex >= totalFrames - 1 ? 0.15 : (nextHovered ? 0.6 : 0.3)
    }

    var body: some View {
        HStack(spacing: 0) {
            Spacer()
                .frame(maxWidth: .infinity)
                .layoutPriority(1)

            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .padding()
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(currentFrameIndex <= 0)
            .opacity(prevButtonOpacity)
            .onHover { prevHovered = $0 }

            Spacer()
                .frame(maxWidth: .infinity)
                .layoutPriority(2)

            ZStack {
                Image(nsImage: frame.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .layoutPriority(3)

            Spacer()
                .frame(maxWidth: .infinity)
                .layoutPriority(2)

            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .padding()
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(currentFrameIndex >= totalFrames - 1)
            .opacity(nextButtonOpacity)
            .onHover { nextHovered = $0 }

            Spacer()
                .frame(maxWidth: .infinity)
                .layoutPriority(1)
        }
    }
}
