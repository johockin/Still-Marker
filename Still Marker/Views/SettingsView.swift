//
//  SettingsView.swift
//  Still Marker
//
//  Preferences window: appearance toggle, about section, feedback.
//

import SwiftUI
import AppKit

// MARK: - Appearance Tile

private struct AppearanceTile: View {
    let appearance: AppAppearance
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    private var icon: String {
        switch appearance {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .frame(height: 22)

                Text(appearance.label)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundColor(isSelected ? Theme.gold : Theme.textDim)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Theme.gold.opacity(0.12) : (isHovered ? Theme.surfaceHover : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(isSelected ? Theme.gold.opacity(0.5) : (isHovered ? Theme.borderSubtle : Color.clear), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .animation(.easeOut(duration: 0.15), value: isHovered)
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @AppStorage("appearance") private var appearanceSetting: String = AppAppearance.light.rawValue

    private var selectedAppearance: AppAppearance {
        AppAppearance(rawValue: appearanceSetting) ?? .light
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Appearance
            VStack(alignment: .leading, spacing: 10) {
                Text("Appearance")
                    .font(.headline)

                HStack(spacing: 8) {
                    ForEach(AppAppearance.allCases, id: \.self) { appearance in
                        AppearanceTile(
                            appearance: appearance,
                            isSelected: selectedAppearance == appearance
                        ) {
                            appearanceSetting = appearance.rawValue
                            AppAppearance.apply(appearance)
                        }
                    }
                }
            }

            Divider()

            // About
            VStack(alignment: .leading, spacing: 10) {
                Text("About Still Marker")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    aboutItem(
                        icon: "photo.on.rectangle.angled",
                        text: "We wanted a simple way to pull beautiful, full-resolution stills from video — so we built one."
                    )
                    aboutItem(
                        icon: "bolt",
                        text: "We tried to make it as fast as possible. Browse, nudge, pick, export — hopefully it feels effortless."
                    )
                    aboutItem(
                        icon: "lock.shield",
                        text: "Your footage stays on your Mac. Nothing is uploaded anywhere."
                    )
                    aboutItem(
                        icon: "film",
                        text: "Named after Chris Marker, the essay filmmaker who saw the world in still frames."
                    )
                }
            }

            Divider()

            // Feedback
            VStack(alignment: .leading, spacing: 10) {
                Text("Feedback")
                    .font(.headline)

                Text("We'd love to hear how you're using Still Marker and any ideas you have for future features.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                FeedbackButton(action: openFeedback)
            }

            Spacer()
        }
        .padding(20)
        .frame(width: 440, height: 460)
        .preferredColorScheme(preferredScheme)
        .onAppear {
            AppAppearance.apply(selectedAppearance)
        }
    }

    private var preferredScheme: ColorScheme? {
        switch selectedAppearance {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }

    private func openFeedback() {
        // TODO: Replace with actual feedback URL
        if let url = URL(string: "https://stillmarker.app/feedback") {
            NSWorkspace.shared.open(url)
        }
    }

    private func aboutItem(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .frame(width: 18)

            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Feedback Button

private struct FeedbackButton: View {
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 13, weight: .medium))
                Text("Share Feedback")
                    .font(.system(size: 13, weight: .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .foregroundColor(isHovered ? Theme.gold : Theme.textSecondary)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? Theme.gold.opacity(0.10) : Theme.surfaceSubtle)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(isHovered ? Theme.gold.opacity(0.4) : Theme.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}
