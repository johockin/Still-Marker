//
//  FrameControlsView.swift
//  Still Marker
//
//  Extracted from ResultsView.swift for maintainability.
//

import SwiftUI

// MARK: - Nudge Gear System

enum NudgeGear: Int, CaseIterable {
    case fine = 0
    case medium = 1
    case coarse = 2

    var label: String {
        switch self {
        case .fine: return "fine"
        case .medium: return "mid"
        case .coarse: return "wide"
        }
    }

    /// Left/Right arrow amount (tight nudge)
    var tightAmount: Double {
        switch self {
        case .fine: return 0.033    // ~1 frame
        case .medium: return 0.5    // half second
        case .coarse: return 2.0    // 2 seconds
        }
    }

    /// Up/Down arrow amount (wide nudge)
    var wideAmount: Double {
        switch self {
        case .fine: return 0.5      // half second
        case .medium: return 2.0    // 2 seconds
        case .coarse: return 10.0   // 10 seconds
        }
    }

    /// Shift multiplier: tight becomes wide, wide becomes next tier
    var shiftTightAmount: Double { wideAmount }

    var shiftWideAmount: Double {
        switch self {
        case .fine: return 2.0
        case .medium: return 10.0
        case .coarse: return 30.0
        }
    }

    var tightLabel: String {
        switch self {
        case .fine: return "1 frame"
        case .medium: return "0.5s"
        case .coarse: return "2s"
        }
    }

    var wideLabel: String {
        switch self {
        case .fine: return "0.5s"
        case .medium: return "2s"
        case .coarse: return "10s"
        }
    }

    func next() -> NudgeGear {
        let all = NudgeGear.allCases
        let nextIndex = (rawValue + 1) % all.count
        return all[nextIndex]
    }
}

// MARK: - Gear Dial View

struct GearDialView: View {
    let currentGear: NudgeGear
    let onCycleGear: () -> Void

    @State private var isHovered = false
    @State private var rotationAngle: Double = 0

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                rotationAngle += 120
            }
            onCycleGear()
        }) {
            HStack(spacing: 6) {
                // Gear icon that rotates
                Image(systemName: "gearshape")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isHovered ? Theme.gold : Theme.textDim)
                    .rotationEffect(.degrees(rotationAngle))

                Text(currentGear.label)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(isHovered ? Theme.gold : Theme.textDim)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(isHovered ? 0.06 : 0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(isHovered ? Theme.gold.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { isHovered = $0 }
    }
}

// MARK: - Nudge Button

struct NudgeButton: View {
    let icon: String
    let action: () -> Void
    let isDisabled: Bool

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isHovered ? Theme.text : Theme.textDim)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(isHovered ? 0.08 : 0.03))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .strokeBorder(Color.white.opacity(isHovered ? 0.15 : 0.06), lineWidth: 1)
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
        VStack(spacing: 10) {
            // Nudge controls: wide back, tight back, [timecode], tight fwd, wide fwd
            HStack(spacing: 6) {
                // Wide back (up arrow equivalent)
                NudgeButton(
                    icon: "chevron.left.2",
                    action: { onNudge(-currentGear.wideAmount) },
                    isDisabled: isRefining || isAtStart
                )

                // Tight back (left arrow equivalent)
                NudgeButton(
                    icon: "chevron.left",
                    action: { onNudge(-currentGear.tightAmount) },
                    isDisabled: isRefining || isAtStart
                )

                // Timecode + gear dial
                VStack(spacing: 4) {
                    Text(Frame.formatTimestamp(displayTimestamp))
                        .font(.system(size: 14, design: .monospaced).monospacedDigit())
                        .foregroundStyle(Theme.text)

                    GearDialView(
                        currentGear: currentGear,
                        onCycleGear: onCycleGear
                    )
                }
                .padding(.horizontal, 8)

                // Tight forward
                NudgeButton(
                    icon: "chevron.right",
                    action: { onNudge(currentGear.tightAmount) },
                    isDisabled: isRefining || isAtEnd
                )

                // Wide forward
                NudgeButton(
                    icon: "chevron.right.2",
                    action: { onNudge(currentGear.wideAmount) },
                    isDisabled: isRefining || isAtEnd
                )
            }

            // Key hints showing current gear mapping + pick/export
            HStack(spacing: 0) {
                Text("\u{2190}\u{2192} \(currentGear.tightLabel)  \u{00B7}  \u{2191}\u{2193} \(currentGear.wideLabel)  \u{00B7}  esc back")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textGhost)
                    .tracking(0.3)

                Spacer()

                HStack(spacing: 8) {
                    // Pick/Unpick button
                    Button(action: onPick) {
                        Text(isPicked ? "unpick" : "pick (space)")
                            .font(.system(size: 12))
                            .foregroundStyle(isPicked ? Theme.text : Theme.gold)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .strokeBorder(pickHovered ? (isPicked ? Theme.text : Theme.gold) : (isPicked ? Theme.textDim : Theme.goldDim), lineWidth: 1)
                            )
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(pickHovered ? (isPicked ? Color.white.opacity(0.06) : Theme.gold.opacity(0.08)) : Color.clear)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onHover { pickHovered = $0 }
                    .disabled(isRefining)
                    .opacity(isRefining ? 0.5 : 1.0)

                    // Export button
                    Button(action: onExport) {
                        Text("export")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.gold)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
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
        .padding(.vertical, 8)
        .padding(.bottom, 8)
    }
}
