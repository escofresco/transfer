import SwiftUI
import MusicKit

@MainActor
class AMAdapter: ObservableObject {
    @Published var playlists: [AMPlaylist] = []

    func fetchUserPlaylists() async {
        let status = await MusicAuthorization.request()
        guard status == .authorized else {
            print("Apple Music authorization not granted.")
            return
        }

        do {
            let request = MusicLibraryRequest<Playlist>()
            let response = try await request.response()
            playlists = response.items.map { AMPlaylist(id: $0.id.rawValue, name: $0.name) }
        } catch {
            print("Failed to load user playlists: \(error)")
        }
    }
}
