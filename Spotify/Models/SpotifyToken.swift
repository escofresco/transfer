import SwiftUI

struct SpotifyToken: Codable {
    let access_token: String
    let access_tokenBase64: String
    let token_type: String
    let expires_in: Int
    let createdAt: Date
    let scope: String?
    var refresh_token: String?
    
    // Keep a Codable-compatible initializer that provides a createdAt default if missing.
    enum CodingKeys: String, CodingKey {
        case access_token, access_tokenBase64, token_type, expires_in, createdAt, scope, refresh_token
    }
    
    init(access_token: String, token_type: String, expires_in: Int) {
        self.access_token = access_token
        self.access_tokenBase64 = SpotifyToken.asBase64Credentials(s: self.access_token)
        self.token_type = token_type
        self.expires_in = expires_in
        self.createdAt = Date()
        self.scope = ""
        self.refresh_token = ""
    }
    
    // Custom decoder that allows createdAt and access_tokenBase64 to be absent in Spotify's response
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.access_token = try container.decode(String.self, forKey: .access_token)
        // Fallback on `access_token` if `access_tokenBase64` is missing? 
        self.access_tokenBase64 = (try? container.decode(String.self, forKey: .access_tokenBase64)) ?? SpotifyToken.asBase64Credentials(s: self.access_token)
        self.token_type = try container.decode(String.self, forKey: .token_type)
        self.expires_in = try container.decode(Int.self, forKey: .expires_in)
        // If createdAt is missing, default to now
        self.createdAt = (try? container.decode(Date.self, forKey: .createdAt)) ?? Date()
        self.scope = try container.decode(String.self, forKey: .scope)
        self.refresh_token = try container.decode(String.self, forKey: .refresh_token)
    }
    
    static func asBase64Credentials(s: String) -> String  {
        let sData = s.data(using: .utf8)!
        return sData.base64EncodedString()
    }
    
    func isExpired() -> Bool {
        let expiresAt = createdAt.addingTimeInterval(TimeInterval(self.expires_in))
        // Use Date() to be widely compatible
        return Date() > expiresAt
    }
    
}
