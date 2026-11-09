import SwiftUI

@main
struct SolEchoApp: App {
    @State private var store = GameStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .preferredColorScheme(.dark)
                .tint(.orange)
        }
    }
}
