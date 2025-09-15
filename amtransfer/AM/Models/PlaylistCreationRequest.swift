import MusicKit
import Foundation

/// Minimal wrapper to create a playlist in the user's Apple Music library.
///
/// The official MusicKit `PlaylistCreationRequest` type is only available
/// on newer OS versions. This custom struct provides the same interface so the
/// app compiles on older SDKs; the actual implementation should be filled in
/// with the necessary network calls when running on a supported platform.
struct PlaylistCreationRequest {
    /// Name for the new playlist.
    var name: String

    /// Tracks to include in the new playlist.
    var trackIDs: [MusicItemID]

    /// Sends the playlist creation request to Apple Music.
    ///
    /// This implementation uses ``MusicDataRequest`` to call the
    /// `me/library/playlists` endpoint and create the playlist with the
    /// supplied tracks.
    func response() async throws {
        let url = URL(string: "https://api.music.apple.com/v1/me/library/playlists")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "attributes": ["name": name],
            "relationships": [
                "tracks": [
                    "data": trackIDs.map { ["id": $0.rawValue, "type": "songs"] }
                ]
            ]
        ]

        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)

        var request = MusicDataRequest(urlRequest: urlRequest)
        request.requiresMusicUserToken = true
        _ = try await request.response()
    }
}
