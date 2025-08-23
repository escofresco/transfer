import Foundation

struct SpotifyPlaylist: Codable, Identifiable, Hashable {
    let id: String
    let name: String
}

struct PlaylistsResponse: Codable {
    let items: [SpotifyPlaylist]
}

struct PlaylistTracksResponse: Codable {
    struct Item: Codable {
        let track: SpotifyTrack
    }
    let items: [Item]
}
