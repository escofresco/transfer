struct SpotifyTrack: Codable, Hashable, Identifiable {
    let id: String
    let name: String
    let artists: [SpotifyArtist]
    
    var artistNames: String {
        artists.map { $0.name }.joined(separator: ", ")
    }
}
