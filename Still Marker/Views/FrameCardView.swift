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
            // Pillarbox container — handles any aspect ratio
            Theme.frameFill

            Image(nsImage: frame.thumbnail)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Hover affordance is the floating overlay (rendered above the entire grid),
            // not a border on the cell itself. The cell stays clean.

            // Picked: bold gold border + checkmark badge top-left so it reads from a glance.
            if isPicked {
                RoundedRectangle(cornerRadius: 2)
                    .strokeBorder(Theme.gold, lineWidth: 2)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.gold)
                    .background(Circle().fill(.black.opacity(0.5)))
                    .padding(6)
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
