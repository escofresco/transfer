import SwiftUI

struct LoggedInView: View {
    @ObservedObject var spotify: SpotifyAdapter
    @State private var selectedPlaylists: Set<String> = []

    var body: some View {
        NavigationStack {
            VStack {
                if let profile = spotify.userProfile {
                    Text("Welcome, \(profile.display_name)!")
                        .font(.headline)
                        .padding(.top)

                    Text("Token ID: \(spotify.tokenId)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                List {
                    Section("Top 5 Songs") {
                        if spotify.topTracks.isEmpty {
                            ProgressView()
                        } else {
                            ForEach(spotify.topTracks) { track in
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

                    Section("Playlists") {
                        ForEach(spotify.playlists) { playlist in
                            HStack {
                                Toggle(isOn: Binding(
                                    get: { selectedPlaylists.contains(playlist.id) },
                                    set: { isSelected in
                                        if isSelected {
                                            selectedPlaylists.insert(playlist.id)
                                        } else {
                                            selectedPlaylists.remove(playlist.id)
                                        }
                                    }
                                )) {
                                    EmptyView()
                                }
                                .toggleStyle(.checkbox)

                                NavigationLink(playlist.name) {
                                    PlaylistDetailView(spotify: spotify, playlist: playlist)
                                }
                            }
                        }
                    }
                }

                Button("Logout", role: .destructive) {
                    spotify.logout()
                }
                .padding()
            }
            .padding()
            .navigationTitle("Spotify")
        }
    }
}
