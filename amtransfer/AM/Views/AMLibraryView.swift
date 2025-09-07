import SwiftUI
import MusicKit

struct AMLibraryView: View {

    /// Playlists from the user's Apple Music library.
    @State private var libraryPlaylists: [AMPlaylist] = []
    @State private var isLoading = true
    @State private var isTransferring = false

    /// Spotify adapter used to fetch playlist tracks.
    @ObservedObject var spotify: SpotifyAdapter

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
            let spotifyTracks = await spotify.getTracks(for: playlist.id)

            var songIDs: [MusicItemID] = []
            for track in spotifyTracks {
                let term = "\(track.name) \(track.artistNames)"
                var request = MusicCatalogSearchRequest(term: term, types: [Song.self])
                if let response = try? await request.response(),
                   let song = response.songs.first {
                    songIDs.append(song.id)
                }
            }

            guard !songIDs.isEmpty else { continue }

            var createRequest = MusicLibraryPlaylistCreationRequest(
                attributes: .init(name: playlist.name,
                                  description: "Imported from Spotify")
            )
            createRequest.relationships.tracks = .init(data: songIDs)

            do {
                _ = try await createRequest.response()
                print("Created playlist \(playlist.name)")
            } catch {
                print("Failed to create playlist \(playlist.name): \(error)")
            }
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
