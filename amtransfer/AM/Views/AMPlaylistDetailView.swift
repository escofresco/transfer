import SwiftUI
import MusicKit

struct AMPlaylistDetailView: View {
    /// The Apple Music playlist to display.
    let playlist: AMPlaylist
    @State private var tracks: [AMTrack] = []
    @State private var isLoading = true

    var body: some View {
        List {
            if isLoading {
                ProgressView()
            } else if tracks.isEmpty {
                Text("No tracks in this playlist")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(tracks) { track in
                    VStack(alignment: .leading) {
                        Text(track.name)
                            .fontWeight(.semibold)
                        Text(track.artistNames)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle(playlist.name)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                BackButton()
            }
        }
        .task {
            await loadTracks()
        }
    }

    /// Loads the tracks for the playlist from the user's Apple Music library.
    private func loadTracks() async {
        do {
            let status = await MusicAuthorization.request()
            guard status == .authorized else {
                await MainActor.run { isLoading = false }
                return
            }

            let playlistID = MusicItemID(playlist.id)
            var request = MusicLibraryResourceRequest<Playlist>(matching: \.id, equalTo: playlistID)
            request.properties = [.tracks]

            let response = try await request.response()
            let fetched = response.items.first?.tracks ?? []

            let mapped = fetched.map { track in
                let artists = track.artists.map { AMArtist(name: $0.name) }
                return AMTrack(id: track.id.rawValue, name: track.title, artists: artists)
            }

            await MainActor.run {
                tracks = mapped
                isLoading = false
            }
        } catch {
            print("Failed to load Apple Music tracks: \(error)")
            await MainActor.run { isLoading = false }
        }
    }
}

#Preview {
    NavigationStack {
        AMPlaylistDetailView(playlist: AMPlaylist(id: "1", name: "Playlist"))
    }
}

