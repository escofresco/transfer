import SwiftUI

struct AMLibraryView: View {

    /// Mock playlists representing existing user content.
    private let mockPlaylists = [
        AMPlaylist(id: "m1", name: "Favourites"),
        AMPlaylist(id: "m2", name: "Road Trip")
    ]

    /// Playlists selected from the Spotify logged in view.
    let selectedPlaylists: [AMPlaylist]

    var body: some View {
        List {
            Section("My Playlists") {
                ForEach(mockPlaylists) { playlist in
                    Text(playlist.name)
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
