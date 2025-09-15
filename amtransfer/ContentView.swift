import SwiftUI

struct ContentView: View {
    @StateObject private var spotify = SpotifyAdapter()
    @State private var isReady = false
    @State private var pastedURL: String = ""
    
    var body: some View {
        GeometryReader { proxy in
            Group {
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
            .frame(
                width: proxy.size.width,
                height: proxy.size.height + proxy.safeAreaInsets.bottom,
                alignment: .top
            )
        }
        .ignoresSafeArea(.container, edges: .bottom)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewLayout(.sizeThatFits)
            .frame(minWidth: 400, minHeight: 500)
    }
}
