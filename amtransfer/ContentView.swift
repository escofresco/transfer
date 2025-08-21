//import SwiftUI
//
//struct ContentView: View {
//    @State private var tokenId = "unset"
//    @State private var top5Songs = SpotifyPlaylist().songs
//    
//    var body: some View {
//        VStack {
//            Text(tokenId)
//                .onAppear {
//                    Task {
//                        // Await the async init
//                        let spotify = await SpotifyAdapter()
//                        // Update UI on main actor
//                        await MainActor.run {
//                            tokenId = spotify.tokenId
//                        }
//                        print(tokenId)
//                    }
//                }
//            Label("Top 5 Songs", systemImage:  "music.note.list")        .font(.largeTitle) // Uses system’s preset size for this style
//                .dynamicTypeSize(.large ... .xxxLarge) // optional: limit range
//            
//            List {
//                ForEach(self.top5Songs, id: \.self) { item in
//                    Text(item)
//                        .font(.title)
//                        .padding()
//                }
//            }
//        }
//    }
//}

import SwiftUI

struct ContentView: View {
    @StateObject private var spotify = SpotifyAdapter()
    @State private var isReady = false
    @State private var pastedURL: String = ""
    
    var body: some View {
        if isReady {
            if spotify.userProfile != nil {
                LoggedInView(spotify: spotify)
            } else {
                LoginView(spotify: spotify, pastedURL: $pastedURL)
            }
        } else {
            ProgressView("Initializing...")
                .task {
                    await spotify.setup()
                    self.isReady = true
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewLayout(.sizeThatFits)
            .frame(minWidth: 400, minHeight: 300)
    }
}
