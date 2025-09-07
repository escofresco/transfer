import SwiftUI
import MusicKit
import Foundation

struct AMLibraryView: View {

    /// Playlists from the user's Apple Music library.
    @State private var libraryPlaylists: [AMPlaylist] = []
    @State private var isLoading = true
    @State private var isTransferring = false

    /// Playlists selected from the Spotify logged in view.
    let selectedPlaylists: [AMPlaylist]

    var body: some View {
        List {
            Section("My Playlists") {
                if isLoading {
                    ProgressView()
                } else if libraryPlaylists.isEmpty {
                    Text("No playlists in library")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(libraryPlaylists) { playlist in
                        Text(playlist.name)
                    }
                }
            }

            Section("Selected Playlists") {
                if selectedPlaylists.isEmpty {
                    Text("No playlists selected")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(selectedPlaylists) { playlist in
                        Text(playlist.name)
                    }
                }
            }
        }
        .padding(.top, 8)
        .navigationTitle("Library")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                BackButton()
            }
            ToolbarItem(placement: .primaryAction) {
                if !selectedPlaylists.isEmpty {
                    Button("Transfer Selected") {
                        Task { await transferSelectedPlaylists() }
                    }
                    .disabled(isTransferring)
                }
            }
        }
        .task {
            await loadLibraryPlaylists()
        }
    }

    /// Requests MusicKit authorization and loads the user's playlists.
    private func loadLibraryPlaylists() async {
        do {
            let status = await MusicAuthorization.request()
            guard status == .authorized else {
                await MainActor.run { isLoading = false }
                return
            }

            let request = MusicLibraryRequest<Playlist>()
            let response = try await request.response()
            let fetched = response.items.map { AMPlaylist(id: $0.id.rawValue, name: $0.name) }

            await MainActor.run {
                libraryPlaylists = fetched
                isLoading = false
            }
        } catch {
            print("Failed to load Apple Music playlists: \(error)")
            await MainActor.run { isLoading = false }
        }
    }

    /// Adds the selected playlists to the user's Apple Music library on macOS
    /// by executing an AppleScript command for each playlist identifier.
    private func transferSelectedPlaylists() async {
        guard !selectedPlaylists.isEmpty else { return }
        await MainActor.run { isTransferring = true }

        for playlist in selectedPlaylists {
            await runAppleScript(for: playlist)
        }

        await MainActor.run { isTransferring = false }
    }

    /// Executes an AppleScript snippet that subscribes to the playlist with the
    /// provided identifier. This approach is used instead of MusicKit because
    /// it works on macOS without needing additional entitlements.
    private func runAppleScript(for playlist: AMPlaylist) async {
        let script = """
        tell application "Music"
            try
                subscribe playlist id "\(playlist.id)"
            on error errMsg
                return errMsg
            end try
        end tell
        """

        await withCheckedContinuation { continuation in
            let task = Process()
            task.launchPath = "/usr/bin/osascript"
            task.arguments = ["-e", script]
            task.terminationHandler = { _ in continuation.resume() }
            do {
                try task.run()
            } catch {
                print("AppleScript execution failed: \(error)")
                continuation.resume()
            }
        }
    }
}

#Preview {
    NavigationStack {
        AMLibraryView(selectedPlaylists: [
            AMPlaylist(id: "1", name: "Chill Vibes"),
            AMPlaylist(id: "2", name: "Workout Mix")
        ])
    }
}
