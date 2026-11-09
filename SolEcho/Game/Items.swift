import Foundation

enum ItemKind: String, Codable {
    case material, food, drink, medicine, weapon, armor, tool, relic
}

enum Item: String, Codable, CaseIterable, Identifiable {
    // Materials
    case wood, fibre, stone, flint, ironOre, hide, reeds
    // Food
    case berries, mushroom, rawMeat, cookedMeat, rawFish, cookedFish
    // Water
    case waterskin, fullWaterskin
    // Medicine
    case bandage, healingSalve
    // Weapons
    case woodenClub, stoneSpear, stoneAxe, ironSword
    // Armor
    case hideArmor, ironMail
    // Tools
    case fishingRod
    // Relics
    case echoShard

    var id: String { rawValue }

    var name: String {
        switch self {
        case .wood: return "Wood"
        case .fibre: return "Plant Fibre"
        case .stone: return "Stone"
        case .flint: return "Flint"
        case .ironOre: return "Iron Ore"
        case .hide: return "Hide"
        case .reeds: return "Reeds"
        case .berries: return "Berries"
        case .mushroom: return "Mushroom"
        case .rawMeat: return "Raw Meat"
        case .cookedMeat: return "Cooked Meat"
        case .rawFish: return "Raw Fish"
        case .cookedFish: return "Cooked Fish"
        case .waterskin: return "Empty Waterskin"
        case .fullWaterskin: return "Full Waterskin"
        case .bandage: return "Bandage"
        case .healingSalve: return "Healing Salve"
        case .woodenClub: return "Wooden Club"
        case .stoneSpear: return "Stone Spear"
        case .stoneAxe: return "Stone Axe"
        case .ironSword: return "Iron Sword"
        case .hideArmor: return "Hide Armor"
        case .ironMail: return "Iron Mail"
        case .fishingRod: return "Fishing Rod"
        case .echoShard: return "Echo Shard"
        }
    }

    var kind: ItemKind {
        switch self {
        case .wood, .fibre, .stone, .flint, .ironOre, .hide, .reeds: return .material
        case .berries, .mushroom, .rawMeat, .cookedMeat, .rawFish, .cookedFish: return .food
        case .waterskin, .fullWaterskin: return .drink
        case .bandage, .healingSalve: return .medicine
        case .woodenClub, .stoneSpear, .stoneAxe, .ironSword: return .weapon
        case .hideArmor, .ironMail: return .armor
        case .fishingRod: return .tool
        case .echoShard: return .relic
        }
    }

    var info: String {
        switch self {
        case .wood: return "Sturdy branches. Used for crafting and cooking fires."
        case .fibre: return "Tough plant strands. Good for binding and bandages."
        case .stone: return "A heavy, sharp-edged rock."
        case .flint: return "Strikes sparks. Needed to cook and to work iron."
        case .ironOre: return "Rust-red ore from the mountains."
        case .hide: return "Animal skin. Makes armor and waterskins."
        case .reeds: return "Hollow lake reeds."
        case .berries: return "Sweet wild berries."
        case .mushroom: return "Edible... probably."
        case .rawMeat: return "Better cooked. Eating it raw may hurt you."
        case .cookedMeat: return "A hearty meal."
        case .rawFish: return "Better cooked."
        case .cookedFish: return "Flaky and filling."
        case .waterskin: return "Fill it at the lake."
        case .fullWaterskin: return "Fresh water for the road."
        case .bandage: return "Stops bleeding. Restores some health."
        case .healingSalve: return "A potent remedy. Restores a lot of health."
        case .woodenClub: return "A crude but solid club."
        case .stoneSpear: return "A sharp spear with a flint tip."
        case .stoneAxe: return "A weapon and a tool. Gathers extra wood."
        case .ironSword: return "A true blade, forged in fire."
        case .hideArmor: return "Stitched hides. Softens blows."
        case .ironMail: return "Heavy iron rings. Strong protection."
        case .fishingRod: return "Lets you fish at the lake."
        case .echoShard: return "A warm fragment of old sunlight. It hums softly."
        }
    }

    /// Hunger restored when eaten.
    var food: Int {
        switch self {
        case .berries: return 12
        case .mushroom: return 8
        case .rawMeat: return 12
        case .cookedMeat: return 35
        case .rawFish: return 10
        case .cookedFish: return 30
        default: return 0
        }
    }

    /// Thirst restored when drunk.
    var water: Int {
        switch self {
        case .fullWaterskin: return 45
        case .berries: return 3
        default: return 0
        }
    }

    /// Health restored when used.
    var heal: Int {
        switch self {
        case .bandage: return 25
        case .healingSalve: return 50
        case .cookedMeat, .cookedFish: return 5
        default: return 0
        }
    }

    var attack: Int {
        switch self {
        case .woodenClub: return 5
        case .stoneSpear: return 8
        case .stoneAxe: return 7
        case .ironSword: return 13
        default: return 0
        }
    }

    var defense: Int {
        switch self {
        case .hideArmor: return 3
        case .ironMail: return 6
        default: return 0
        }
    }

    var isConsumable: Bool { kind == .food || kind == .medicine || self == .fullWaterskin }
    var isEquippable: Bool { kind == .weapon || kind == .armor }
}

struct Recipe: Identifiable {
    let output: Item
    let amount: Int
    let inputs: [(item: Item, count: Int)]
    /// An item you must own, but which isn't used up.
    let tool: Item?

    var id: String { output.rawValue }

    static let all: [Recipe] = [
        Recipe(output: .woodenClub, amount: 1, inputs: [(.wood, 2)], tool: nil),
        Recipe(output: .stoneSpear, amount: 1, inputs: [(.wood, 1), (.flint, 1), (.fibre, 1)], tool: nil),
        Recipe(output: .stoneAxe, amount: 1, inputs: [(.wood, 1), (.stone, 2), (.fibre, 1)], tool: nil),
        Recipe(output: .ironSword, amount: 1, inputs: [(.ironOre, 3), (.wood, 2)], tool: .flint),
        Recipe(output: .hideArmor, amount: 1, inputs: [(.hide, 3), (.fibre, 2)], tool: nil),
        Recipe(output: .ironMail, amount: 1, inputs: [(.ironOre, 4), (.hide, 1), (.wood, 1)], tool: .flint),
        Recipe(output: .fishingRod, amount: 1, inputs: [(.wood, 1), (.fibre, 2)], tool: nil),
        Recipe(output: .waterskin, amount: 1, inputs: [(.hide, 1), (.fibre, 1)], tool: nil),
        Recipe(output: .bandage, amount: 1, inputs: [(.fibre, 2)], tool: nil),
        Recipe(output: .healingSalve, amount: 1, inputs: [(.berries, 1), (.mushroom, 1), (.fibre, 1)], tool: nil),
        Recipe(output: .cookedMeat, amount: 1, inputs: [(.rawMeat, 1), (.wood, 1)], tool: .flint),
        Recipe(output: .cookedFish, amount: 1, inputs: [(.rawFish, 1), (.wood, 1)], tool: .flint),
    ]
}
