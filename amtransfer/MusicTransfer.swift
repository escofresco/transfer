import SwiftUI

@main
struct MusicTransfer: App {
    var body: some Scene {
        WindowGroup {
            ContentView().task {
                await runTests()
            }
        }
    }
}
