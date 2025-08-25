import Testing
import SwiftUI
@testable import amtransfer

struct BackButtonTests {
    @Test func backButtonHasChevronAndText() {
        let backButton = BackButton()
        let bodyMirror = Mirror(reflecting: backButton.body)
        guard let label = bodyMirror.descendant("label") else {
            Issue.record("Label not found")
            return
        }
        let labelMirror = Mirror(reflecting: label)
        let title = labelMirror.descendant("title") as? Text
        let icon = labelMirror.descendant("icon") as? Image
        #expect(String(describing: title) == "Text(\"Back\")")
        #expect(String(describing: icon) == "Image(systemName: \"chevron.left\")")
    }

    @Test func backButtonDismisses() {
        var didDismiss = false
        let view = BackButton().environment(\.dismiss, DismissAction { didDismiss = true })
        let mirror = Mirror(reflecting: view)
        // try to pull out underlying Button
        let button = mirror.descendant("content") ?? mirror.descendant("modifier", "content")
        guard let unwrappedButton = button else {
            Issue.record("Button not found")
            return
        }
        let actionMirror = Mirror(reflecting: unwrappedButton)
        guard let action = actionMirror.descendant("action") as? () -> Void else {
            Issue.record("Action not accessible")
            return
        }
        action()
        #expect(didDismiss)
    }
}
