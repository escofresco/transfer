import SwiftUI
import MusicKit

struct AMLibraryView: View {

    /// Adapter used to fetch tracks from Spotify playlists.
    @ObservedObject var spotify: SpotifyAdapter

    /// Playlists from the user's Apple Music library.
    @State private var libraryPlaylists: [AMPlaylist] = []
    @State private var isLoading = true
    @State private var errorMessage: String? = nil

    /// Indicates whether a transfer operation is currently running.
    @State private var isTransferring = false

    /// Message shown after a transfer completes or fails.
    @State private var transferMessage: String? = nil

    /// Playlists selected from the Spotify logged in view.
    let selectedPlaylists: [AMPlaylist]

    var body: some View {
        VStack {
            List {
                Section("My Playlists") {
                    if isLoading {
                        ProgressView()
                    } else if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
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

            if isTransferring {
                ProgressView("Transferring...")
                    .padding(.vertical)
            }

            if let transferMessage {
                Text(transferMessage)
                    .foregroundStyle(.secondary)
            }

            Button("Transfer Selected Playlists") {
                Task {
                    await transferSelectedPlaylists()
                }
            }
            .disabled(isTransferring || selectedPlaylists.isEmpty)
            .padding(.vertical)
        }
        .padding(.top, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationTitle("Library")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                BackButton()
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

            let subscription = try await MusicSubscription.current
            guard subscription.canPlayCatalogContent else {
                await MainActor.run {
                    errorMessage = "Apple Music subscription required"
                    isLoading = false
                }
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
            await MainActor.run {
                if error.localizedDescription.contains("MusicIdentifierSet: Unable to create a valid cloud resource identifier for MusicIdentifierSet") {
                    errorMessage = "Apple Music subscription required"
                } else {
                    errorMessage = "Failed to load Apple Music playlists"
                }
                isLoading = false
            }
        }
    }

    /// Transfers the selected Spotify playlists into the user's Apple Music library.
    /// Each Spotify playlist is matched track by track using a simple search and
    /// then recreated as a new playlist in Apple Music.
    private func transferSelectedPlaylists() async {
        await MainActor.run {
            isTransferring = true
            transferMessage = nil
        }

        do {
            for playlist in selectedPlaylists {
                let tracks = await spotify.getTracks(for: playlist.id)
                var trackIDs: [MusicItemID] = []

                for track in tracks {
                    let term = "\(track.name) \(track.artistNames)"
                    var search = MusicCatalogSearchRequest(term: term, types: [Song.self])
                    search.limit = 1
                    let response = try await search.response()
                    if let song = response.songs.first {
                        trackIDs.append(song.id)
                    }
                }

                if !trackIDs.isEmpty {
                    var create = PlaylistCreationRequest(name: playlist.name, trackIDs: trackIDs)
                    _ = try await create.response()
                }
            }

            await MainActor.run {
                transferMessage = "Transfer complete"
            }
        } catch {
            await MainActor.run {
                transferMessage = "Failed to transfer playlists"
            }
        }

        await MainActor.run {
            isTransferring = false
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
