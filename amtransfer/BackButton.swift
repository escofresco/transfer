import SwiftUI

/// A reusable back button with a leading chevron and "Back" label.
///
/// This view dismisses the current presentation when tapped and can be
/// reused across screens that require a custom back navigation button.
struct BackButton: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button(action: { dismiss() }) {
            Label("Back", systemImage: "chevron.left")
        }
    }
}

