import Foundation

struct AMToken: Codable {
    let token: String
    let tokenType: String
    let expiresIn: Int
    let createdAt: Date
    let refreshToken: String?

    enum CodingKeys: String, CodingKey {
        case token
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case createdAt
        case refreshToken = "refresh_token"
    }

    init(token: String, tokenType: String, expiresIn: Int, refreshToken: String? = nil) {
        self.token = token
        self.tokenType = tokenType
        self.expiresIn = expiresIn
        self.createdAt = Date()
        self.refreshToken = refreshToken
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.token = try container.decode(String.self, forKey: .token)
        self.tokenType = try container.decode(String.self, forKey: .tokenType)
        self.expiresIn = try container.decode(Int.self, forKey: .expiresIn)
        self.createdAt = (try? container.decode(Date.self, forKey: .createdAt)) ?? Date()
        self.refreshToken = try container.decodeIfPresent(String.self, forKey: .refreshToken)
    }

    func isExpired() -> Bool {
        let expiresAt = createdAt.addingTimeInterval(TimeInterval(expiresIn))
        return Date() > expiresAt
    }
}
