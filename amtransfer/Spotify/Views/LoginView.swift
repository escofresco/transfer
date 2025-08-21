import SwiftUI

struct LoginView: View {
    @ObservedObject var spotify: SpotifyAdapter
    @Binding var pastedURL: String
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Spotify Login")
                .font(.largeTitle.bold())
                .padding(.top)
            
            Text("App Token: \(spotify.tokenId)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom)
            
            if let authURL = spotify.createAuthorizationURL() {
                Link("1. Tap here to Authorize", destination: authURL)
                    .padding().background(Color.green).foregroundColor(.white).cornerRadius(10)
            }
            
            TextField("2. Paste the full redirected URL here", text: $pastedURL)
                .textFieldStyle(.roundedBorder)
                .disableAutocorrection(true)
                .padding(Edge.Set.horizontal)
          
            
            Button("3. Complete Login") {
                Task {
                    guard let url = URL(string: pastedURL) else { return }
                    do {
                        try await spotify.exchangeCodeForToken(from: url)
                        try await spotify.getUserProfile()
                    } catch {
                        print("🚨 Login failed: \(error.localizedDescription)")
                    }
                }
            }
            .padding().background(pastedURL.isEmpty ? Color.gray : Color.blue).foregroundColor(.white).cornerRadius(10).disabled(pastedURL.isEmpty)
            
            Spacer()
        }
        .padding()
    }
}
