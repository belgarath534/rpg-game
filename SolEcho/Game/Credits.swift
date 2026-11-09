import Foundation

/// Every sound in the game comes from OpenGameArt.org. CC-BY works require credit; CC0 works don't,
/// but we credit everyone anyway. Keep this list in sync with CREDITS.md.
struct CreditEntry: Identifiable {
    let use: String
    let title: String
    let author: String
    let license: String
    let url: String
    var id: String { use + title }
}

enum Credits {
    static let music: [CreditEntry] = [
        CreditEntry(use: "Title music", title: "Tragic ambient main menu", author: "HaelDB", license: "CC0", url: "https://opengameart.org/content/tragic-ambient-main-menu"),
        CreditEntry(use: "Exploring", title: "Medieval: Exploration", author: "RandomMind", license: "CC0", url: "https://opengameart.org/content/medieval-exploration"),
        CreditEntry(use: "Night", title: "Crystal Cave (song18)", author: "cynicmusic", license: "CC0", url: "https://opengameart.org/content/crystal-cave-song18"),
        CreditEntry(use: "Battle", title: "Battle Theme A", author: "cynicmusic", license: "CC0", url: "https://opengameart.org/content/battle-theme-a"),
        CreditEntry(use: "Boss battle", title: "Epic Boss Battle", author: "Juhani Junkala (SubspaceAudio)", license: "CC0", url: "https://opengameart.org/content/boss-battle-music"),
        CreditEntry(use: "Victory", title: "Lively Meadow Victory Fanfare", author: "Matthew Pablo (matthewpablo.com)", license: "CC-BY 3.0", url: "https://opengameart.org/content/lively-meadow-victory-fanfare-and-song"),
        CreditEntry(use: "Defeat", title: "Heroic Demise (shortened)", author: "Matthew Pablo (matthewpablo.com)", license: "CC-BY 3.0", url: "https://opengameart.org/content/heroic-demise-updated-version"),
    ]

    static let ambience: [CreditEntry] = [
        CreditEntry(use: "Woods, lake, mountains, shrines", title: "Nature Ambient Pack Vol 1", author: "JC Sounds", license: "CC-BY 4.0", url: "https://opengameart.org/content/jc-sounds-nature-ambient-pack-vol-1"),
        CreditEntry(use: "Grassland wind", title: "wind1", author: "Luke.RUSTLTD", license: "CC0", url: "https://opengameart.org/content/wind1"),
        CreditEntry(use: "Night crickets", title: "Crickets Ambient Noise", author: "Wolfgang_", license: "CC0", url: "https://opengameart.org/content/crickets-ambient-noise-loopable"),
        CreditEntry(use: "Ruins", title: "Loopable Dungeon Ambience", author: "JaggedStone", license: "CC0", url: "https://opengameart.org/content/loopable-dungeon-ambience"),
    ]

    static let effects: [CreditEntry] = [
        CreditEntry(use: "Battle, items, shades", title: "RPG Sound Pack", author: "artisticdude", license: "CC0", url: "https://opengameart.org/content/rpg-sound-pack"),
        CreditEntry(use: "Items, spells, creatures", title: "80 CC0 RPG SFX", author: "rubberduck", license: "CC0", url: "https://opengameart.org/content/80-cc0-rpg-sfx"),
        CreditEntry(use: "Searching, fleeing", title: "50 RPG sound effects", author: "Kenney", license: "CC0", url: "https://opengameart.org/content/50-rpg-sound-effects"),
        CreditEntry(use: "Footsteps", title: "Fantozzi's Footsteps", author: "Fantozzi / qubodup", license: "CC0", url: "https://opengameart.org/content/fantozzis-footsteps-grasssand-stone"),
        CreditEntry(use: "Drinking", title: "Liquid Bottle Drink Set", author: "qubodup", license: "CC0", url: "https://opengameart.org/content/liquid-bottle-drink-set"),
        CreditEntry(use: "Hits", title: "37 hits/punches", author: "Independent.nu / qubodup", license: "CC0", url: "https://opengameart.org/content/37-hitspunches"),
        CreditEntry(use: "Eating", title: "7 Eating Crunches", author: "StarNinjas", license: "CC0", url: "https://opengameart.org/content/7-eating-crunches"),
        CreditEntry(use: "Level up", title: "Completion sound", author: "HaelDB", license: "CC0", url: "https://opengameart.org/content/completion-sound"),
        CreditEntry(use: "Shrine blessing", title: "Magic Words + Healing Sound Effect", author: "Spring Spring", license: "CC0", url: "https://opengameart.org/content/magic-words-healing-sound-effect"),
    ]
}
