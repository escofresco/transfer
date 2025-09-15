import SwiftUI
import UIKit

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
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .onAppear {
                print("Root view frame:", proxy.frame(in: .global))
                print("UIScreen bounds:", UIScreen.main.bounds)
            }
        }
        .ignoresSafeArea()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewLayout(.sizeThatFits)
            .frame(minWidth: 400, minHeight: 500)
    }
}
