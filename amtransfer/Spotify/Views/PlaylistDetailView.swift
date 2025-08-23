import SwiftUI

struct PlaylistDetailView: View {
    @ObservedObject var spotify: SpotifyAdapter
    let playlist: SpotifyPlaylist
    @State private var tracks: [SpotifyTrack] = []

    var body: some View {
        List {
            if tracks.isEmpty {
                ProgressView()
            } else {
                ForEach(tracks) { track in
                    VStack(alignment: .leading) {
                        Text(track.name)
                            .fontWeight(.semibold)
                        Text(track.artistNames)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle(playlist.name)
        .task {
            tracks = await spotify.getTracks(for: playlist.id)
        }
    }
}
