import Foundation

struct AMPlaylist: Codable, Identifiable, Hashable {
    let id: String
    let name: String
}

struct AMPlaylistsResponse: Codable {
    let data: [AMPlaylist]
}

struct AMPlaylistTracksResponse: Codable {
    let data: [AMTrack]
}
