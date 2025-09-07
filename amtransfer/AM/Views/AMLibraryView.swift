import SwiftUI
import MusicKit

struct AMLibraryView: View {

    /// Playlists from the user's Apple Music library.
    @State private var libraryPlaylists: [AMPlaylist] = []
    @State private var isLoading = true
    @State private var isTransferring = false

    /// Playlists selected from the Spotify logged in view.
    let selectedPlaylists: [AMPlaylist]

    /// Spotify adapter used to fetch playlist tracks from the user's account.
    @ObservedObject var spotify: SpotifyAdapter

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
            #if os(macOS)
            ToolbarItem(placement: .primaryAction) {
                Button("Transfer") {}
                    .disabled(true)
            }
            #else
            ToolbarItem(placement: .primaryAction) {
                Button("Transfer") {
                    Task { await transferSelectedPlaylists() }
                }
                .disabled(isTransferring || selectedPlaylists.isEmpty)
            }
            #endif
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

    /// Transfers the selected Spotify playlists to the user's Apple Music library.
    private func transferSelectedPlaylists() async {
        guard !selectedPlaylists.isEmpty else { return }

        await MainActor.run { isTransferring = true }
        defer { Task { await MainActor.run { isTransferring = false } } }

        for playlist in selectedPlaylists {
            do {
                // Fetch tracks from the Spotify playlist.
                let tracks = await spotify.getTracks(for: playlist.id)

                // Find the best matching Apple Music songs for each track.
                var songs: [Song] = []
                for track in tracks {
                    var request = MusicCatalogSearchRequest(
                        term: "\(track.name) \(track.artistNames)",
                        types: [Song.self]
                    )
                    request.limit = 1
                    if let match = try? await request.response().songs.first {
                        songs.append(match)
                    }
                }

                // Create a new playlist in the user's Apple Music library.
                let newPlaylist = try await MusicLibrary.shared.createPlaylist(
                    name: playlist.name,
                    description: nil
                )

                // Add the matched songs to the newly created playlist.
                for song in songs {
                    try await MusicLibrary.shared.add(song, to: newPlaylist)
                }

                print("Transferred playlist: \(playlist.name) with \(songs.count) tracks")
            } catch {
                print("Failed to transfer playlist \(playlist.name): \(error)")
            }
        }

        // Refresh the library playlists after transfer completes.
        await loadLibraryPlaylists()
    }
}

#Preview {
    NavigationStack {
        AMLibraryView(
            selectedPlaylists: [
                AMPlaylist(id: "1", name: "Chill Vibes"),
                AMPlaylist(id: "2", name: "Workout Mix")
            ],
            spotify: SpotifyAdapter()
        )
    }
}
