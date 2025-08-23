import Testing
@testable import amtransfer

struct SpotifyTests {
    @Test func tokenExpiration() async throws {
        let token = SpotifyToken(access_token: "abc", token_type: "test_token", expires_in: 1)
        #expect(!token.isExpired())
        try await Task.sleep(nanoseconds: 1_500_000_000)
        #expect(token.isExpired())
    }
}
