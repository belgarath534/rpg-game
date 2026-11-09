import SwiftUI

struct BagView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if let game = store.game {
                    Section("Character") {
                        LabeledContent("Level", value: "\(game.level)")
                        LabeledContent("Experience", value: "\(game.xp) / \(game.xpToNext)")
                        LabeledContent("Attack", value: "\(game.attackPower)")
                        LabeledContent("Defense", value: "\(game.defensePower)")
                        LabeledContent("Weapon", value: game.weapon?.name ?? "Fists")
                        LabeledContent("Armor", value: game.armor?.name ?? "None")
                        LabeledContent("Class", value: game.isWizard ? "Sun Wizard" : "Wanderer")
                        LabeledContent("Gold", value: "\(game.gold)")
                    }
                    Section("Items") {
                        if game.sortedInventory.isEmpty {
                            Text("Your bag is empty. Search the land to find things.")
                                .foregroundStyle(.secondary)
                        }
                        ForEach(game.sortedInventory) { entry in
                            ItemRow(entry: entry, game: game)
                        }
                    }
                }
            }
            .navigationTitle("Bag")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}

private struct ItemRow: View {
    @Environment(GameStore.self) private var store
    let entry: InventoryEntry
    let game: Game

    private var isEquipped: Bool { game.weapon == entry.item || game.armor == entry.item }

    private var actionTitle: String? {
        let item = entry.item
        if item.isEquippable { return isEquipped ? nil : "Equip" }
        switch item.kind {
        case .food: return "Eat"
        case .drink: return item == .fullWaterskin ? "Drink" : nil
        case .medicine: return "Use"
        default: return nil
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(entry.item.name) × \(entry.count)\(isEquipped ? " (equipped)" : "")")
                    .font(.body.bold())
                Text(entry.item.info)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            Spacer()
            if let actionTitle {
                Button(actionTitle) {
                    store.perform { $0.use(entry.item) }
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("\(actionTitle) \(entry.item.name)")
            }
        }
    }
}

struct CraftView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if let game = store.game {
                    ForEach(Recipe.all) { recipe in
                        RecipeRow(recipe: recipe, game: game)
                    }
                }
            }
            .navigationTitle("Craft")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}

private struct RecipeRow: View {
    @Environment(GameStore.self) private var store
    let recipe: Recipe
    let game: Game

    private var requirements: String {
        var parts = recipe.inputs.map { "\($0.item.name) \(game.count($0.item))/\($0.count)" }
        if let tool = recipe.tool {
            parts.append("needs \(tool.name)\(game.count(tool) > 0 ? " ✓" : "")")
        }
        return parts.joined(separator: ", ")
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(recipe.output.name).font(.body.bold())
                Text(requirements)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            Spacer()
            Button("Craft") {
                store.perform { $0.craft(recipe) }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!game.canCraft(recipe))
            .accessibilityLabel("Craft \(recipe.output.name)")
        }
    }
}

struct MapView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                if let game = store.game {
                    VStack(alignment: .leading, spacing: 16) {
                        grid(for: game)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(summary(for: game))
                        Text("Unexplored areas show as dots. Shrines ☀️ restore you and give Echo Shards.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
            }
            .navigationTitle("Map")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }

    private func grid(for game: Game) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: World.size)
        return LazyVGrid(columns: columns, spacing: 2) {
            ForEach(0..<(World.size * World.size), id: \.self) { index in
                let position = Position(x: index % World.size, y: index / World.size)
                cell(for: position, game: game)
            }
        }
    }

    private func cell(for position: Position, game: Game) -> some View {
        let isHere = position == game.position
        let known = game.visited.contains(position)
        return Text(isHere ? "🧍" : (known ? World.biome(at: position).symbol : "·"))
            .font(.system(size: 18))
            .frame(maxWidth: .infinity, minHeight: 28)
            .background(isHere ? Color.orange.opacity(0.4) : Theme.card, in: RoundedRectangle(cornerRadius: 4))
    }

    private func summary(for game: Game) -> String {
        let shrinesFound = World.shrines.keys.filter { game.visited.contains($0) }.count
        return "Map. You are in the \(game.biome.regionName), \(game.position.x + 1) from the west edge and \(game.position.y + 1) from the north edge. "
            + "You have explored \(game.visited.count) of \(World.size * World.size) areas and found \(shrinesFound) of \(World.shrines.count) shrines."
    }
}
