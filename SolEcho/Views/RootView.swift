import SwiftUI

struct RootView: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            if let game = store.game {
                if game.isOver {
                    EndView(game: game)
                } else if game.combat != nil {
                    CombatView(game: game)
                } else {
                    GameView(game: game)
                }
            } else {
                TitleView()
            }
        }
    }
}

struct TitleView: View {
    @Environment(GameStore.self) private var store
    @State private var confirmNewGame = false
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "sun.max.fill")
                .font(.system(size: 80))
                .foregroundStyle(Theme.sun)
                .accessibilityHidden(true)
            Text("Sol Echo")
                .font(.system(size: 48, weight: .bold, design: .serif))
                .foregroundStyle(Theme.sun)
                .accessibilityAddTraits(.isHeader)
            Text("No name. No food. No supplies.\nSurvive, and bring back the light.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Spacer()
            VStack(spacing: 12) {
                if store.hasSave {
                    ActionButton(title: "Continue", symbol: "play.fill") { store.continueGame() }
                }
                ActionButton(title: "New Game", symbol: "sparkles", tint: store.hasSave ? .gray : .orange) {
                    if store.hasSave { confirmNewGame = true } else { store.newGame() }
                }
            }
            .padding(.horizontal, 32)
            Button("Settings & Credits") { showSettings = true }
                .padding(.bottom, 32)
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .confirmationDialog("Start a new game? Your current journey will be lost.", isPresented: $confirmNewGame, titleVisibility: .visible) {
            Button("Start New Game", role: .destructive) { store.newGame() }
        }
    }
}

struct EndView: View {
    @Environment(GameStore.self) private var store
    let game: Game

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: game.hasWon ? "sun.max.fill" : "moon.zzz.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(game.hasWon ? Color.yellow : Color.gray)
                    .accessibilityHidden(true)
                    .padding(.top, 40)
                Text(game.hasWon ? "The Light Returns" : "You Have Fallen")
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)
                Text(game.hasWon
                     ? "You came from nothing, with no name. Now the whole world will remember you."
                     : (game.deathCause ?? "Your journey ends here."))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Card {
                    Text("Survived until \(game.timeLabel)")
                    Text("Reached level \(game.level)")
                    Text("Explored \(game.visited.count) of \(World.size * World.size) areas")
                    Text("Gold: \(game.gold)")
                }
                .accessibilityElement(children: .combine)
                ActionButton(title: "Begin Again", symbol: "arrow.counterclockwise") { store.newGame() }
                Button("Back to Title") { store.quitToTitle() }
                    .padding(.top, 4)
            }
            .padding()
        }
    }
}
