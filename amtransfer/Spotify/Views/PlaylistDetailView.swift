import SwiftUI

struct PlaylistDetailView: View {
    @ObservedObject var spotify: SpotifyAdapter
    let playlist: SpotifyPlaylist
    @State private var tracks: [SpotifyTrack] = []
    @Environment(\.dismiss) private var dismiss

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
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Label("Back", systemImage: "chevron.left")
                }
            }
        }
        .task {
            tracks = await spotify.getTracks(for: playlist.id)
        }
    }
}
