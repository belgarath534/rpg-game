import AVFoundation
import Foundation

/// Plays music, area ambience and sound effects. Music and ambience crossfade when they change.
/// Uses a mixing audio session so VoiceOver speech is never cut off.
final class AudioManager {
    static let shared = AudioManager()

    enum Track: String {
        case title = "music_title", explore = "music_explore", night = "music_night"
        case battle = "music_battle", boss = "music_boss", victory = "music_victory", defeat = "music_defeat"

        var loops: Bool { self != .victory && self != .defeat }
    }

    enum Ambience: String {
        case grassland = "amb_grassland", forest = "amb_forest", forestNight = "amb_forest_night"
        case lake = "amb_lake", mountains = "amb_mountains", ruins = "amb_ruins"
        case shrine = "amb_shrine", night = "amb_night"
    }

    private static let musicKey = "audio.music", ambienceKey = "audio.ambience", effectsKey = "audio.effects"

    var musicVolume: Float {
        didSet { save(musicVolume, Self.musicKey); musicPlayer?.volume = musicVolume }
    }
    var ambienceVolume: Float {
        didSet { save(ambienceVolume, Self.ambienceKey); ambiencePlayer?.volume = ambienceLevel }
    }
    var effectsVolume: Float {
        didSet { save(effectsVolume, Self.effectsKey) }
    }

    private var musicPlayer: AVAudioPlayer?
    private var ambiencePlayer: AVAudioPlayer?
    private var currentTrack: Track?
    private var currentAmbience: Ambience?
    private var inBattle = false
    private var effectPlayers: [Sound: [AVAudioPlayer]] = [:]
    private let fade: TimeInterval = 1.2

    /// Ambience gets quieter during battles so the fight stands out.
    private var ambienceLevel: Float { ambienceVolume * (inBattle ? 0.35 : 1) }

    private init() {
        let defaults = UserDefaults.standard
        musicVolume = defaults.object(forKey: Self.musicKey) as? Float ?? 0.5
        ambienceVolume = defaults.object(forKey: Self.ambienceKey) as? Float ?? 0.7
        effectsVolume = defaults.object(forKey: Self.effectsKey) as? Float ?? 0.9
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    private func save(_ value: Float, _ key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }

    private func makePlayer(_ name: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "m4a") else { return nil }
        let player = try? AVAudioPlayer(contentsOf: url)
        player?.prepareToPlay()
        return player
    }

    // MARK: - Music & ambience

    func play(track: Track?) {
        guard track != currentTrack else { return }
        currentTrack = track
        musicPlayer = crossfade(from: musicPlayer, to: track?.rawValue, loops: track?.loops ?? true, volume: musicVolume)
    }

    func play(ambience: Ambience?, battle: Bool) {
        let battleChanged = battle != inBattle
        inBattle = battle
        if ambience != currentAmbience {
            currentAmbience = ambience
            ambiencePlayer = crossfade(from: ambiencePlayer, to: ambience?.rawValue, loops: true, volume: ambienceLevel)
        } else if battleChanged {
            ambiencePlayer?.setVolume(ambienceLevel, fadeDuration: fade)
        }
    }

    private func crossfade(from old: AVAudioPlayer?, to name: String?, loops: Bool, volume: Float) -> AVAudioPlayer? {
        if let old {
            old.setVolume(0, fadeDuration: fade)
            DispatchQueue.main.asyncAfter(deadline: .now() + fade) { old.stop() }
        }
        guard let name, let player = makePlayer(name) else { return nil }
        player.numberOfLoops = loops ? -1 : 0
        player.volume = 0
        player.play()
        player.setVolume(volume, fadeDuration: fade)
        return player
    }

    // MARK: - Effects

    func play(_ sounds: [Sound]) {
        guard effectsVolume > 0 else { return }
        // Space effects out a little so a swing and a hit don't land on top of each other.
        for (index, sound) in sounds.prefix(4).enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.18) { [weak self] in
                self?.playEffect(sound)
            }
        }
    }

    private func playEffect(_ sound: Sound) {
        var pool = effectPlayers[sound, default: []]
        let player: AVAudioPlayer
        if let idle = pool.first(where: { !$0.isPlaying }) {
            player = idle
        } else if let fresh = makePlayer(Self.fileName(for: sound)) {
            player = fresh
            pool.append(fresh)
            effectPlayers[sound] = pool
        } else {
            return
        }
        player.volume = effectsVolume
        player.currentTime = 0
        player.play()
    }

    private static func fileName(for sound: Sound) -> String {
        switch sound {
        case .stepSoft: return "sfx_step_soft"
        case .stepStone: return "sfx_step_stone"
        case .search: return "sfx_search"
        case .pickup: return "sfx_pickup"
        case .coins: return "sfx_coins"
        case .craft: return "sfx_craft"
        case .drink: return "sfx_drink"
        case .eat: return "sfx_eat"
        case .equip: return "sfx_equip"
        case .swing: return "sfx_swing"
        case .hit: return "sfx_hit"
        case .crit: return "sfx_crit"
        case .block: return "sfx_block"
        case .hurt: return "sfx_hurt"
        case .sunbolt: return "sfx_sunbolt"
        case .awaken: return "sfx_awaken"
        case .levelUp: return "sfx_levelup"
        case .shrine: return "sfx_shrine"
        case .enemyAppear: return "sfx_enemy_appear"
        case .shade: return "sfx_shade"
        case .enemyDie: return "sfx_enemy_die"
        case .flee: return "sfx_flee"
        }
    }

    // MARK: - Choosing what fits the moment

    /// Picks music and ambience for the current game state (nil game = title screen).
    func update(for game: Game?) {
        guard let game else {
            play(track: .title)
            play(ambience: .grassland, battle: false)
            return
        }
        if game.hasWon {
            play(track: .victory)
        } else if game.isDead {
            play(track: .defeat)
        } else if let fight = game.combat, !fight.enemy.isPrey {
            play(track: fight.enemy.isBoss ? .boss : .battle)
        } else {
            play(track: game.isNight ? .night : .explore)
        }
        play(ambience: Self.ambience(for: game), battle: game.combat != nil && game.combat?.enemy.isPrey == false)
    }

    private static func ambience(for game: Game) -> Ambience? {
        if game.isOver { return nil }
        switch game.biome {
        case .grassland: return game.isNight ? .night : .grassland
        case .forest: return game.isNight ? .forestNight : .forest
        case .lakeshore: return .lake
        case .mountains: return .mountains
        case .ruins, .throne: return .ruins
        case .shrine: return .shrine
        }
    }
}
