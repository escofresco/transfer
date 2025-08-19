import SwiftUI

func runTests() async {
    let token = SpotifyToken(access_token: "abc", token_type: "test_token", expires_in: 1)
    assert(!token.isExpired())
    try? await Task.sleep(nanoseconds: 1_500_000_000)
    assert(token.isExpired())
}

