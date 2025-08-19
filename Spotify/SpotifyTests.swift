import SwiftUI

func runTests() async {
    let token = SpotifyToken(access_token: "abc", token_type: "test_token", expires_in: 10)
    assert(!token.isExpired())
    try? await Task.sleep(nanoseconds: 10_000_000_000)
    assert(token.isExpired())
}


