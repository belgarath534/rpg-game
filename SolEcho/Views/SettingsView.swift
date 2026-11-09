import SwiftUI

struct SettingsView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var music = AudioManager.shared.musicVolume
    @State private var ambience = AudioManager.shared.ambienceVolume
    @State private var effects = AudioManager.shared.effectsVolume

    var body: some View {
        NavigationStack {
            List {
                Section("Sound") {
                    VolumeRow(label: "Music", symbol: "music.note", value: $music)
                        .onChange(of: music) { _, value in AudioManager.shared.musicVolume = value }
                    VolumeRow(label: "Ambience", symbol: "leaf.fill", value: $ambience)
                        .onChange(of: ambience) { _, value in AudioManager.shared.ambienceVolume = value }
                    VolumeRow(label: "Sound Effects", symbol: "speaker.wave.2.fill", value: $effects)
                        .onChange(of: effects) { _, value in AudioManager.shared.effectsVolume = value }
                }
                Section {
                    NavigationLink("Credits") { CreditsView() }
                }
                if store.game != nil {
                    Section {
                        Button("Save and Return to Title") {
                            dismiss()
                            store.quitToTitle()
                        }
                    } footer: {
                        Text("Your journey is saved after every action.")
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}

private struct VolumeRow: View {
    let label: String
    let symbol: String
    @Binding var value: Float

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(label, systemImage: symbol)
            Slider(value: $value, in: 0...1, step: 0.1)
                .accessibilityLabel("\(label) volume")
                .accessibilityValue(value == 0 ? "Off" : "\(Int((value * 100).rounded())) percent")
        }
    }
}

struct CreditsView: View {
    var body: some View {
        List {
            Section {
                Text("Sol Echo's music and sounds come from OpenGameArt.org. Thank you to these creators!")
                    .foregroundStyle(.secondary)
            }
            section("Music", Credits.music)
            section("Ambience", Credits.ambience)
            section("Sound Effects", Credits.effects)
        }
        .navigationTitle("Credits")
    }

    private func section(_ title: String, _ entries: [CreditEntry]) -> some View {
        Section(title) {
            ForEach(entries) { entry in
                if let url = URL(string: entry.url) {
                    Link(destination: url) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(entry.title) by \(entry.author)").font(.body).foregroundStyle(.primary)
                            Text("\(entry.use) · \(entry.license)").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityHint("Opens the original on OpenGameArt")
                }
            }
        }
    }
}
