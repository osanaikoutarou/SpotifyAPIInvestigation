//
//  ContentView.swift
//  SpotifyAPIInvestigation
//
//  Created by 長内幸太郎 on 2024/06/24.
//

import SwiftUI
import SpotifyiOS

struct ContentView: View {

    @State var trackItems: [TrackItem] = []
    @State var secret: String = "f38984ba02e6490eb9bae628be68cf87"   //78fc

    @State var token: String?
    @State var searchQuery: String = "artist=Ado"

    var body: some View {
        VStack {

            TextField("input secret", text: $secret)
                .border(.gray)
                .onChange(of: secret) { newValue in
                    SpotifyManager.shared.setSecret(value: newValue)
                }

            Spacer().frame(height: 30)

            Button {

                Task {
                    do {
                        token = try await SpotifyManager.shared.fetchAccessToken()
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            } label: {
                VStack {
                    Text("fetch access token")
                }
            }

            if token != nil {
                Text("token OK")
            } else {
                Text("token NG")
            }

            Spacer().frame(height: 30)

            Button {
                Task {
                    do {
                        trackItems =  try await SpotifyManager.shared.searchTrack(query: searchQuery)
                        print(trackItems)
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            } label: {
                Text("Search Musics")
            }
            TextField("Search Query", text: $searchQuery)
                .frame(alignment: .center)
                .border(.gray)

            Spacer().frame(height: 30)

            ScrollView {
                LazyVStack {
                    ForEach(0..<trackItems.count, id: \.self) { index in
                        Button {
                            print(trackItems[index].uri)
                            SpotifyManager.shared.authorizeAndPlayURI(playUrl: trackItems[index].uri)
                        } label: {
                            Text(trackItems[index].name + ":" + trackItems[index].uri)
                                .font(.system(size: 12))
                                .frame(height: 30)
                        }
                    }
                }
            }
            .frame(width: UIScreen.main.bounds.width - 20, height: 150)
            .border(.gray)

            Spacer().frame(height: 30)

            Button {
                SpotifyManager.shared.appRemote.connect()
            } label: {
                Text("Connect")
            }

            Spacer().frame(height: 30)

            Button {
                SpotifyManager.shared.authorizeAndPlayURI(playUrl: "spotify:track:1I77T75FxVU3W9SfGDFwZO")
            } label: {
                Text("play example")
            }

            Spacer().frame(height: 30)

            Button {
                SpotifyManager.shared.appRemote.disconnect()
            } label: {
                Text("Disconnect")
            }

            Spacer().frame(height: 30)



        }
        .padding()
        .onAppear {
            SpotifyManager.shared.setSecret(value: secret)
        }
    }

}

#Preview {
    ContentView()
}
