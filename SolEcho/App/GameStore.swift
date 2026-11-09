import Foundation
import Observation
import UIKit

/// Owns the current game, saves it after every action and reads new log lines to VoiceOver.
@Observable
final class GameStore {
    private(set) var game: Game?
    private(set) var hasSave: Bool

    private let saveKey = "solecho.save.v1"

    init() {
        hasSave = UserDefaults.standard.data(forKey: saveKey) != nil
        AudioManager.shared.update(for: nil)
    }

    func newGame() {
        let fresh = Game()
        game = fresh
        AudioManager.shared.update(for: fresh)
        save()
        announce(fresh.log.map(\.text).joined(separator: " "))
    }

    func continueGame() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let saved = try? JSONDecoder().decode(Game.self, from: data) else {
            deleteSave()
            return
        }
        game = saved
        AudioManager.shared.update(for: saved)
    }

    func quitToTitle() {
        game = nil
        AudioManager.shared.update(for: nil)
    }

    /// Runs a game action, saves, and announces whatever happened.
    func perform(_ action: (inout Game) -> Void) {
        guard var current = game else { return }
        let firstNewID = current.nextLogID
        action(&current)
        let sounds = current.pendingSounds ?? []
        current.pendingSounds = nil
        game = current
        AudioManager.shared.play(sounds)
        AudioManager.shared.update(for: current)
        let news = current.log.filter { $0.id >= firstNewID }.map(\.text)
        if !news.isEmpty { announce(news.joined(separator: " ")) }
        if current.isOver {
            deleteSave()
        } else {
            save()
        }
    }

    private func save() {
        guard let game, let data = try? JSONEncoder().encode(game) else { return }
        UserDefaults.standard.set(data, forKey: saveKey)
        hasSave = true
    }

    private func deleteSave() {
        UserDefaults.standard.removeObject(forKey: saveKey)
        hasSave = false
    }

    private func announce(_ text: String) {
        guard UIAccessibility.isVoiceOverRunning else { return }
        // A short delay lets the button's own feedback finish first.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            UIAccessibility.post(notification: .announcement, argument: text)
        }
    }
}
