import SwiftUI

struct SpotifyProfile {
    let playlists = [SpotifyPlaylist()]
}

// A simple struct to decode the /me endpoint response
struct SpotifyUserProfile: Codable, Identifiable {
    let id: String
    let display_name: String
    let email: String 
}
