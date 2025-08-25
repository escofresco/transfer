import SwiftUI

/// A reusable back button with a leading chevron and "Back" label.
///
/// This view dismisses the current presentation when tapped and can be
/// reused across screens that require a custom back navigation button.
struct BackButton: View {
    @Environment(\.dismiss) private var dismiss
    private let handler: (() -> Void)?

    init(handler: (() -> Void)? = nil) {
        self.handler = handler
    }

    /// Invokes the button's action. Exposed internally so tests can trigger
    /// the action without relying on SwiftUI internals.
    func performAction() {
        if let handler {
            handler()
        } else {
            dismiss()
        }
    }

    var body: some View {
        Button(action: performAction) {
            Label("Back", systemImage: "chevron.left")
        }
    }
}

