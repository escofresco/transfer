struct AMTrack: Codable, Hashable, Identifiable {
    let id: String
    let name: String
    let artists: [AMArtist]

    var artistNames: String {
        artists.map { $0.name }.joined(separator: ", ")
    }
}
