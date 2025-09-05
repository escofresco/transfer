import Foundation
import SwiftUI

@MainActor
class AMAdapter: ObservableObject {
    @Published var token: AMToken?
    @Published var playlists: [AMPlaylist] = []

    private static func loadSecrets() -> [String: Any] {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let dict = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
            return [:]
        }
        return dict
    }

    private static let secrets = loadSecrets()
    private let developerToken = AMAdapter.secrets["APPLE_DEVELOPER_TOKEN"] as? String ?? ""

    private let tokenKey = "apple-music-user-token"

    private let urlSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = true
        return URLSession(configuration: configuration)
    }()

    init() {
        if developerToken.isEmpty {
            print("⚠️ Apple Music developer token not set in Secrets.plist")
        }
        if let storedToken: AMToken = KeychainHelper.standard.load(for: tokenKey) {
            self.token = storedToken
        }
    }

    func setup() async {
        guard token != nil else {
            print("No Apple Music user token available")
            return
        }
        await fetchUserPlaylists()
    }

    func updateToken(_ newToken: AMToken) {
        self.token = newToken
        KeychainHelper.standard.save(newToken, for: tokenKey)
    }

    func fetchUserPlaylists() async {
        guard let token = token else { return }

        do {
            let url = URL(string: "https://api.music.apple.com/v1/me/library/playlists")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(developerToken)", forHTTPHeaderField: "Authorization")
            request.setValue(token.token, forHTTPHeaderField: "Music-User-Token")

            let (data, _) = try await urlSession.data(for: request)
            let response = try JSONDecoder().decode(AMPlaylistsResponse.self, from: data)
            self.playlists = response.data
        } catch {
            print("🚨 Could not fetch Apple Music playlists: \(error)")
        }
    }
}

