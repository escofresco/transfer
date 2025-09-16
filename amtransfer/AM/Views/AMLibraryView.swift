import SwiftUI
import MusicKit

struct AMLibraryView: View {

    /// Playlists from the user's Apple Music library.
    @State private var libraryPlaylists: [AMPlaylist] = []
    @State private var isLoading = true
    @State private var errorMessage: String? = nil

    /// Playlists selected from the Spotify logged in view.
    let selectedPlaylists: [AMPlaylist]

    var body: some View {
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
                        NavigationLink(playlist.name) {
                            AMPlaylistDetailView(playlist: playlist)
                        }
                    }
                }
            }

            Section("Selected Playlists") {
                if selectedPlaylists.isEmpty {
                    Text("No playlists selected")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(selectedPlaylists) { playlist in
                        NavigationLink(playlist.name) {
                            AMPlaylistDetailView(playlist: playlist)
                        }
                    }
                }
            }
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
}

#Preview {
    NavigationStack {
        AMLibraryView(selectedPlaylists: [
            AMPlaylist(id: "1", name: "Chill Vibes"),
            AMPlaylist(id: "2", name: "Workout Mix")
        ])
    }
}
