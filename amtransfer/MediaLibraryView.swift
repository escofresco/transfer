import SwiftUI

/// A simple library view combining existing media and selected Spotify playlists.
struct MediaLibraryView: View {
    /// Mock existing library items provided by the app.
    var existingItems: [String]

    /// Spotify playlists chosen in `LoggedInView`.
    var playlists: [SpotifyPlaylist]

    var body: some View {
        NavigationStack {
            List {
                Section("Your Library") {
                    ForEach(existingItems, id: \.self) { item in
                        Text(item)
                    }
                }

                if !playlists.isEmpty {
                    Section("Spotify Playlists") {
                        ForEach(playlists) { playlist in
                            Text(playlist.name)
                        }
                    }
                }
            }
            .navigationTitle("Library")
        }
    }
}

#Preview {
    MediaLibraryView(
        existingItems: ["Local Album", "Downloaded Track"],
        playlists: [
            .init(id: "1", name: "Mock Playlist")
        ]
    )
}
