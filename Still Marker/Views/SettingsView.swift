//
//  SettingsView.swift
//  Still Marker
//
//  Preferences window: appearance toggle and about section.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("appearance") private var appearanceSetting: String = AppAppearance.light.rawValue

    private var selectedAppearance: AppAppearance {
        AppAppearance(rawValue: appearanceSetting) ?? .light
    }

    var body: some View {
        TabView {
            appearanceTab
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }

            aboutTab
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 460, height: 320)
    }

    // MARK: - Appearance Tab

    private var appearanceTab: some View {
        Form {
            Picker("Appearance", selection: Binding(
                get: { selectedAppearance },
                set: { newValue in
                    appearanceSetting = newValue.rawValue
                    AppAppearance.apply(newValue)
                }
            )) {
                ForEach(AppAppearance.allCases, id: \.self) { appearance in
                    Text(appearance.label).tag(appearance)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(20)
    }

    // MARK: - About Tab

    private var aboutTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Still Marker")
                .font(.title2.weight(.semibold))

            VStack(alignment: .leading, spacing: 12) {
                aboutItem(
                    icon: "photo.on.rectangle.angled",
                    text: "Highest quality archival stills from your video. Every frame extracted at full resolution, ready for print or portfolio."
                )
                aboutItem(
                    icon: "bolt",
                    text: "Every millisecond shaved off the workflow. Browse hundreds of frames, nudge to the exact moment, pick and export — fast."
                )
                aboutItem(
                    icon: "lock.shield",
                    text: "Everything runs locally on your Mac. No uploads, no cloud, no tracking. Your footage never leaves your machine."
                )
                aboutItem(
                    icon: "film",
                    text: "Named after Chris Marker, the legendary essay filmmaker. Built for filmmakers who care about the still image."
                )
            }

            Spacer()
        }
        .padding(20)
    }

    private func aboutItem(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .frame(width: 20)

            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
