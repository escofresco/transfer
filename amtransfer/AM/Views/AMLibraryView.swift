import SwiftUI

struct AMLibraryView: View {

    /// Adapter responsible for interacting with Apple Music APIs.
    @StateObject private var music = AMAdapter()

    /// Playlists selected from the Spotify logged in view.
    let selectedPlaylists: [AMPlaylist]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("My Playlists")
                        .font(.headline)

                    if music.playlists.isEmpty {
                        ProgressView()
                    } else {
                        ForEach(music.playlists) { playlist in
                            Text(playlist.name)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Selected Playlists")
                        .font(.headline)

                    if selectedPlaylists.isEmpty {
                        Text("No playlists selected")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(selectedPlaylists) { playlist in
                            Text(playlist.name)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .padding()
            .padding(.top, 8)
        }
        .navigationTitle("Library")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                BackButton()
            }
        }
        .task {
            await music.setup()
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
