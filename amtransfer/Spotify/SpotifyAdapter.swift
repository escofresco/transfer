import Foundation
import SwiftUI
import Combine

@MainActor
class SpotifyAdapter: ObservableObject {
    @Published var spotifyToken: SpotifyToken?
    @Published var userProfile: SpotifyUserProfile?
    @Published var tokenId: String = "unset"
    @Published var topTracks: [SpotifyTrack] = []
    
    private let clientID = "442144c176c44965a2c05859fc00e5e6"
    private let clientSecret = "face180305184bd6bc692d932d8756c0"
    private let redirectURI = "https://cruditech.com/callback"

    private let tokenKey = "spotify-token"
    private let profileKey = "spotify-user-profile"

    // Use a dedicated URLSession so we can tweak its behaviour when
    // attempting to reach Spotify. `waitsForConnectivity` ensures that
    // transient network issues (for example when the device temporarily
    // loses connectivity or DNS resolution fails) are handled more
    // gracefully instead of immediately throwing a "cannot find host"
    // error.
    private let urlSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = true
        return URLSession(configuration: configuration)
    }()
    
    init() {
        print("SpotifyAdapter initialized.")
    }
    
    func setup() async {
        // Try to load a session from the Keychain.
        if let storedToken = KeychainHelper.standard.load(for: tokenKey) as SpotifyToken? {
            self.spotifyToken = storedToken
            if storedToken.isExpired() {
                print("Token expired, attempting refresh...")
                do {
                    try await refreshAccessToken()
                } catch {
                    print("🚨 Refresh failed, logging out. Error: \(error)")
                    logout() // If refresh fails, force logout
                }
            } else {
                print("✅ Found valid token in Keychain.")
                self.userProfile = KeychainHelper.standard.load(for: profileKey)
                self.tokenId = String(storedToken.access_token.prefix(8))
                await fetchUserData()
            }
        } else {
            // If no token, start a fresh session.
            print("No token found in Keychain, starting new session.")
            await setupNewSession()
        }
    }
    
    private func setupNewSession() async {
        do {
            try await requestNewSpotifyAuthToken()
            print("✅ App authenticated with initial client token.")
        } catch {
            print("🚨 Failed to get initial client token: \(error)")
        }
    }
    
    func logout() {
        KeychainHelper.standard.delete(for: tokenKey)
        KeychainHelper.standard.delete(for: profileKey)
        
        self.spotifyToken = nil
        self.userProfile = nil
        self.topTracks = []
        self.tokenId = "unset"
        
        Task {
            await setupNewSession()
        }
    }
    
    // MARK: - Authentication Methods
    
    func requestNewSpotifyAuthToken() async throws {
        let body = "grant_type=client_credentials&client_id=\(clientID)&client_secret=\(clientSecret)"
        let url = URL(string: "https://accounts.spotify.com/api/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = body.data(using: .utf8)
        
        let (data, _) = try await urlSession.data(for: request)
        let decoded = try JSONDecoder().decode(SpotifyToken.self, from: data)
        
        self.spotifyToken = decoded
        self.tokenId = String(decoded.access_token.prefix(8))
    }
    
    func createAuthorizationURL() -> URL? {
        var components = URLComponents(string: "https://accounts.spotify.com/authorize")
        let scopes = "user-read-private user-read-email user-top-read"
        
        components?.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "scope", value: scopes),
            URLQueryItem(name: "redirect_uri", value: redirectURI)
        ]
        return components?.url
    }
    
    func exchangeCodeForToken(from redirectedURL: URL) async throws {
        guard let components = URLComponents(url: redirectedURL, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            throw NSError(domain: "SpotifyAuth", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not find authorization code in URL."])
        }
        
        let tokenURL = URL(string: "https://accounts.spotify.com/api/token")!
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        var bodyComponents = URLComponents()
        bodyComponents.queryItems = [
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "client_secret", value: clientSecret)
        ]
        request.httpBody = bodyComponents.query?.data(using: .utf8)
        
        let (data, _) = try await urlSession.data(for: request)
        let userToken = try JSONDecoder().decode(SpotifyToken.self, from: data)
        
        self.spotifyToken = userToken
        KeychainHelper.standard.save(userToken, for: tokenKey)
        print("✅ User successfully authenticated and token saved.")
        
        await fetchUserData()
    }
    
    func refreshAccessToken() async throws {
        guard let currentToken = self.spotifyToken, let refreshToken = currentToken.refresh_token else {
            throw NSError(domain: "SpotifyAuth", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing refresh token."])
        }
        
        let tokenURL = URL(string: "https://accounts.spotify.com/api/token")!
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        var bodyComponents = URLComponents()
        bodyComponents.queryItems = [
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "refresh_token", value: refreshToken),
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "client_secret", value: clientSecret)
        ]
        request.httpBody = bodyComponents.query?.data(using: .utf8)
        
        let (data, _) = try await urlSession.data(for: request)
        var refreshedToken = try JSONDecoder().decode(SpotifyToken.self, from: data)
        
        // Spotify may not return a new refresh token. If not, reuse the old one.
        if refreshedToken.refresh_token == nil {
            refreshedToken.refresh_token = refreshToken
        }
        
        self.spotifyToken = refreshedToken
        self.tokenId = String(refreshedToken.access_token.prefix(8))
        KeychainHelper.standard.save(refreshedToken, for: tokenKey)
        print("✅ Token refreshed and saved.")
        
        await fetchUserData()
    }
    
    // MARK: - Data Fetching
    
    private func fetchUserData() async {
        do {
            // Run profile and track fetching concurrently.
            async let profileTask: () = getUserProfile()
            async let tracksTask: () = getTopTracks()
            
            // Await both tasks to complete. If either throws, the catch block will run.
            _ = try await (profileTask, tracksTask)
        } catch {
            print("🚨 Failed to fetch user data, logging out. Error: \(error)")
            logout()
        }
    }
    
    func getUserProfile() async throws {
        guard let token = spotifyToken, token.refresh_token != nil else { return }
        
        do {
            let url = URL(string: "https://api.spotify.com/v1/me")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token.access_token)", forHTTPHeaderField: "Authorization")
            
            let (data, _) = try await urlSession.data(for: request)
            let profile = try JSONDecoder().decode(SpotifyUserProfile.self, from: data)
            
            self.userProfile = profile
            self.tokenId = String(token.access_token.prefix(8))
            KeychainHelper.standard.save(profile, for: profileKey)
        } catch {
            print("🚨 Could not fetch user profile: \(error)")
        }
    }
    
    func getTopTracks() async {
        guard let token = spotifyToken, token.refresh_token != nil else { return }
        
        do {
            let url = URL(string: "https://api.spotify.com/v1/me/top/tracks?limit=5&time_range=medium_term")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token.access_token)", forHTTPHeaderField: "Authorization")
            
            let (data, _) = try await urlSession.data(for: request)
            let response = try JSONDecoder().decode(TopTracksResponse.self, from: data)
            self.topTracks = response.items
        } catch {
            print("🚨 Could not fetch top tracks: \(error)")
        }
    }
}
