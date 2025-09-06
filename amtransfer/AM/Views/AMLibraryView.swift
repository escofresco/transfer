import SwiftUI
import MusicKit

struct AMLibraryView: View {

    /// Playlists from the user's Apple Music library.
    @State private var libraryPlaylists: [AMPlaylist] = []
    @State private var isLoading = true

    /// Playlists that were written in this session so the action can be undone.
    @State private var writtenPlaylists: [AMPlaylist] = []
    @State private var isWriting = false

    /// Playlists selected from the Spotify logged in view.
    let selectedPlaylists: [AMPlaylist]

    var body: some View {
        VStack {
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

            if !selectedPlaylists.isEmpty {
                Button(writtenPlaylists.isEmpty ? "Write to Library" : "Undo Write") {
                    Task {
                        if writtenPlaylists.isEmpty {
                            await writeSelectedPlaylists()
                        } else {
                            await undoWrittenPlaylists()
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding()
                .disabled(isWriting)
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

    /// Writes the selected playlists to the user's Apple Music library.
    private func writeSelectedPlaylists() async {
        guard !selectedPlaylists.isEmpty else { return }
        isWriting = true
        let playlists = selectedPlaylists.map { Playlist(id: MusicItemID(rawValue: $0.id)) }

        do {
            try await MusicLibrary.shared.add(playlists)
            await MainActor.run {
                let newPlaylists = selectedPlaylists.filter { !libraryPlaylists.contains($0) }
                libraryPlaylists.append(contentsOf: newPlaylists)
                writtenPlaylists = newPlaylists
                isWriting = false
            }
        } catch {
            print("Failed to write playlists: \(error)")
            await MainActor.run { isWriting = false }
        }
    }

    /// Removes previously written playlists from the user's Apple Music library.
    private func undoWrittenPlaylists() async {
        guard !writtenPlaylists.isEmpty else { return }
        isWriting = true
        let playlists = writtenPlaylists.map { Playlist(id: MusicItemID(rawValue: $0.id)) }

        do {
            try await MusicLibrary.shared.delete(playlists)
            await MainActor.run {
                libraryPlaylists.removeAll { writtenPlaylists.contains($0) }
                writtenPlaylists.removeAll()
                isWriting = false
            }
        } catch {
            print("Failed to undo playlists: \(error)")
            await MainActor.run { isWriting = false }
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
