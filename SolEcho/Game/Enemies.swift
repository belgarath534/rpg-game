import Foundation

struct LootDrop: Codable {
    let item: Item
    let chance: Double
    let min: Int
    let max: Int
}

struct Enemy: Codable {
    let name: String
    let maxHealth: Int
    var health: Int
    let attack: Int
    let defense: Int
    let xp: Int
    let goldMin: Int
    let goldMax: Int
    let loot: [LootDrop]
    let isBoss: Bool
    /// Prey you hunt for food rather than a monster that hunts you.
    let isPrey: Bool

    init(
        _ name: String, health: Int, attack: Int, defense: Int, xp: Int,
        gold: ClosedRange<Int> = 0...0, loot: [LootDrop] = [], isBoss: Bool = false, isPrey: Bool = false
    ) {
        self.name = name
        self.maxHealth = health
        self.health = health
        self.attack = attack
        self.defense = defense
        self.xp = xp
        self.goldMin = gold.lowerBound
        self.goldMax = gold.upperBound
        self.loot = loot
        self.isBoss = isBoss
        self.isPrey = isPrey
    }
}

enum Bestiary {
    // Prey
    static var rabbit: Enemy {
        Enemy("Rabbit", health: 8, attack: 1, defense: 0, xp: 4, loot: [
            LootDrop(item: .rawMeat, chance: 1, min: 1, max: 1),
            LootDrop(item: .hide, chance: 0.3, min: 1, max: 1),
        ], isPrey: true)
    }
    static var deer: Enemy {
        Enemy("Deer", health: 20, attack: 3, defense: 0, xp: 10, loot: [
            LootDrop(item: .rawMeat, chance: 1, min: 1, max: 2),
            LootDrop(item: .hide, chance: 1, min: 1, max: 1),
        ], isPrey: true)
    }
    static var goat: Enemy {
        Enemy("Mountain Goat", health: 24, attack: 5, defense: 1, xp: 14, loot: [
            LootDrop(item: .rawMeat, chance: 1, min: 1, max: 2),
            LootDrop(item: .hide, chance: 1, min: 1, max: 1),
        ], isPrey: true)
    }

    // Hostiles
    static var boar: Enemy {
        Enemy("Wild Boar", health: 30, attack: 7, defense: 1, xp: 18, loot: [
            LootDrop(item: .rawMeat, chance: 1, min: 2, max: 2),
            LootDrop(item: .hide, chance: 1, min: 1, max: 1),
        ])
    }
    static var wolf: Enemy {
        Enemy("Grey Wolf", health: 28, attack: 7, defense: 1, xp: 20, loot: [
            LootDrop(item: .hide, chance: 0.8, min: 1, max: 1),
            LootDrop(item: .rawMeat, chance: 0.5, min: 1, max: 1),
        ])
    }
    static var goblin: Enemy {
        Enemy("Goblin Scavenger", health: 26, attack: 7, defense: 2, xp: 22, gold: 2...8, loot: [
            LootDrop(item: .flint, chance: 0.3, min: 1, max: 1),
            LootDrop(item: .bandage, chance: 0.2, min: 1, max: 1),
            LootDrop(item: .ironOre, chance: 0.2, min: 1, max: 1),
        ])
    }
    static var bandit: Enemy {
        Enemy("Bandit", health: 40, attack: 10, defense: 2, xp: 30, gold: 5...15, loot: [
            LootDrop(item: .bandage, chance: 0.4, min: 1, max: 2),
            LootDrop(item: .cookedMeat, chance: 0.3, min: 1, max: 1),
            LootDrop(item: .fullWaterskin, chance: 0.3, min: 1, max: 1),
        ])
    }
    static var drowned: Enemy {
        Enemy("Drowned One", health: 34, attack: 9, defense: 2, xp: 28, gold: 1...6, loot: [
            LootDrop(item: .reeds, chance: 0.6, min: 1, max: 2),
            LootDrop(item: .rawFish, chance: 0.5, min: 1, max: 2),
        ])
    }
    static var troll: Enemy {
        Enemy("Stone Troll", health: 70, attack: 14, defense: 4, xp: 60, gold: 4...12, loot: [
            LootDrop(item: .ironOre, chance: 1, min: 2, max: 3),
            LootDrop(item: .stone, chance: 0.6, min: 1, max: 2),
        ])
    }
    static var shade: Enemy {
        Enemy("Shade", health: 32, attack: 11, defense: 1, xp: 32, gold: 3...10)
    }
    static var hollowKnight: Enemy {
        Enemy("Hollow Knight", health: 55, attack: 13, defense: 4, xp: 45, gold: 8...20, loot: [
            LootDrop(item: .ironOre, chance: 0.6, min: 1, max: 2),
            LootDrop(item: .healingSalve, chance: 0.2, min: 1, max: 1),
        ])
    }
    static var hollowKing: Enemy {
        Enemy("The Hollow King", health: 160, attack: 17, defense: 5, xp: 300, gold: 100...100, isBoss: true)
    }

    static func hostile(for biome: Biome, night: Bool) -> Enemy? {
        var pool: [Enemy]
        switch biome {
        case .grassland: pool = [wolf, goblin, boar]
        case .forest: pool = [wolf, goblin, boar]
        case .lakeshore: pool = [drowned, bandit]
        case .mountains: pool = [troll, bandit, wolf]
        case .ruins: pool = [bandit, hollowKnight, shade]
        case .shrine, .throne: return nil
        }
        if night { pool.append(shade) }
        return pool.randomElement()
    }

    static func prey(for biome: Biome) -> Enemy? {
        switch biome {
        case .grassland: return [rabbit, rabbit, deer].randomElement()
        case .forest: return [deer, rabbit, boar].randomElement()
        case .mountains: return goat
        default: return nil
        }
    }
}
