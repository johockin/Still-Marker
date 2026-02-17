//
//  FrameControlsView.swift
//  Still Marker
//
//  Nudge controls, gear system, pick and export buttons.
//

import SwiftUI

// MARK: - Nudge Gear System (2 gears)

enum NudgeGear: Int, CaseIterable {
    case fine = 0
    case wide = 1

    var label: String {
        switch self {
        case .fine: return "fine"
        case .wide: return "wide"
        }
    }

    /// Left/Right arrow amount
    var tightAmount: Double {
        switch self {
        case .fine: return 0.033    // ~1 frame
        case .wide: return 2.0     // 2 seconds
        }
    }

    /// Up/Down arrow amount
    var wideAmount: Double {
        switch self {
        case .fine: return 0.5     // half second
        case .wide: return 10.0   // 10 seconds
        }
    }

    /// Shift multiplier
    var shiftTightAmount: Double { wideAmount }

    var shiftWideAmount: Double {
        switch self {
        case .fine: return 2.0
        case .wide: return 30.0
        }
    }

    var tightLabel: String {
        switch self {
        case .fine: return "1 frame"
        case .wide: return "2s"
        }
    }

    var wideLabel: String {
        switch self {
        case .fine: return "0.5s"
        case .wide: return "10s"
        }
    }

    func next() -> NudgeGear {
        let all = NudgeGear.allCases
        let nextIndex = (rawValue + 1) % all.count
        return all[nextIndex]
    }
}

// MARK: - Nudge Button

struct NudgeButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    let isDisabled: Bool

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isHovered ? Theme.text : Theme.textSecondary)
                    .frame(width: 36, height: 28)

                Text(label)
                    .font(.system(size: 9).monospacedDigit())
                    .foregroundStyle(Theme.textDim)
            }
            .frame(width: 44)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isHovered ? Theme.surfaceHover : Theme.surfaceSubtle)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(isHovered ? Theme.borderHover : Theme.borderSubtle, lineWidth: 1)
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.3 : 1.0)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Gear Toggle

struct GearToggleView: View {
    let currentGear: NudgeGear
    let onCycleGear: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onCycleGear) {
            HStack(spacing: 6) {
                Image(systemName: "gearshape")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isHovered ? Theme.gold : Theme.textSecondary)

                Text(currentGear.label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isHovered ? Theme.gold : Theme.textSecondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isHovered ? Theme.surfaceHover : Theme.surfaceSubtle)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(isHovered ? Theme.gold.opacity(0.4) : Theme.borderSubtle, lineWidth: 1)
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { isHovered = $0 }
    }
}

// MARK: - Frame Controls View Component

struct FrameControlsView: View {
    let frame: Frame
    let refinedTimestamp: Double?
    let isRefining: Bool
    let isPicked: Bool
    let videoDuration: Double
    let currentGear: NudgeGear
    let onNudge: (Double) -> Void
    let onCycleGear: () -> Void
    let onPick: () -> Void
    let onExport: () -> Void

    @State private var pickHovered = false
    @State private var exportHovered = false

    private var displayTimestamp: Double {
        refinedTimestamp ?? frame.timestamp
    }

    private var isAtStart: Bool {
        displayTimestamp <= 0
    }

    private var isAtEnd: Bool {
        videoDuration > 0 && displayTimestamp >= videoDuration - 0.1
    }

    var body: some View {
        VStack(spacing: 12) {
            // Nudge controls with inline labels
            HStack(spacing: 6) {
                NudgeButton(
                    icon: "chevron.left.2",
                    label: "\u{2191}\u{2193} \(currentGear.wideLabel)",
                    action: { onNudge(-currentGear.wideAmount) },
                    isDisabled: isRefining || isAtStart
                )

                NudgeButton(
                    icon: "chevron.left",
                    label: "\u{2190}\u{2192} \(currentGear.tightLabel)",
                    action: { onNudge(-currentGear.tightAmount) },
                    isDisabled: isRefining || isAtStart
                )

                // Timecode + gear toggle
                VStack(spacing: 4) {
                    Text(Frame.formatTimestamp(displayTimestamp))
                        .font(.system(size: 15, design: .monospaced).monospacedDigit())
                        .foregroundStyle(Theme.text)

                    GearToggleView(
                        currentGear: currentGear,
                        onCycleGear: onCycleGear
                    )
                }
                .padding(.horizontal, 8)

                NudgeButton(
                    icon: "chevron.right",
                    label: "\u{2190}\u{2192} \(currentGear.tightLabel)",
                    action: { onNudge(currentGear.tightAmount) },
                    isDisabled: isRefining || isAtEnd
                )

                NudgeButton(
                    icon: "chevron.right.2",
                    label: "\u{2191}\u{2193} \(currentGear.wideLabel)",
                    action: { onNudge(currentGear.wideAmount) },
                    isDisabled: isRefining || isAtEnd
                )
            }

            // Bottom row: hints + pick/export
            HStack(spacing: 0) {
                Text("esc grid")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textDim)

                Spacer()

                HStack(spacing: 8) {
                    Button(action: onPick) {
                        Text(isPicked ? "unpick" : "pick (space)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(isPicked ? Theme.text : Theme.gold)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .strokeBorder(pickHovered ? (isPicked ? Theme.text : Theme.gold) : (isPicked ? Theme.textDim : Theme.goldDim), lineWidth: 1)
                            )
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(pickHovered ? (isPicked ? Theme.surfaceHover : Theme.gold.opacity(0.08)) : Color.clear)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onHover { pickHovered = $0 }
                    .disabled(isRefining)
                    .opacity(isRefining ? 0.5 : 1.0)

                    Button(action: onExport) {
                        Text("export")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.gold)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .strokeBorder(exportHovered ? Theme.gold : Theme.goldDim, lineWidth: 1)
                            )
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(exportHovered ? Theme.gold.opacity(0.08) : Color.clear)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onHover { exportHovered = $0 }
                    .disabled(isRefining)
                    .opacity(isRefining ? 0.5 : 1.0)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 10)
        .padding(.bottom, 8)
    }
}
