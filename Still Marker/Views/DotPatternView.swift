//
//  DotPatternView.swift
//  Still Marker
//
//  Created by Claude Code on 2025-01-25.
//

import SwiftUI

struct DotPatternView: View {
    var body: some View {
        Canvas { context, size in
            // Calculate dot spacing - approximately 1cm (28.35 points)
            let dotSpacing: CGFloat = 24
            let dotSize: CGFloat = 2.4
            
            // Calculate grid dimensions
            let cols = Int(size.width / dotSpacing) + 1
            let rows = Int(size.height / dotSpacing) + 1
            
            // Draw dot grid
            for row in 0..<rows {
                for col in 0..<cols {
                    let x = CGFloat(col) * dotSpacing
                    let y = CGFloat(row) * dotSpacing
                    
                    // Create tiny dot
                    let dotRect = CGRect(
                        x: x - dotSize / 2,
                        y: y - dotSize / 2,
                        width: dotSize,
                        height: dotSize
                    )
                    
                    context.fill(
                        Path(ellipseIn: dotRect),
                        with: .color(Color.gray.opacity(0.4))
                    )
                }
            }
        }
    }
}

struct DotPatternView_Previews: PreviewProvider {
    static var previews: some View {
        DotPatternView()
            .frame(width: 400, height: 300)
            .background(Color.gray.opacity(0.2))
    }
}