//
//  FrameCardView.swift
//  Still Marker
//
//  Extracted from ResultsView.swift for maintainability.
//

import SwiftUI

struct FrameCard: View {
    let frame: Frame
    let isSelected: Bool
    let isHovered: Bool
    let isPicked: Bool
    let onTap: () -> Void
    let onDoubleTap: () -> Void
    let onHover: (Bool) -> Void

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.black

            Image(nsImage: frame.thumbnail)
                .resizable()
                .aspectRatio(contentMode: .fit)

            // Hover or selected: gold border
            if isHovered || isSelected {
                RoundedRectangle(cornerRadius: 1)
                    .strokeBorder(
                        Theme.gold,
                        lineWidth: 1.5
                    )
            }

            // Picked indicator: gold dot top-left
            if isPicked {
                VStack {
                    HStack {
                        Circle()
                            .fill(Theme.gold)
                            .frame(width: 8, height: 8)
                            .padding(5)
                        Spacer()
                    }
                    Spacer()
                }
                // Subtle gold border when picked (even when not hovered)
                if !isHovered && !isSelected {
                    RoundedRectangle(cornerRadius: 1)
                        .strokeBorder(
                            Theme.gold.opacity(0.4),
                            lineWidth: 1
                        )
                }
            }

            // Timecode: overlay, bottom-right, visible on hover
            Text(frame.formattedTimestamp)
                .font(.system(size: 10, design: .monospaced).monospacedDigit())
                .foregroundStyle(Color.white.opacity(0.7))
                .shadow(color: .black.opacity(0.8), radius: 3, x: 0, y: 1)
                .padding(6)
                .opacity(isHovered ? 1 : 0)
        }
        .aspectRatio(16.0/9.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 1))
        .scaleEffect(isHovered ? 1.8 : 1.0)
        .zIndex(isHovered ? 100 : 0)
        .animation(.easeOut(duration: 0.12), value: isHovered)
        .onTapGesture(count: 2) { onDoubleTap() }
        .onTapGesture { onTap() }
        .onHover { hovering in
            onHover(hovering)
        }
    }
}
