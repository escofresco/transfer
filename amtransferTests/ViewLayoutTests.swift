import Testing
import SwiftUI
import UIKit
@testable import amtransfer

@MainActor
struct ViewLayoutTests {
    private func assertFillsScreen<V: View>(_ view: V) {
        let controller = UIHostingController(rootView: view)
        let screenSize = UIScreen.main.bounds.size == .zero ? CGSize(width: 390, height: 844) : UIScreen.main.bounds.size
        controller.view.frame = CGRect(origin: .zero, size: screenSize)
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        let hostedSize = controller.view.subviews.first?.bounds.size ?? .zero
        let expectedHeight = screenSize.height - controller.view.safeAreaInsets.top
        let expectedSize = CGSize(width: screenSize.width, height: expectedHeight)
        #expect(hostedSize == expectedSize)
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
