import Foundation

enum Tone: String, Codable {
    case normal, good, bad, story
}

struct LogEntry: Codable, Identifiable, Equatable {
    let id: Int
    let text: String
    let tone: Tone
}

/// Sound effects the game asks the app to play after an action.
enum Sound: String, Codable {
    case stepSoft, stepStone, search, pickup, coins, craft, drink, eat, equip
    case swing, hit, crit, block, hurt, sunbolt, awaken, levelUp, shrine
    case enemyAppear, shade, enemyDie, flee
}

struct InventoryEntry: Identifiable {
    let item: Item
    let count: Int
    var id: Item { item }
}

struct Combat: Codable {
    var enemy: Enemy
    var defending = false
}

/// The whole game state. A value type so it's easy to save, load and test.
struct Game: Codable {
    // World
    var position = World.start
    var visited: Set<Position> = [World.start]
    var minutes = 0
    var blessedShrines: Set<Position> = []

    // Player
    var health = 100
    var maxHealth = 100
    var hunger = 70
    var thirst = 55
    var energy = 100
    var mana = 0
    var maxMana = 0
    var level = 1
    var xp = 0
    var gold = 0
    var inventory: [Item: Int] = [:]
    var weapon: Item?
    var armor: Item?
    var isWizard = false

    // Flow
    var combat: Combat?
    var log: [LogEntry] = []
    var nextLogID = 0
    var deathCause: String?
    var hasWon = false
    /// Filled during an action, played and cleared by the app. Optional so older saves still load.
    var pendingSounds: [Sound]?

    init() {
        say("You wake in tall grass. No name. No food. No supplies.", .story)
        say("The sun hangs pale and weak, as if someone dimmed it.", .story)
        say("Lake to the east. Mountains to the south. It doesn't matter now. You need to survive.", .story)
    }

    // MARK: - Derived values

    var biome: Biome { World.biome(at: position) }
    var isDead: Bool { deathCause != nil }
    var isOver: Bool { isDead || hasWon }
    var hour: Int { (minutes / 60 + 6) % 24 }
    var day: Int { (minutes / 60 + 6) / 24 + 1 }
    var isNight: Bool { hour >= 20 || hour < 6 }
    var timeLabel: String {
        let phase: String
        switch hour {
        case 5..<12: phase = "Morning"
        case 12..<17: phase = "Afternoon"
        case 17..<20: phase = "Evening"
        default: phase = "Night"
        }
        return "Day \(day), \(phase)"
    }
    var xpToNext: Int { level * 50 }
    var attackPower: Int { (weapon?.attack ?? 3) + level }
    var defensePower: Int { armor?.defense ?? 0 }
    var shrineHere: Int? { World.shrines[position] }

    func count(_ item: Item) -> Int { inventory[item, default: 0] }

    var sortedInventory: [InventoryEntry] {
        Item.allCases.compactMap { item in
            let n = count(item)
            return n > 0 ? InventoryEntry(item: item, count: n) : nil
        }
    }

    // MARK: - Sound

    mutating func play(_ sound: Sound) {
        pendingSounds = (pendingSounds ?? []) + [sound]
    }

    // MARK: - Log

    mutating func say(_ text: String, _ tone: Tone = .normal) {
        log.append(LogEntry(id: nextLogID, text: text, tone: tone))
        nextLogID += 1
        if log.count > 80 { log.removeFirst(log.count - 80) }
    }

    // MARK: - Inventory

    mutating func add(_ item: Item, _ amount: Int = 1) {
        guard amount > 0 else { return }
        inventory[item, default: 0] += amount
    }

    @discardableResult
    mutating func remove(_ item: Item, _ amount: Int = 1) -> Bool {
        guard count(item) >= amount else { return false }
        let left = count(item) - amount
        inventory[item] = left > 0 ? left : nil
        if left == 0 {
            if weapon == item { weapon = nil }
            if armor == item { armor = nil }
        }
        return true
    }

    // MARK: - Time & survival

    /// Advances time and drains hunger/thirst/energy. Returns false if the player died.
    @discardableResult
    mutating func passTime(minutes elapsed: Int, hunger dh: Int, thirst dt: Int, energy de: Int) -> Bool {
        let wasNight = isNight
        minutes += elapsed
        hunger = max(0, hunger - dh)
        thirst = max(0, thirst - dt)
        energy = min(100, max(0, energy - de))

        if hunger == 0 {
            hurt(5, cause: "Starved to death")
            if !isDead { say("You are starving. Find food!", .bad) }
        } else if hunger < 20 {
            say("Your stomach aches with hunger.", .bad)
        }
        if thirst == 0 {
            hurt(6, cause: "Died of thirst")
            if !isDead { say("Your throat burns. You need water!", .bad) }
        } else if thirst < 20 {
            say("Your lips are cracked. You are very thirsty.", .bad)
        }
        if !isDead && hunger > 50 && thirst > 50 && health < maxHealth {
            health = min(maxHealth, health + 1)
        }
        if !wasNight && isNight { say("Night falls. The dark brings worse things out.", .story) }
        if wasNight && !isNight { say("Dawn breaks, thin and grey.", .story) }
        return !isDead
    }

    mutating func hurt(_ amount: Int, cause: String) {
        health = max(0, health - amount)
        if health == 0 && deathCause == nil {
            deathCause = cause
            combat = nil
            say("You fall. \(cause).", .bad)
        }
    }

    mutating func healBy(_ amount: Int) {
        health = min(maxHealth, health + amount)
    }

    // MARK: - Exploration

    func canMove(_ direction: Direction) -> Bool {
        World.contains(World.neighbor(of: position, toward: direction))
    }

    mutating func move(_ direction: Direction) {
        guard !isOver, combat == nil else { return }
        let next = World.neighbor(of: position, toward: direction)
        guard World.contains(next) else {
            say("The way \(direction.rawValue) is impassable.")
            return
        }
        let cost = World.biome(at: next) == .mountains ? 8 : 4
        guard energy >= cost else {
            say("You are too exhausted to travel. Rest first.", .bad)
            return
        }
        position = next
        play([.mountains, .ruins, .throne].contains(biome) ? .stepStone : .stepSoft)
        let firstVisit = visited.insert(next).inserted
        say("You travel \(direction.rawValue) to the \(biome.regionName).")
        if firstVisit { say(World.description(at: next), .story) }
        if isWizard { mana = min(maxMana, mana + 3) }
        guard passTime(minutes: 30, hunger: 2, thirst: 3, energy: cost) else { return }
        rollEncounter(chance: encounterChance)
    }

    var encounterChance: Double {
        var chance: Double
        switch biome {
        case .grassland: chance = 0.08
        case .forest: chance = 0.13
        case .lakeshore: chance = 0.08
        case .mountains: chance = 0.18
        case .ruins: chance = 0.25
        case .shrine, .throne: return 0
        }
        if isNight { chance += 0.12 }
        return chance
    }

    mutating func rollEncounter(chance: Double) {
        guard Double.random(in: 0..<1) < chance,
              let enemy = Bestiary.hostile(for: biome, night: isNight) else { return }
        startCombat(with: enemy, ambush: true)
    }

    mutating func search() {
        guard !isOver, combat == nil else { return }
        guard energy >= 5 else {
            say("You are too tired to search. Rest first.", .bad)
            return
        }
        var found: [(Item, Int)] = []
        let rolls = Double.random(in: 0..<1) < 0.4 ? 2 : 1
        for _ in 0..<rolls {
            if let drop = rollForage() { found.append(drop) }
        }
        if biome == .forest, weapon == .stoneAxe || count(.stoneAxe) > 0 {
            found.append((.wood, 1))
        }
        // Hidden items: rare finds that can mean the difference between life and death.
        if Double.random(in: 0..<1) < 0.08 {
            let hidden: [(Item, Int)] = [(.bandage, 1), (.fullWaterskin, 1), (.cookedMeat, 1), (.flint, 1)]
            if let pick = hidden.randomElement() {
                found.append(pick)
                say("Something glints beneath the undergrowth: a hidden \(pick.0.name)!", .good)
            }
        }
        if found.isEmpty {
            play(.search)
            say("You search the area but find nothing useful.")
        } else {
            play(.pickup)
            for (item, n) in found { add(item, n) }
            let text = found.map { "\($0.1) \($0.0.name)" }.joined(separator: ", ")
            say("You find: \(text).", .good)
        }
        if biome == .ruins, Double.random(in: 0..<1) < 0.3 {
            let coins = Int.random(in: 2...9)
            gold += coins
            play(.coins)
            say("Among the rubble you find \(coins) old gold coins.", .good)
        }
        guard passTime(minutes: 45, hunger: 2, thirst: 2, energy: 5) else { return }
        rollEncounter(chance: encounterChance / 2)
    }

    private func rollForage() -> (Item, Int)? {
        let table: [(Item, Int, ClosedRange<Int>)]
        switch biome {
        case .grassland: table = [(.fibre, 4, 1...3), (.berries, 3, 1...2), (.stone, 2, 1...1), (.flint, 1, 1...1)]
        case .forest: table = [(.wood, 5, 1...3), (.berries, 2, 1...2), (.mushroom, 3, 1...2), (.fibre, 2, 1...2)]
        case .lakeshore: table = [(.reeds, 3, 1...2), (.stone, 2, 1...2), (.flint, 2, 1...1), (.fibre, 1, 1...1)]
        case .mountains: table = [(.stone, 4, 1...3), (.flint, 3, 1...2), (.ironOre, 3, 1...2)]
        case .ruins: table = [(.ironOre, 2, 1...1), (.bandage, 1, 1...1), (.flint, 2, 1...1), (.wood, 2, 1...2)]
        case .shrine, .throne: return nil
        }
        if Double.random(in: 0..<1) < 0.15 { return nil }
        let total = table.reduce(0) { $0 + $1.1 }
        var roll = Int.random(in: 0..<total)
        for (item, weight, range) in table {
            if roll < weight { return (item, Int.random(in: range)) }
            roll -= weight
        }
        return nil
    }

    var canDrinkHere: Bool { biome == .lakeshore }

    mutating func drinkFromLake() {
        guard !isOver, combat == nil, canDrinkHere else { return }
        thirst = 100
        play(.drink)
        let empty = count(.waterskin)
        if empty > 0 {
            remove(.waterskin, empty)
            add(.fullWaterskin, empty)
            say("You drink deeply and fill \(empty) waterskin\(empty == 1 ? "" : "s").", .good)
        } else {
            say("You drink deeply from the cold lake. Your thirst is gone.", .good)
        }
        passTime(minutes: 10, hunger: 0, thirst: 0, energy: 0)
    }

    var canFish: Bool { biome == .lakeshore && count(.fishingRod) > 0 }

    mutating func fish() {
        guard !isOver, combat == nil, canFish else { return }
        guard energy >= 3 else {
            say("You are too tired to fish. Rest first.", .bad)
            return
        }
        if Double.random(in: 0..<1) < 0.55 {
            let n = Int.random(in: 1...2)
            add(.rawFish, n)
            play(.pickup)
            say("A tug on the line! You catch \(n) fish.", .good)
        } else {
            say("The fish aren't biting.")
        }
        guard passTime(minutes: 60, hunger: 2, thirst: 2, energy: 3) else { return }
        rollEncounter(chance: encounterChance / 2)
    }

    var canHunt: Bool { Bestiary.prey(for: biome) != nil }

    mutating func hunt() {
        guard !isOver, combat == nil else { return }
        guard energy >= 6 else {
            say("You are too tired to hunt. Rest first.", .bad)
            return
        }
        guard passTime(minutes: 45, hunger: 2, thirst: 3, energy: 6) else { return }
        if Double.random(in: 0..<1) < 0.25 {
            say("You track for a while, but find nothing to hunt.")
        } else if let prey = Bestiary.prey(for: biome) {
            startCombat(with: prey, ambush: false)
        }
    }

    mutating func rest() {
        guard !isOver, combat == nil else { return }
        let safe = biome == .shrine
        say(safe ? "You rest under the shrine's warm glow." : "You find a sheltered spot and rest.")
        healBy(safe ? 30 : 12)
        energy = min(100, energy + 45)
        if isWizard { mana = min(maxMana, mana + 20) }
        guard passTime(minutes: 180, hunger: 6, thirst: 8, energy: 0) else { return }
        if !safe, isNight || Double.random(in: 0..<1) < 0.3 {
            rollEncounter(chance: 0.2)
            if combat != nil { say("You're woken by a noise. Something has found you!", .bad) }
        }
    }

    // MARK: - Items

    mutating func use(_ item: Item) {
        guard !isOver, count(item) > 0 else { return }
        switch item.kind {
        case .weapon:
            weapon = item
            play(.equip)
            say("You equip the \(item.name).", .good)
        case .armor:
            armor = item
            play(.equip)
            say("You put on the \(item.name).", .good)
        case .food, .medicine, .drink:
            guard item.isConsumable else { return }
            remove(item)
            if item.food > 0 { hunger = min(100, hunger + item.food) }
            if item.water > 0 { thirst = min(100, thirst + item.water) }
            if item.heal > 0 { healBy(item.heal) }
            if item == .fullWaterskin { add(.waterskin) }
            play(item.kind == .food ? .eat : (item == .fullWaterskin ? .drink : .pickup))
            switch item {
            case .rawMeat, .rawFish:
                say("You eat the \(item.name). Your stomach churns.", .bad)
                hurt(4, cause: "Food poisoning")
            case .mushroom where Double.random(in: 0..<1) < 0.2:
                say("That mushroom was a bad one.", .bad)
                hurt(6, cause: "Poisoned by a mushroom")
            default:
                say("You use the \(item.name).", .good)
            }
            passTime(minutes: 5, hunger: 0, thirst: 0, energy: 0)
        case .material, .tool, .relic:
            say(item.info)
        }
    }

    func canCraft(_ recipe: Recipe) -> Bool {
        if let tool = recipe.tool, count(tool) == 0 { return false }
        return recipe.inputs.allSatisfy { count($0.item) >= $0.count }
    }

    mutating func craft(_ recipe: Recipe) {
        guard !isOver, combat == nil, canCraft(recipe) else { return }
        for input in recipe.inputs { remove(input.item, input.count) }
        add(recipe.output, recipe.amount)
        play(.craft)
        say("You craft \(recipe.amount > 1 ? "\(recipe.amount) " : "a ")\(recipe.output.name).", .good)
        passTime(minutes: 20, hunger: 1, thirst: 1, energy: 2)
    }

    // MARK: - Shrines & wizardry

    mutating func pray() {
        guard !isOver, combat == nil, let hintIndex = shrineHere else { return }
        play(.shrine)
        if blessedShrines.insert(position).inserted {
            add(.echoShard)
            health = maxHealth
            energy = 100
            say("Light pours from the shrine and fills you. You are fully restored.", .good)
            say("An Echo Shard forms in your palm. (\(count(.echoShard)) held)", .good)
        } else {
            healBy(15)
            say("The shrine's warmth soothes you.", .good)
        }
        say("A voice echoes: \(World.shrineHints[hintIndex])", .story)
        passTime(minutes: 30, hunger: 1, thirst: 1, energy: 0)
    }

    var canAwaken: Bool { !isWizard && shrineHere != nil && count(.echoShard) >= 3 }

    mutating func awaken() {
        guard canAwaken else { return }
        remove(.echoShard, 3)
        play(.awaken)
        isWizard = true
        maxMana = 40 + level * 5
        mana = maxMana
        say("The three shards melt into light and sink into your chest.", .story)
        say("You have become a Sun Wizard! You can now cast Sunbolt in battle.", .good)
    }

    // MARK: - The Hollow King

    var canChallengeKing: Bool { biome == .throne && !hasWon }

    mutating func challengeKing() {
        guard canChallengeKing, combat == nil else { return }
        say("The Hollow King rises from his throne. \"Another echo. You will fade like the rest.\"", .story)
        startCombat(with: Bestiary.hollowKing, ambush: false)
    }

    // MARK: - Combat

    static let sunboltCost = 15

    mutating func startCombat(with enemy: Enemy, ambush: Bool) {
        combat = Combat(enemy: enemy)
        if !enemy.isPrey { play(enemy.name == "Shade" ? .shade : .enemyAppear) }
        if enemy.isPrey {
            say("You spot a \(enemy.name). The hunt is on.")
        } else if ambush {
            say("A \(enemy.name) attacks!", .bad)
        } else {
            say("You face the \(enemy.name).", .bad)
        }
    }

    mutating func attack() {
        guard var fight = combat else { return }
        var damage = max(1, attackPower + Int.random(in: -2...3) - fight.enemy.defense)
        let crit = Double.random(in: 0..<1) < 0.1
        if crit { damage *= 2 }
        play(.swing)
        play(crit ? .crit : .hit)
        fight.enemy.health = max(0, fight.enemy.health - damage)
        fight.defending = false
        combat = fight
        say(crit ? "Critical hit! You strike the \(fight.enemy.name) for \(damage)." : "You hit the \(fight.enemy.name) for \(damage).", crit ? .good : .normal)
        finishPlayerTurn()
    }

    mutating func defend() {
        guard combat != nil else { return }
        combat?.defending = true
        play(.block)
        energy = min(100, energy + 3)
        say("You raise your guard.")
        finishPlayerTurn()
    }

    var canCastSunbolt: Bool { isWizard && mana >= Game.sunboltCost }

    mutating func castSunbolt() {
        guard var fight = combat, canCastSunbolt else { return }
        mana -= Game.sunboltCost
        play(.sunbolt)
        let damage = 16 + level * 3 + Int.random(in: 0...4)
        fight.enemy.health = max(0, fight.enemy.health - damage)
        fight.defending = false
        combat = fight
        say("A bolt of sunlight sears the \(fight.enemy.name) for \(damage)!", .good)
        finishPlayerTurn()
    }

    mutating func useInCombat(_ item: Item) {
        guard combat != nil, item.isConsumable, count(item) > 0 else { return }
        use(item)
        combat?.defending = false
        if !isDead { enemyTurn() }
    }

    mutating func flee() {
        guard let fight = combat else { return }
        if fight.enemy.isBoss {
            say("There is no escape from the Hollow King!", .bad)
            enemyTurn()
            return
        }
        if fight.enemy.isPrey {
            combat = nil
            say("You let the \(fight.enemy.name) go.")
            return
        }
        if Double.random(in: 0..<1) < 0.55 {
            combat = nil
            play(.flee)
            energy = max(0, energy - 5)
            say("You escape from the \(fight.enemy.name).")
        } else {
            say("You try to flee, but the \(fight.enemy.name) blocks your way!", .bad)
            enemyTurn()
        }
    }

    private mutating func finishPlayerTurn() {
        guard let fight = combat else { return }
        if fight.enemy.health <= 0 {
            win(against: fight.enemy)
        } else {
            enemyTurn()
        }
    }

    private mutating func enemyTurn() {
        guard let fight = combat else { return }
        if fight.enemy.isPrey && Double.random(in: 0..<1) < 0.25 {
            combat = nil
            say("The \(fight.enemy.name) bolts away and escapes.")
            return
        }
        var damage = max(0, fight.enemy.attack + Int.random(in: -2...2) - defensePower)
        if fight.defending { damage /= 2 }
        if damage == 0 {
            play(.block)
            say("The \(fight.enemy.name) attacks, but you take no damage.")
        } else {
            play(.hurt)
            say("The \(fight.enemy.name) hits you for \(damage).", .bad)
            hurt(damage, cause: "Slain by \(fight.enemy.name == "The Hollow King" ? "the Hollow King" : "a \(fight.enemy.name)")")
        }
        combat?.defending = false
    }

    private mutating func win(against enemy: Enemy) {
        combat = nil
        play(.enemyDie)
        say(enemy.isPrey ? "You bring down the \(enemy.name)." : "You defeat the \(enemy.name)!", .good)
        var drops: [String] = []
        for drop in enemy.loot where Double.random(in: 0..<1) < drop.chance {
            let n = Int.random(in: drop.min...drop.max)
            add(drop.item, n)
            drops.append("\(n) \(drop.item.name)")
        }
        let coins = Int.random(in: enemy.goldMin...enemy.goldMax)
        if coins > 0 {
            play(.coins)
            gold += coins
            drops.append("\(coins) gold")
        }
        if !drops.isEmpty { say("You take: \(drops.joined(separator: ", ")).", .good) }
        gainXP(enemy.xp)
        if enemy.isBoss {
            hasWon = true
            say("The Hollow King crumbles to ash. Above you, the sun flares bright and warm for the first time in an age.", .story)
            say("Humanity has a chance again, because of you.", .story)
        }
    }

    mutating func gainXP(_ amount: Int) {
        xp += amount
        say("+\(amount) XP")
        while xp >= xpToNext {
            xp -= xpToNext
            level += 1
            play(.levelUp)
            maxHealth += 10
            healBy(20)
            if isWizard {
                maxMana += 5
                mana = maxMana
            }
            say("Level up! You are now level \(level).", .good)
        }
    }
}
