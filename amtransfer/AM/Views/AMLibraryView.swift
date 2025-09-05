import SwiftUI
import MusicKit

struct AMLibraryView: View {

    @StateObject private var adapter = AMAdapter()

    /// Playlists selected from the Spotify logged in view.
    let selectedPlaylists: [AMPlaylist]

    var body: some View {
        List {
            Section("My Playlists") {
                if adapter.playlists.isEmpty {
                    if adapter.authorizationStatus == .authorized {
                        ProgressView()
                    } else {
                        Text("Authorize Apple Music to view playlists")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ForEach(adapter.playlists) { playlist in
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
        }
        .task {
            await adapter.setup()
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
