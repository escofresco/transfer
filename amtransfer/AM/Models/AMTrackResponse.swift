import Foundation

// Models for the top songs endpoint
struct TopSongsResponse: Codable {
    let data: [AMTrack]
}
