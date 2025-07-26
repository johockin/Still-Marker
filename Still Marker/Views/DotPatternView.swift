//
//  DotPatternView.swift
//  Still Marker
//
//  Created by Claude Code on 2025-01-25.
//

import SwiftUI

struct DotPatternView: View {
    let dotSize: CGFloat
    let spacing: CGFloat
    let opacity: Double
    
    init(dotSize: CGFloat = 1.0, spacing: CGFloat = 50.0, opacity: Double = 0.12) {
        self.dotSize = dotSize
        self.spacing = spacing
        self.opacity = opacity
    }
    
    var body: some View {
        Canvas { context, size in
            guard size.width > 0 && size.height > 0 else { return }
            
            // Calculate grid dimensions based on custom spacing
            let cols = Int(size.width / spacing) + 1
            let rows = Int(size.height / spacing) + 1
            
            // Draw dot grid with black dots for film paper texture
            for row in 0..<rows {
                for col in 0..<cols {
                    let x = CGFloat(col) * spacing
                    let y = CGFloat(row) * spacing
                    
                    // Ensure dot is within bounds
                    guard x < size.width && y < size.height else { continue }
                    
                    // Create simple circle dot
                    let dotRect = CGRect(
                        x: x - dotSize / 2,
                        y: y - dotSize / 2,
                        width: dotSize,
                        height: dotSize
                    )
                    
                    // Use ellipse instead of roundedRect for simpler rendering
                    context.fill(
                        Path(ellipseIn: dotRect),
                        with: .color(.black.opacity(opacity))
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct DotPatternView_Previews: PreviewProvider {
    static var previews: some View {
        DotPatternView(dotSize: 2.0, spacing: 50.0, opacity: 0.25)
            .frame(width: 400, height: 300)
            .background(Color(red: 0.12, green: 0.12, blue: 0.13))
    }
}