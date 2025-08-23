import SwiftUI

struct LibraryView: View {
    /// Mock existing library items.
    private let existingItems = ["Local Song 1", "Local Song 2", "Podcast Episode"]

    /// Playlists selected from the Spotify logged in view.
    let selectedPlaylists: [SpotifyPlaylist]

    var body: some View {
        List {
            Section("My Library") {
                ForEach(existingItems, id: \.self) { item in
                    Text(item)
                }
            }

            Section("Selected Spotify Playlists") {
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
        .navigationTitle("Library")
    }
}

#Preview {
    LibraryView(selectedPlaylists: [
        SpotifyPlaylist(id: "1", name: "Chill Vibes"),
        SpotifyPlaylist(id: "2", name: "Workout Mix")
    ])
}
