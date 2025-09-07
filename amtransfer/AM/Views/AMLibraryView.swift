import SwiftUI
import MusicKit

struct AMLibraryView: View {

    /// Provides access to the user's Spotify data for fetching tracks.
    @ObservedObject var spotify: SpotifyAdapter

    /// Playlists from the user's Apple Music library.
    @State private var libraryPlaylists: [AMPlaylist] = []
    @State private var isLoading = true

    /// Indicates that a transfer is currently running.
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
                Button("Transfer") {
                    Task { await transferSelectedPlaylists() }
                }
                .disabled(selectedPlaylists.isEmpty || isTransferring)
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

    /// Transfers the selected Spotify playlists into the user's Apple Music library.
    private func transferSelectedPlaylists() async {
        guard !selectedPlaylists.isEmpty else { return }

        isTransferring = true
        defer { isTransferring = false }

        do {
            let status = await MusicAuthorization.request()
            guard status == .authorized else { return }

            for playlist in selectedPlaylists {
                // Fetch tracks from Spotify for each selected playlist.
                let tracks = await spotify.getTracks(for: playlist.id)

                // Attempt to match each Spotify track in the Apple Music catalog.
                var songs: [Song] = []
                for track in tracks {
                    let term = "\(track.name) \(track.artistNames)"
                    var search = MusicCatalogSearchRequest(term: term, types: [Song.self])
                    search.limit = 1
                    if let song = try? await search.response().songs.first {
                        songs.append(song)
                    }
                }

                // Create a new playlist and add the matched songs.
                var creationRequest = PlaylistCreationRequest(
                    name: playlist.name,
                    description: "Transferred from Spotify"
                )
                if !songs.isEmpty {
                    creationRequest.add(items: songs)
                }
                _ = try await MusicLibrary.shared.createPlaylist(creationRequest)
            }

            // Refresh the user's library playlists after transfer.
            await loadLibraryPlaylists()
        } catch {
            print("Failed to transfer playlists: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        AMLibraryView(
            spotify: SpotifyAdapter(),
            selectedPlaylists: [
                AMPlaylist(id: "1", name: "Chill Vibes"),
                AMPlaylist(id: "2", name: "Workout Mix")
            ]
        )
    }
}
