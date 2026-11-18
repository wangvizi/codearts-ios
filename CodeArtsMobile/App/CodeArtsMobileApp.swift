import SwiftUI

@main
struct CodeArtsMobileApp: App {
    @StateObject private var environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(environment)
                .tint(Theme.accent)
        }
    }
}