import SwiftUI

struct LibraryView: View {

    /// Mock playlists representing existing user content.
    private let mockPlaylists = [
        SpotifyPlaylist(id: "m1", name: "Favourites"),
        SpotifyPlaylist(id: "m2", name: "Road Trip")
    ]

    /// Playlists selected from the Spotify logged in view.
    let selectedPlaylists: [SpotifyPlaylist]

    var body: some View {
        List {
            Section("My Playlists") {
                ForEach(mockPlaylists) { playlist in
                    Text(playlist.name)
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
        .padding(.top, 8)
        .navigationTitle("Library")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                BackButton()
            }
        }
    }
}

#Preview {
    NavigationStack {
        LibraryView(selectedPlaylists: [
            SpotifyPlaylist(id: "1", name: "Chill Vibes"),
            SpotifyPlaylist(id: "2", name: "Workout Mix")
        ])
    }
}
