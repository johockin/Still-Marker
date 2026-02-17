//
//  FrameCardView.swift
//  Still Marker
//
//  Grid card with hover magnification and pick indicator.
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
            // Dark pillarbox container — handles any aspect ratio
            Theme.background

            Image(nsImage: frame.thumbnail)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Hover or selected: gold border
            if isHovered || isSelected {
                RoundedRectangle(cornerRadius: 2)
                    .strokeBorder(Theme.gold, lineWidth: 1.5)
            }

            // Picked indicator: gold dot top-left + subtle border
            if isPicked {
                ZStack(alignment: .topLeading) {
                    if !isHovered && !isSelected {
                        RoundedRectangle(cornerRadius: 2)
                            .strokeBorder(Theme.gold.opacity(0.4), lineWidth: 1)
                    }
                    Circle()
                        .fill(Theme.gold)
                        .frame(width: 8, height: 8)
                        .padding(5)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }

            // Timecode overlay, bottom-right, visible on hover
            Text(frame.formattedTimestamp)
                .font(.system(size: 11).monospacedDigit())
                .foregroundStyle(Color.white.opacity(0.85))
                .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 1)
                .padding(6)
                .opacity(isHovered ? 1 : 0)
        }
        .aspectRatio(16.0/9.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { onDoubleTap() }
        .onTapGesture { onTap() }
        .onHover { hovering in
            onHover(hovering)
        }
    }
}
