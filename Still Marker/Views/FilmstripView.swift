//
//  FilmstripView.swift
//  Still Marker
//
//  Extracted from ResultsView.swift for maintainability.
//

import SwiftUI

struct FilmstripView: View {
    let frames: [Frame]
    let currentIndex: Int
    let onSelect: (Int) -> Void

    /// How many neighbors to show on each side of the current frame.
    private static let neighborsPerSide: Int = 4

    /// Slice of indices to show: a window centered on currentIndex, clamped at edges.
    private var visibleIndices: [Int] {
        guard !frames.isEmpty else { return [] }
        let total = frames.count
        let windowSize = (Self.neighborsPerSide * 2) + 1
        let half = Self.neighborsPerSide
        // Try to center on currentIndex, but clamp at the start/end so the window
        // doesn't shrink (still shows N frames if there are enough).
        let rawStart = currentIndex - half
        let start = max(0, min(rawStart, total - windowSize))
        let safeStart = max(0, start)
        let end = min(total, safeStart + windowSize)
        return Array(safeStart..<end)
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(visibleIndices, id: \.self) { index in
                let frame = frames[index]
                let isActive = index == currentIndex
                Button(action: { onSelect(index) }) {
                    ZStack {
                        Theme.frameFill
                        Image(nsImage: frame.thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                    .frame(width: 80, height: 45)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .strokeBorder(isActive ? Theme.gold : Color.clear, lineWidth: 1.5)
                    )
                    .opacity(isActive ? 1.0 : 0.5)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .frame(height: 55)
    }
}
