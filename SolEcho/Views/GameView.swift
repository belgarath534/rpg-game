import SwiftUI

enum GameSheet: String, Identifiable {
    case bag, craft, map
    var id: String { rawValue }
}

struct GameView: View {
    @Environment(GameStore.self) private var store
    let game: Game
    @State private var sheet: GameSheet?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                StatsPanel(game: game)
                locationCard
                Card {
                    Text("Journal").font(.headline).accessibilityAddTraits(.isHeader)
                    LogList(entries: Array(game.log.suffix(6)))
                }
                CompassView(game: game)
                actions
                menuRow
            }
            .padding()
        }
        .sheet(item: $sheet) { sheet in
            switch sheet {
            case .bag: BagView()
            case .craft: CraftView()
            case .map: MapView()
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(game.biome.symbol) \(game.biome.regionName)")
                    .font(.title2.bold())
                    .accessibilityAddTraits(.isHeader)
                Text(game.timeLabel)
                    .font(.subheadline)
                    .foregroundStyle(game.isNight ? Color.indigo : Color.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("Level \(game.level)").font(.subheadline.bold())
                Text("\(game.gold) gold").font(.caption).foregroundStyle(.yellow)
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var locationCard: some View {
        Card {
            Text(World.description(at: game.position))
                .foregroundStyle(.secondary)
            Divider()
            ForEach(World.surroundings(of: game.position)) { near in
                HStack {
                    Image(systemName: near.direction.arrow).frame(width: 20).accessibilityHidden(true)
                    Text("\(near.direction.label): \(near.place)").font(.subheadline)
                }
            }
        }
    }

    private var actions: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ActionButton(title: "Search", symbol: "magnifyingglass") { store.perform { $0.search() } }
            ActionButton(title: "Rest", symbol: "bed.double.fill", tint: .indigo) { store.perform { $0.rest() } }
            if game.canHunt {
                ActionButton(title: "Hunt", symbol: "hare.fill", tint: .brown) { store.perform { $0.hunt() } }
            }
            if game.canDrinkHere {
                ActionButton(title: "Drink", symbol: "drop.fill", tint: .blue) { store.perform { $0.drinkFromLake() } }
            }
            if game.canFish {
                ActionButton(title: "Fish", symbol: "fish.fill", tint: .teal) { store.perform { $0.fish() } }
            }
            if game.shrineHere != nil {
                ActionButton(title: "Pray", symbol: "sun.max.fill", tint: .yellow) { store.perform { $0.pray() } }
            }
            if game.canAwaken {
                ActionButton(title: "Awaken", symbol: "wand.and.stars", tint: .purple) { store.perform { $0.awaken() } }
            }
            if game.canChallengeKing {
                ActionButton(title: "Face the King", symbol: "crown.fill", tint: .red) { store.perform { $0.challengeKing() } }
            }
        }
    }

    private var menuRow: some View {
        HStack(spacing: 10) {
            menuButton("Bag", "backpack.fill", .bag)
            menuButton("Craft", "hammer.fill", .craft)
            menuButton("Map", "map.fill", .map)
        }
    }

    private func menuButton(_ title: String, _ symbol: String, _ target: GameSheet) -> some View {
        Button {
            sheet = target
        } label: {
            Label(title, systemImage: symbol)
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 48)
        }
        .buttonStyle(.bordered)
    }
}

struct StatsPanel: View {
    let game: Game

    var body: some View {
        Card {
            StatBar(label: "Health", symbol: "heart.fill", value: game.health, maximum: game.maxHealth, color: .red)
            StatBar(label: "Food", symbol: "fork.knife", value: game.hunger, maximum: 100, color: .orange)
            StatBar(label: "Water", symbol: "drop.fill", value: game.thirst, maximum: 100, color: .blue)
            StatBar(label: "Energy", symbol: "bolt.fill", value: game.energy, maximum: 100, color: .yellow)
            if game.isWizard {
                StatBar(label: "Mana", symbol: "sparkles", value: game.mana, maximum: game.maxMana, color: .purple)
            }
        }
    }
}

struct CompassView: View {
    @Environment(GameStore.self) private var store
    let game: Game

    var body: some View {
        Grid(horizontalSpacing: 14, verticalSpacing: 10) {
            GridRow {
                Color.clear.frame(width: 1, height: 1)
                button(.north)
                Color.clear.frame(width: 1, height: 1)
            }
            GridRow {
                button(.west)
                Image(systemName: "location.north.circle.fill")
                    .font(.title)
                    .foregroundStyle(.orange)
                    .accessibilityHidden(true)
                button(.east)
            }
            GridRow {
                Color.clear.frame(width: 1, height: 1)
                button(.south)
                Color.clear.frame(width: 1, height: 1)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func button(_ direction: Direction) -> some View {
        let canMove = game.canMove(direction)
        let next = World.neighbor(of: game.position, toward: direction)
        return Button {
            store.perform { $0.move(direction) }
        } label: {
            Image(systemName: direction.arrow)
                .font(.title2.bold())
                .frame(width: 60, height: 60)
                .background(Color.orange.opacity(canMove ? 0.25 : 0.06), in: Circle())
        }
        .disabled(!canMove)
        .accessibilityLabel("Go \(direction.label)")
        .accessibilityHint(canMove ? World.biome(at: next).regionName : "Impassable")
    }
}
