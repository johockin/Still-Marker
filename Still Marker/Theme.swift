//
//  Theme.swift
//  Still Marker
//
//  TE5 "The Essay Film" color system.
//  The app is a dark room that respects what you brought into it.
//

import SwiftUI

enum Theme {
    static let background = Color.black
    static let text = Color.white.opacity(0.87)
    static let textDim = Color.white.opacity(0.50)
    static let textGhost = Color.white.opacity(0.25)
    static let gold = Color(red: 0.769, green: 0.643, blue: 0.292)  // #C4A44A
    static let goldDim = Color(red: 0.769, green: 0.643, blue: 0.292).opacity(0.25)
}
