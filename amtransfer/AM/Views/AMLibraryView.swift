import SwiftUI
import MusicKit

struct AMLibraryView: View {

    /// Playlists from the user's Apple Music library.
    @State private var libraryPlaylists: [AMPlaylist] = []
    @State private var isLoading = true
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

                    if isTransferring {
                        ProgressView()
                    } else {
                        Button("Transfer Selected Playlists") {
                            Task {
                                await transferSelectedPlaylists()
                            }
                        }
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

    /// Creates the selected playlists in the user's Apple Music library.
    private func transferSelectedPlaylists() async {
        await MainActor.run { isTransferring = true }
        defer { Task { await MainActor.run { isTransferring = false } } }

        for playlist in selectedPlaylists {
            do {
                try await MusicLibrary.shared.createPlaylist(
                    name: playlist.name,
                    description: "Transferred from Spotify",
                    tracks: []
                )
            } catch {
                print("Failed to create playlist \(playlist.name): \(error)")
            }
        }

        await loadLibraryPlaylists()
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
