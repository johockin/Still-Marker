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

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 3) {
                    ForEach(0..<frames.count, id: \.self) { index in
                        let frame = frames[index]
                        let isActive = index == currentIndex

                        Button(action: { onSelect(index) }) {
                            ZStack {
                                Color.black

                                Image(nsImage: frame.thumbnail)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            }
                            .frame(width: 80, height: 45)
                            .clipShape(RoundedRectangle(cornerRadius: 1))
                            .border(isActive ? Theme.gold : Color.clear, width: 1.5)
                            .opacity(isActive ? 1.0 : 0.45)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .onHover { hovering in
                            // hover opacity handled below
                        }
                        .id(index)
                    }
                }
                .padding(.horizontal, 12)
            }
            .frame(height: 55)
            .onChange(of: currentIndex) { newIndex in
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
    }
}
