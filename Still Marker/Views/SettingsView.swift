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
        VStack(alignment: .leading, spacing: 24) {
            // Appearance
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

            Spacer()
        }
        .padding(20)
        .frame(width: 440, height: 320)
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
