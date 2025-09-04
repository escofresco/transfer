import SwiftUI

struct AMLibraryView: View {
    @StateObject private var appleMusic = AMAdapter()

    /// Playlists selected from the Spotify logged in view.
    let selectedPlaylists: [AMPlaylist]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("My Playlists")
                        .font(.headline)

                    if appleMusic.playlists.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        ForEach(appleMusic.playlists) { playlist in
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
            .padding(.top, 8)
            .padding(.horizontal)
        }
        .navigationTitle("Library")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                BackButton()
            }
        }
        .task {
            await appleMusic.requestAuthorization()
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
