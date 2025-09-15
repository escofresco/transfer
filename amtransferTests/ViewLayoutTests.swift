import Testing
import SwiftUI
import UIKit
@testable import amtransfer

@MainActor
struct ViewLayoutTests {
    private func assertFillsScreen<V: View>(_ view: V, file: StaticString = #file, line: UInt = #line) {
        let controller = UIHostingController(rootView: view)
        let screenSize = UIScreen.main.bounds.size == .zero ? CGSize(width: 390, height: 844) : UIScreen.main.bounds.size
        controller.view.frame = CGRect(origin: .zero, size: screenSize)
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        let hostedSize = controller.view.subviews.first?.bounds.size ?? .zero
        #expect(hostedSize == screenSize, file: file, line: line)
    }

    @Test func contentViewFillsScreen() {
        assertFillsScreen(ContentView())
    }

    @Test func loginViewFillsScreen() {
        assertFillsScreen(LoginView(spotify: SpotifyAdapter(), pastedURL: .constant("")))
    }

    @Test func loggedInViewFillsScreen() {
        assertFillsScreen(LoggedInView(spotify: SpotifyAdapter()))
    }

    @Test func amLibraryViewFillsScreen() {
        assertFillsScreen(AMLibraryView(selectedPlaylists: []))
    }
}
