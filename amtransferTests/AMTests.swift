import Testing
import Foundation
@testable import amtransfer

struct AMTests {
    @Test func tokenExpiration() async throws {
        let token = AMToken(token: "abc", tokenType: "bearer", expiresIn: 1)
        #expect(!token.isExpired())
        try await Task.sleep(nanoseconds: 1_500_000_000)
        #expect(token.isExpired())
    }

    @Test func trackArtistNames() throws {
        let track = AMTrack(id: "1", name: "Song", artists: [AMArtist(name: "Artist 1"), AMArtist(name: "Artist 2")])
        #expect(track.artistNames == "Artist 1, Artist 2")
    }

    @Test func decodeTopSongsResponse() throws {
        let json = """
        {"data":[{"id":"1","name":"Song","artists":[{"name":"Artist"}]}]}
        """.data(using: .utf8)!
        let response = try JSONDecoder().decode(TopSongsResponse.self, from: json)
        #expect(response.data.count == 1)
        #expect(response.data[0].name == "Song")
    }

    @Test func decodePlaylistsResponse() throws {
        let json = """
        {"data":[{"id":"1","name":"My Playlist"}]}
        """.data(using: .utf8)!
        let response = try JSONDecoder().decode(AMPlaylistsResponse.self, from: json)
        #expect(response.data.count == 1)
        #expect(response.data[0].id == "1")
    }
}
