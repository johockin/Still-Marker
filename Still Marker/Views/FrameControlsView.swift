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
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(isHovered ? Theme.text : Theme.textSecondary)
                    .frame(width: 48, height: 32)

                Text(label)
                    .font(.system(size: 11).monospacedDigit())
                    .foregroundStyle(Theme.textDim)
            }
            .frame(width: 64)
            .padding(.vertical, 6)
            .glassButton(cornerRadius: 8)
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
            HStack(spacing: 8) {
                Image(systemName: "gearshape")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isHovered ? Theme.gold : Theme.textSecondary)

                Text(currentGear.label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isHovered ? Theme.gold : Theme.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .glassButton(cornerRadius: 8)
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
        VStack(spacing: 16) {
            // Nudge controls with inline labels
            HStack(spacing: 8) {
                NudgeButton(
                    icon: "chevron.left.2",
                    label: currentGear.wideLabel,
                    action: { onNudge(-currentGear.wideAmount) },
                    isDisabled: isRefining || isAtStart
                )

                NudgeButton(
                    icon: "chevron.left",
                    label: currentGear.tightLabel,
                    action: { onNudge(-currentGear.tightAmount) },
                    isDisabled: isRefining || isAtStart
                )

                // Timecode + gear toggle
                VStack(spacing: 6) {
                    Text(Frame.formatTimestamp(displayTimestamp))
                        .font(.system(size: 22, design: .monospaced).monospacedDigit())
                        .foregroundStyle(Theme.text)

                    GearToggleView(
                        currentGear: currentGear,
                        onCycleGear: onCycleGear
                    )
                }
                .padding(.horizontal, 12)

                NudgeButton(
                    icon: "chevron.right",
                    label: currentGear.tightLabel,
                    action: { onNudge(currentGear.tightAmount) },
                    isDisabled: isRefining || isAtEnd
                )

                NudgeButton(
                    icon: "chevron.right.2",
                    label: currentGear.wideLabel,
                    action: { onNudge(currentGear.wideAmount) },
                    isDisabled: isRefining || isAtEnd
                )
            }

            // Bottom row: hints + pick/export
            HStack(spacing: 0) {
                Text("esc grid")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textDim)

                Spacer()

                HStack(spacing: 10) {
                    Button(action: onPick) {
                        Text(isPicked ? "unpick" : "pick")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(pickHovered ? (isPicked ? Theme.text : Theme.gold) : (isPicked ? Theme.textSecondary : Theme.goldDim))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .glassButton(isActive: isPicked, cornerRadius: 8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onHover { pickHovered = $0 }
                    .disabled(isRefining)
                    .opacity(isRefining ? 0.5 : 1.0)

                    Button(action: onExport) {
                        Text("export")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(exportHovered ? Theme.gold : Theme.goldDim)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .glassButton(cornerRadius: 8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onHover { exportHovered = $0 }
                    .disabled(isRefining)
                    .opacity(isRefining ? 0.5 : 1.0)
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 12)
        .padding(.bottom, 10)
    }
}
