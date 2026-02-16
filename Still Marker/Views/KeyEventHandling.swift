//
//  KeyEventHandling.swift
//  Still Marker
//
//  Extracted from ResultsView.swift for maintainability.
//

import SwiftUI
import AppKit

// MARK: - Keyboard Event Handling

struct KeyEventHandlingView: NSViewRepresentable {
    let onLeftArrow: () -> Void
    let onRightArrow: () -> Void
    let onShiftLeftArrow: () -> Void
    let onShiftRightArrow: () -> Void
    let onUpArrow: () -> Void
    let onDownArrow: () -> Void
    let onEscape: () -> Void
    let onPick: () -> Void

    func makeNSView(context: Context) -> KeyCaptureView {
        let view = KeyCaptureView()
        view.onLeftArrow = onLeftArrow
        view.onRightArrow = onRightArrow
        view.onShiftLeftArrow = onShiftLeftArrow
        view.onShiftRightArrow = onShiftRightArrow
        view.onUpArrow = onUpArrow
        view.onDownArrow = onDownArrow
        view.onEscape = onEscape
        view.onPick = onPick
        return view
    }

    func updateNSView(_ nsView: KeyCaptureView, context: Context) {
        nsView.onLeftArrow = onLeftArrow
        nsView.onRightArrow = onRightArrow
        nsView.onShiftLeftArrow = onShiftLeftArrow
        nsView.onShiftRightArrow = onShiftRightArrow
        nsView.onUpArrow = onUpArrow
        nsView.onDownArrow = onDownArrow
        nsView.onEscape = onEscape
        nsView.onPick = onPick
    }
}

class KeyCaptureView: NSView {
    var onLeftArrow: (() -> Void)?
    var onRightArrow: (() -> Void)?
    var onShiftLeftArrow: (() -> Void)?
    var onShiftRightArrow: (() -> Void)?
    var onUpArrow: (() -> Void)?
    var onDownArrow: (() -> Void)?
    var onEscape: (() -> Void)?
    var onPick: (() -> Void)?

    override var acceptsFirstResponder: Bool { true }
    override var canBecomeKeyView: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        DispatchQueue.main.async { [weak self] in
            self?.window?.makeFirstResponder(self)
        }
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        super.mouseDown(with: event)
    }

    override func keyDown(with event: NSEvent) {
        let isShiftPressed = event.modifierFlags.contains(.shift)

        switch event.keyCode {
        case 123: // Left arrow
            if isShiftPressed {
                onShiftLeftArrow?()
            } else {
                onLeftArrow?()
            }
        case 124: // Right arrow
            if isShiftPressed {
                onShiftRightArrow?()
            } else {
                onRightArrow?()
            }
        case 125: // Down arrow
            onDownArrow?()
        case 126: // Up arrow
            onUpArrow?()
        case 53: // Escape
            onEscape?()
        case 49: // Space bar
            onPick?()
        case 35: // P key
            onPick?()
        default:
            super.keyDown(with: event)
        }
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
}
