import SwiftUI

struct CombatView: View {
    @Environment(GameStore.self) private var store
    let game: Game

    private var enemy: Enemy? { game.combat?.enemy }

    private var usableItems: [InventoryEntry] {
        game.sortedInventory.filter { $0.item.isConsumable }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let enemy {
                    Text(enemy.isPrey ? "Hunting" : (enemy.isBoss ? "Final Battle" : "Battle"))
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Text(enemy.name)
                        .font(.largeTitle.bold())
                        .foregroundStyle(enemy.isBoss ? Color.red : Color.primary)
                        .accessibilityAddTraits(.isHeader)
                    Card {
                        StatBar(label: enemy.name, symbol: "flame.fill", value: enemy.health, maximum: enemy.maxHealth, color: .red)
                        Text("Attack \(enemy.attack) · Defense \(enemy.defense)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Card {
                    StatBar(label: "Your Health", symbol: "heart.fill", value: game.health, maximum: game.maxHealth, color: .green)
                    if game.isWizard {
                        StatBar(label: "Mana", symbol: "sparkles", value: game.mana, maximum: game.maxMana, color: .purple)
                    }
                    Text("Weapon: \(game.weapon?.name ?? "Fists") · Armor: \(game.armor?.name ?? "None")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Card {
                    LogList(entries: Array(game.log.suffix(5)))
                }
                buttons
            }
            .padding()
        }
    }

    private var buttons: some View {
        VStack(spacing: 10) {
            ActionButton(title: "Attack", symbol: "burst.fill", tint: .red) { store.perform { $0.attack() } }
            HStack(spacing: 10) {
                ActionButton(title: "Defend", symbol: "shield.fill", tint: .blue) { store.perform { $0.defend() } }
                itemsMenu
            }
            if game.isWizard {
                ActionButton(title: "Sunbolt (\(Game.sunboltCost) mana)", symbol: "sun.max.fill", tint: .yellow) {
                    store.perform { $0.castSunbolt() }
                }
                .disabled(!game.canCastSunbolt)
            }
            if enemy?.isBoss != true {
                ActionButton(title: enemy?.isPrey == true ? "Let it go" : "Flee", symbol: "figure.run", tint: .gray) {
                    store.perform { $0.flee() }
                }
            }
        }
    }

    private var itemsMenu: some View {
        Menu {
            if usableItems.isEmpty {
                Text("Nothing to use")
            }
            ForEach(usableItems) { entry in
                Button("\(entry.item.name) (\(entry.count))") {
                    store.perform { $0.useInCombat(entry.item) }
                }
            }
        } label: {
            Label("Items", systemImage: "bag.fill")
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 48)
        }
        .buttonStyle(.bordered)
    }
}
