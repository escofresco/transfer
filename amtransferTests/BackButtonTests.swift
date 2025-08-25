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
        guard let title = labelMirror.descendant("title") as? Text else {
            Issue.record("Title not found")
            return
        }
        guard let icon = labelMirror.descendant("icon") as? Image else {
            Issue.record("Icon not found")
            return
        }
        #expect(String(describing: title).contains("Back"))
        let iconMirror = Mirror(reflecting: icon)
        let iconName = iconMirror.descendant("provider", "base", "name") as? String
        #expect(iconName == "chevron.left")
    }

    @Test func backButtonDismisses() {
        var didDismiss = false
        let backButton = BackButton(handler: { didDismiss = true })
        backButton.performAction()
        #expect(didDismiss)
    }
}
