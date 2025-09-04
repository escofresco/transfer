import Foundation
import MusicKit
import SwiftUI

@MainActor
class AMAdapter: ObservableObject {
    @Published var playlists: [AMPlaylist] = []

    func requestAuthorization() async {
        let status = await MusicAuthorization.request()
        guard status == .authorized else {
            print("🚨 Apple Music authorization denied")
            return
        }
        await fetchUserPlaylists()
    }

    func fetchUserPlaylists() async {
        do {
            var request = MusicLibraryRequest<Playlist>()
            request.limit = 100
            let response = try await request.response()
            self.playlists = response.items.map { playlist in
                AMPlaylist(id: playlist.id.rawValue, name: playlist.name)
            }
        } catch {
            print("🚨 Could not fetch Apple Music playlists: \(error)")
        }
    }
}
