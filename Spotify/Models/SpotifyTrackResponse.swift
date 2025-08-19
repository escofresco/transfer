import SwiftUI

// Models for the /me/top/tracks endpoint
struct TopTracksResponse: Codable {
    let items: [SpotifyTrack]
}


