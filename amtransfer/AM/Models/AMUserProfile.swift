import Foundation

// A simple struct to decode the /me endpoint response
struct AMUserProfile: Codable, Identifiable {
    let id: String
    let name: String
}
