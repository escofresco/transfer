import SwiftUI
import MusicKit

struct AMLibraryView: View {

    /// Playlists from the user's Apple Music library.
    @State private var libraryPlaylists: [AMPlaylist] = []
    @State private var isLoading = true
    /// Newly written playlists so they can be undone.
    @State private var writtenPlaylists: [Playlist] = []

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
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button("Write") {
                    Task { await writeSelectedPlaylists() }
                }
                .disabled(selectedPlaylists.isEmpty)

                Button("Undo") {
                    Task { await undoWrittenPlaylists() }
                }
                .disabled(writtenPlaylists.isEmpty)
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

    /// Writes the selected playlists to the user's Apple Music library.
    private func writeSelectedPlaylists() async {
        for playlist in selectedPlaylists {
            do {
                let created = try await MusicLibrary.shared.createPlaylist(
                    name: playlist.name,
                    tracks: MusicItemCollection<Track>()
                )
                await MainActor.run {
                    writtenPlaylists.append(created)
                    libraryPlaylists.append(AMPlaylist(id: created.id.rawValue, name: created.name))
                }
            } catch {
                print("Failed to write playlist to library: \(error)")
            }
        }
    }

    /// Removes any playlists written during this session from the library.
    private func undoWrittenPlaylists() async {
        for playlist in writtenPlaylists {
            do {
                try await MusicLibrary.shared.deletePlaylist(playlist)
                await MainActor.run {
                    libraryPlaylists.removeAll { $0.id == playlist.id.rawValue }
                }
            } catch {
                print("Failed to remove playlist from library: \(error)")
            }
        }
        await MainActor.run { writtenPlaylists.removeAll() }
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
