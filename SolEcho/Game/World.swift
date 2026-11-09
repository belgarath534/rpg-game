import Foundation

/// A grid coordinate in the world. `y` grows to the south, `x` grows to the east.
struct Position: Codable, Hashable {
    var x: Int
    var y: Int
}

enum Direction: String, CaseIterable, Codable, Identifiable {
    case north, east, south, west

    var id: String { rawValue }

    var dx: Int {
        switch self {
        case .east: return 1
        case .west: return -1
        default: return 0
        }
    }

    var dy: Int {
        switch self {
        case .south: return 1
        case .north: return -1
        default: return 0
        }
    }

    var label: String { rawValue.capitalized }

    var arrow: String {
        switch self {
        case .north: return "arrow.up"
        case .east: return "arrow.right"
        case .south: return "arrow.down"
        case .west: return "arrow.left"
        }
    }
}

enum Biome: String, Codable, CaseIterable {
    case grassland, forest, lakeshore, mountains, ruins, shrine, throne

    var regionName: String {
        switch self {
        case .grassland: return "Open Grasslands"
        case .forest: return "Whispering Woods"
        case .lakeshore: return "Glasswater Shore"
        case .mountains: return "Ashpeak Mountains"
        case .ruins: return "Hollow Ruins"
        case .shrine: return "Sun Shrine"
        case .throne: return "Throne of the Hollow King"
        }
    }

    /// Short marker used on the map.
    var symbol: String {
        switch self {
        case .grassland: return "🌾"
        case .forest: return "🌲"
        case .lakeshore: return "🌊"
        case .mountains: return "⛰️"
        case .ruins: return "🏚️"
        case .shrine: return "☀️"
        case .throne: return "👑"
        }
    }

    var descriptions: [String] {
        switch self {
        case .grassland:
            return [
                "Tall grass sways in a cold wind. The sun above is pale, like a candle behind glass.",
                "A wide meadow. Crickets go quiet as you pass.",
                "Rolling hills of grass and wildflowers. Something has trampled a path through here.",
            ]
        case .forest:
            return [
                "Old trees lean close together. Their leaves whisper words you almost understand.",
                "Moss and fallen logs. Mushrooms glow faintly in the shade.",
                "The canopy swallows the weak sunlight. Branches crack somewhere nearby.",
            ]
        case .lakeshore:
            return [
                "Cold, clear water laps at a pebble beach. You could drink here.",
                "Reeds rise from the shallows. Fish flicker beneath the surface.",
                "The lake stretches to the horizon, still as a mirror.",
            ]
        case .mountains:
            return [
                "Grey stone and ash-coloured scree. The climb steals your breath.",
                "A narrow pass between cliffs. Veins of rusty ore streak the rock.",
                "Wind howls through the peaks. Something large has left tracks in the gravel.",
            ]
        case .ruins:
            return [
                "Broken walls of a forgotten city. Shadows linger where they shouldn't.",
                "Collapsed towers and scorched stone. The air tastes of old smoke.",
                "A shattered statue of a sun-crowned figure stares at nothing.",
            ]
        case .shrine:
            return [
                "A small stone shrine, warm to the touch. A faint golden hum fills the air.",
            ]
        case .throne:
            return [
                "A great hall without a roof. On a throne of black stone sits a hollow figure, waiting.",
            ]
        }
    }
}

enum World {
    static let size = 11
    static let start = Position(x: 5, y: 5)
    static let throne = Position(x: 0, y: 5)

    /// Shrine positions, each paired with the index of the hint it gives.
    static let shrines: [Position: Int] = [
        Position(x: 5, y: 1): 0,
        Position(x: 9, y: 9): 1,
        Position(x: 2, y: 9): 2,
        Position(x: 1, y: 2): 3,
    ]

    static let shrineHints: [String] = [
        "\"The lake to the east gives water freely. Carry it with you: hide and fibre make a waterskin.\"",
        "\"Flint makes fire. With fire, raw meat becomes a feast and iron ore becomes a blade.\"",
        "\"The Hollow King waits in the western ruins. Do not face him without iron, bandages and a full belly.\"",
        "\"Three Echo Shards awaken the light within. Pray at a shrine while holding them, and the sun will answer.\"",
    ]

    static func contains(_ p: Position) -> Bool {
        p.x >= 0 && p.y >= 0 && p.x < size && p.y < size
    }

    static func biome(at p: Position) -> Biome {
        if p == throne { return .throne }
        if shrines[p] != nil { return .shrine }
        if p.x >= 8 { return .lakeshore }
        if p.y >= 8 { return .mountains }
        if p.y <= 2 { return .forest }
        if p.x <= 1 { return .ruins }
        return .grassland
    }

    static func description(at p: Position) -> String {
        let options = biome(at: p).descriptions
        let index = abs(p.x * 7 + p.y * 13) % options.count
        return options[index]
    }

    static func neighbor(of p: Position, toward direction: Direction) -> Position {
        Position(x: p.x + direction.dx, y: p.y + direction.dy)
    }

    /// One line per direction, e.g. "East: Glasswater Shore". Used for navigation and VoiceOver.
    static func surroundings(of p: Position) -> [Surrounding] {
        Direction.allCases.map { dir in
            let next = neighbor(of: p, toward: dir)
            let label = contains(next) ? biome(at: next).regionName : "Impassable"
            return Surrounding(direction: dir, place: label)
        }
    }
}

struct Surrounding: Identifiable {
    let direction: Direction
    let place: String
    var id: Direction { direction }
}
