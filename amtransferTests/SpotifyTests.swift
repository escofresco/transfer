import Testing
import Foundation
@testable import amtransfer

struct SpotifyTests {
    @Test func tokenExpiration() async throws {
        let token = SpotifyToken(access_token: "abc", token_type: "test_token", expires_in: 1)
        #expect(!token.isExpired())
        try await Task.sleep(nanoseconds: 1_500_000_000)
        #expect(token.isExpired())
    }

    @Test func playlistsDecode() throws {
        let json = """
        {
            "items": [
                {"id": "1", "name": "Road Trip"},
                {"id": "2", "name": "Chill"}
            ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(PlaylistsResponse.self, from: json)
        #expect(response.items.count == 2)
        #expect(response.items.first?.name == "Road Trip")
    }

    @Test func playlistTracksDecode() throws {
        let json = """
        {
            "items": [
                {
                    "track": {
                        "id": "t1",
                        "name": "Song A",
                        "artists": [{"id": "a1", "name": "Artist 1"}]
                    }
                },
                {
                    "track": {
                        "id": "t2",
                        "name": "Song B",
                        "artists": [{"id": "a2", "name": "Artist 2"}]
                    }
                }
            ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(PlaylistTracksResponse.self, from: json)
        #expect(response.items.count == 2)
        #expect(response.items[0].track.name == "Song A")
        #expect(response.items[0].track.artists[0].name == "Artist 1")
    }
}
