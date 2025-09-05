import Foundation
import MusicKit

@MainActor
class AMAdapter: ObservableObject {
    @Published var playlists: [AMPlaylist] = []
    @Published var authorizationStatus: MusicAuthorization.Status = .notDetermined

    /// Requests MusicKit authorization and loads the user's library playlists
    func setup() async {
        let status = await MusicAuthorization.request()
        authorizationStatus = status
        guard status == .authorized else {
            return
        }
        await loadPlaylists()
    }

    /// Fetches the user's Apple Music library playlists
    private func loadPlaylists() async {
        do {
            var request = MusicLibraryRequest<Playlist>()
            request.limit = 100
            let response = try await request.response()
            playlists = response.items.map { AMPlaylist(id: $0.id.rawValue, name: $0.name) }
        } catch {
            print("🚨 Could not load Apple Music playlists: \(error)")
        }
    }
}
