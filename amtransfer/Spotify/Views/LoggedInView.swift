import SwiftUI

struct LoggedInView: View {
    @ObservedObject var spotify: SpotifyAdapter
    @State private var top5Songs = SpotifyPlaylist().songs
    
    var body: some View {
        VStack {
            if let profile = spotify.userProfile {
                Text("Welcome, \(profile.display_name)!")
                    .font(.headline)
                    .padding(.top)
                
                Text("Token ID: \(spotify.tokenId)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
            }
            
            
                Label("Top 5 Songs", systemImage: "music.note.list")
                    .font(.largeTitle)
                    .padding(.top)
                
                if spotify.topTracks.isEmpty {
                    ProgressView()
                    Spacer()
                } else {
                    List(spotify.topTracks) { track in
                        VStack(alignment: .leading) {
                            Text(track.name)
                                .fontWeight(.semibold)
                            Text(track.artistNames)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                
                Spacer()
                
                Button("Logout", role: .destructive) {
                    spotify.logout()
                }
                .padding()
            }
        }
        .padding()
    }
}
