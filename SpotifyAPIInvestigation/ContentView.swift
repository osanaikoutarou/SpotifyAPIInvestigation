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
    @State var playUrl: String = ""
    @State var isConnected: Bool = false
    @State var currentTrackImage: UIImage? = nil

    var body: some View {
        ScrollView {
            content
                .onAppear {
                    SpotifyManager.shared.setSecret(value: secret)
                }
                .onReceive(
                    NotificationCenter.default.publisher(for: Notification.Name.SPTAppRemoteConnected)
                ) { _ in
                    isConnected = true
                }
                .onReceive(
                    NotificationCenter.default.publisher(for: Notification.Name.SPTAppRemoteDisConnected)
                ) { _ in
                    isConnected = false
                }
                .onReceive(
                    NotificationCenter.default.publisher(for: Notification.Name.playerStateDidChange)
                ) { _ in
                    if let currentSPTAppRemotePlayerState = SpotifyManager.shared.currentSPTAppRemotePlayerState {
                        fetchImage(for: currentSPTAppRemotePlayerState.track)
                    }
                }
        }
    }

    @ViewBuilder
    var content: some View {
        VStack {
            TextField("input secret", text: $secret)
                .border(.gray)
                .onChange(of: secret) { newValue in
                    SpotifyManager.shared.setSecret(value: newValue)
                }
                .padding(.bottom, 20)

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
                    Text("fetch access token (WebAPI)")
                }
            }

            Group {
                if token != nil {
                    Text("token OK")
                } else {
                    Text("token NG")
                }
            }
            .padding(.bottom, 20)

            Button {
                SpotifyManager.shared.authorizeAndPlayURI()
            } label: {
                VStack {
                    Text("authorize (iOS SDK)")
                }
            }

            searchView

            if let currentTrackImage {
                SpotifyPlayingImage(image: currentTrackImage)
                    .frame(width: 30, height: 30)
            }

            connectingView

            HStack {
                TextField("input URL", text: $playUrl)
                    .border(.gray)

                Button {
                    if playUrl.isEmpty {
                        SpotifyManager.shared.authorizeAndPlayURI()
                    } else {
                        SpotifyManager.shared.appRemote.playerAPI?.play(playUrl, asRadio: true, callback: { a, error in
                            print(a, error?.localizedDescription)
                        })
                    }
                } label: {
                    Text("play example")
                }
            }
            .padding(.bottom, 20)

            HStack(spacing: 20) {
                Button {
                    SpotifyManager.shared.appRemote.playerAPI?.resume()
                } label: {
                    Text("Play")
                }
                Button {
                    SpotifyManager.shared.appRemote.playerAPI?.pause()
                } label: {
                    Text("Pause")
                }
                Button {
                } label: {
                    Text("Stop")
                }

            }
        }
    }

    @ViewBuilder
    var searchView: some View {
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
            .padding(.bottom, 20)

        Text("Search Result")
        ScrollView {
            LazyVStack {
                ForEach(0..<trackItems.count, id: \.self) { index in
                    Button {
                        print(trackItems[index].uri)
                        SpotifyManager.shared.authorizeAndPlayURI(playUrl: trackItems[index].uri)
                    } label: {
                        HStack {


                            VStack {
                                Text(trackItems[index].name + "(" + trackItems[index].artists.first!.name + ")")
                                    .font(.system(size: 11))
                                Text("URI:" + trackItems[index].uri)
                                    .font(.system(size: 11))
                                Spacer().frame(height: 10)
                            }
                        }
                    }
                }
            }

        }
        .frame(width: UIScreen.main.bounds.width - 20, height: 150)
        .border(.gray)
        .padding(.bottom, 20)
    }


    @ViewBuilder
    var connectingView: some View {
        Button {
            SpotifyManager.shared.appRemote.connect()
        } label: {
            Text("Connect")
        }
        .padding(.bottom, 10)

        Button {
            SpotifyManager.shared.appRemote.disconnect()
        } label: {
            Text("Disconnect")
        }
        .padding(.bottom, 10)

        Group {
            if isConnected {
                Text("connect OK")
            } else {
                Text("connect NG")
            }
        }
        .padding(.bottom, 20)
    }

}

extension ContentView {
    func fetchImage(for track: SPTAppRemoteTrack) {
        SpotifyManager.shared.appRemote.imageAPI?.fetchImage(forItem: track, with: CGSize(width: 50, height: 50), callback: { (image, error) in
            if let error = error {
                print("Error fetching track image: \(error.localizedDescription)")
            } else if let image = image as? UIImage {
                DispatchQueue.main.async {
                    self.currentTrackImage = image
                }
            }
        })
    }
}



/*



{
    "tracks": {
        "href": "https://api.spotify.com/v1/search?query=artist%3DAdo&type=track&include_external=audio&market=JP&locale=ja%2Cen-US%3Bq%3D0.9%2Cen%3Bq%3D0.8&offset=0&limit=10",
        "limit": 10,
        "next": "https://api.spotify.com/v1/search?query=artist%3DAdo&type=track&include_external=audio&market=JP&locale=ja%2Cen-US%3Bq%3D0.9%2Cen%3Bq%3D0.8&offset=10&limit=10",
        "offset": 0,
        "previous": null,
        "total": 899,
        "items": [
            {
                "album": {
                    "album_type": "single",
                    "total_tracks": 1,
                    "external_urls": {
                        "spotify": "https://open.spotify.com/album/10iuG3s2Fry5JiUh0i0c75"
                    },
                    "href": "https://api.spotify.com/v1/albums/10iuG3s2Fry5JiUh0i0c75",
                    "id": "10iuG3s2Fry5JiUh0i0c75",
                    "images": [
                        {
                            "url": "https://i.scdn.co/image/ab67616d0000b27396442a09c438871cbd60c8e2",
                            "height": 640,
                            "width": 640
                        },
                        {
                            "url": "https://i.scdn.co/image/ab67616d00001e0296442a09c438871cbd60c8e2",
                            "height": 300,
                            "width": 300
                        },
                        {
                            "url": "https://i.scdn.co/image/ab67616d0000485196442a09c438871cbd60c8e2",
                            "height": 64,
                            "width": 64
                        }
                    ],
                    "name": "ルル",
                    "release_date": "2024-07-05",
                    "release_date_precision": "day",
                    "type": "album",
                    "uri": "spotify:album:10iuG3s2Fry5JiUh0i0c75",
                    "artists": [
                        {
                            "external_urls": {
                                "spotify": "https://open.spotify.com/artist/6mEQK9m2krja6X1cfsAjfl"
                            },
                            "href": "https://api.spotify.com/v1/artists/6mEQK9m2krja6X1cfsAjfl",
                            "id": "6mEQK9m2krja6X1cfsAjfl",
                            "name": "Ado",
                            "type": "artist",
                            "uri": "spotify:artist:6mEQK9m2krja6X1cfsAjfl"
                        }
                    ],
                    "is_playable": true
                },
                "artists": [
                    {
                        "external_urls": {
                            "spotify": "https://open.spotify.com/artist/6mEQK9m2krja6X1cfsAjfl"
                        },
                        "href": "https://api.spotify.com/v1/artists/6mEQK9m2krja6X1cfsAjfl",
                        "id": "6mEQK9m2krja6X1cfsAjfl",
                        "name": "Ado",
                        "type": "artist",
                        "uri": "spotify:artist:6mEQK9m2krja6X1cfsAjfl"
                    }
                ],
                "disc_number": 1,
                "duration_ms": 197854,
                "explicit": false,
                "external_ids": {
                    "isrc": "JPPO02402980"
                },
                "external_urls": {
                    "spotify": "https://open.spotify.com/track/6UuxnR9zgvzpFS6YvfCqFL"
                },
                "href": "https://api.spotify.com/v1/tracks/6UuxnR9zgvzpFS6YvfCqFL",
                "id": "6UuxnR9zgvzpFS6YvfCqFL",
                "is_playable": true,
                "name": "ルル",
                "popularity": 36,
                "preview_url": null,
                "track_number": 1,
                "type": "track",
                "uri": "spotify:track:6UuxnR9zgvzpFS6YvfCqFL",
                "is_local": false
            },










            {
                "album": {
                    "album_type": "single",
                    "total_tracks": 1,
                    "external_urls": {
                        "spotify": "https://open.spotify.com/album/18jn1n7WP5aYQcJORKwTxp"      // AlbumのURL?
                    },
                    "href": "https://api.spotify.com/v1/albums/18jn1n7WP5aYQcJORKwTxp",
                    "id": "18jn1n7WP5aYQcJORKwTxp",     // Album Id
                    "images": [
                        {
                            "url": "https://i.scdn.co/image/ab67616d0000b273985fe71d6d5d528429037716",
                            "height": 640,
                            "width": 640
                        },
                        {
                            "url": "https://i.scdn.co/image/ab67616d00001e02985fe71d6d5d528429037716",
                            "height": 300,
                            "width": 300
                        },
                        {
                            "url": "https://i.scdn.co/image/ab67616d00004851985fe71d6d5d528429037716",
                            "height": 64,
                            "width": 64
                        }
                    ],
                    "name": "唱",
                    "release_date": "2023-09-06",
                    "release_date_precision": "day",
                    "type": "album",
                    "uri": "spotify:album:18jn1n7WP5aYQcJORKwTxp",
                    "artists": [
                        {
                            "external_urls": {
                                "spotify": "https://open.spotify.com/artist/6mEQK9m2krja6X1cfsAjfl"
                            },
                            "href": "https://api.spotify.com/v1/artists/6mEQK9m2krja6X1cfsAjfl",
                            "id": "6mEQK9m2krja6X1cfsAjfl",
                            "name": "Ado",
                            "type": "artist",
                            "uri": "spotify:artist:6mEQK9m2krja6X1cfsAjfl"
                        }
                    ],
                    "is_playable": true
                },
                "artists": [
                    {
                        "external_urls": {
                            "spotify": "https://open.spotify.com/artist/6mEQK9m2krja6X1cfsAjfl"
                        },
                        "href": "https://api.spotify.com/v1/artists/6mEQK9m2krja6X1cfsAjfl",
                        "id": "6mEQK9m2krja6X1cfsAjfl",
                        "name": "Ado",
                        "type": "artist",
                        "uri": "spotify:artist:6mEQK9m2krja6X1cfsAjfl"
                    }
                ],
                "disc_number": 1,
                "duration_ms": 189772,
                "explicit": false,
                "external_ids": {
                    "isrc": "JPPO02302806"
                },
                "external_urls": {
                    "spotify": "https://open.spotify.com/track/2tlOVDJ3lQsUxz22vPJ4c4"
                },
                "href": "https://api.spotify.com/v1/tracks/2tlOVDJ3lQsUxz22vPJ4c4",
                "id": "2tlOVDJ3lQsUxz22vPJ4c4",
                "is_playable": true,
                "name": "唱",
                "popularity": 65,
                "preview_url": null,
                "track_number": 1,
                "type": "track",
                "uri": "spotify:track:2tlOVDJ3lQsUxz22vPJ4c4",          // ~~c4は確かに唱
                "is_local": false
            },











            {
                "album": {
                    "album_type": "album",
                    "total_tracks": 14,
                    "external_urls": {
                        "spotify": "https://open.spotify.com/album/0tDsHtvN9YNuZjlqHvDY2P"
                    },
                    "href": "https://api.spotify.com/v1/albums/0tDsHtvN9YNuZjlqHvDY2P",
                    "id": "0tDsHtvN9YNuZjlqHvDY2P",
                    "images": [
                        {
                            "url": "https://i.scdn.co/image/ab67616d0000b2732cd7888600aafe2eb8b6be9f",
                            "height": 640,
                            "width": 640
                        },
                        {
                            "url": "https://i.scdn.co/image/ab67616d00001e022cd7888600aafe2eb8b6be9f",
                            "height": 300,
                            "width": 300
                        },
                        {
                            "url": "https://i.scdn.co/image/ab67616d000048512cd7888600aafe2eb8b6be9f",
                            "height": 64,
                            "width": 64
                        }
                    ],
                    "name": "狂言",
                    "release_date": "2022-01-26",
                    "release_date_precision": "day",
                    "type": "album",
                    "uri": "spotify:album:0tDsHtvN9YNuZjlqHvDY2P",
                    "artists": [
                        {
                            "external_urls": {
                                "spotify": "https://open.spotify.com/artist/6mEQK9m2krja6X1cfsAjfl"
                            },
                            "href": "https://api.spotify.com/v1/artists/6mEQK9m2krja6X1cfsAjfl",
                            "id": "6mEQK9m2krja6X1cfsAjfl",
                            "name": "Ado",
                            "type": "artist",
                            "uri": "spotify:artist:6mEQK9m2krja6X1cfsAjfl"
                        }
                    ],
                    "is_playable": true
                },
                "artists": [
                    {
                        "external_urls": {
                            "spotify": "https://open.spotify.com/artist/6mEQK9m2krja6X1cfsAjfl"
                        },
                        "href": "https://api.spotify.com/v1/artists/6mEQK9m2krja6X1cfsAjfl",
                        "id": "6mEQK9m2krja6X1cfsAjfl",
                        "name": "Ado",
                        "type": "artist",
                        "uri": "spotify:artist:6mEQK9m2krja6X1cfsAjfl"
                    }
                ],
                "disc_number": 1,
                "duration_ms": 210346,
                "explicit": false,
                "external_ids": {
                    "isrc": "JPPO02100708"
                },
                "external_urls": {
                    "spotify": "https://open.spotify.com/track/0871AdnvzzSGr5XdTJaDHC"
                },
                "href": "https://api.spotify.com/v1/tracks/0871AdnvzzSGr5XdTJaDHC",
                "id": "0871AdnvzzSGr5XdTJaDHC",
                "is_playable": true,
                "name": "踊",
                "popularity": 58,
                "preview_url": null,
                "track_number": 2,
                "type": "track",
                "uri": "spotify:track:0871AdnvzzSGr5XdTJaDHC",
                "is_local": false
            },
            {
                "album": {
                    "album_type": "single",
                    "total_tracks": 1,
                    "external_urls": {
                        "spotify": "https://open.spotify.com/album/4bIo5w5xKztinGjv11NoOQ"
                    },
                    "href": "https://api.spotify.com/v1/albums/4bIo5w5xKztinGjv11NoOQ",
                    "id": "4bIo5w5xKztinGjv11NoOQ",
                    "images": [
                        {
                            "url": "https://i.scdn.co/image/ab67616d0000b273dfdacb364c44d7365b6139b7",
                            "height": 640,
                            "width": 640
                        },
                        {
                            "url": "https://i.scdn.co/image/ab67616d00001e02dfdacb364c44d7365b6139b7",
                            "height": 300,
                            "width": 300
                        },
                        {
                            "url": "https://i.scdn.co/image/ab67616d00004851dfdacb364c44d7365b6139b7",
                            "height": 64,
                            "width": 64
                        }
                    ],
                    "name": "MIRROR",
                    "release_date": "2024-05-30",
                    "release_date_precision": "day",
                    "type": "album",
                    "uri": "spotify:album:4bIo5w5xKztinGjv11NoOQ",
                    "artists": [
                        {
                            "external_urls": {
                                "spotify": "https://open.spotify.com/artist/6mEQK9m2krja6X1cfsAjfl"
                            },
                            "href": "https://api.spotify.com/v1/artists/6mEQK9m2krja6X1cfsAjfl",
                            "id": "6mEQK9m2krja6X1cfsAjfl",
                            "name": "Ado",
                            "type": "artist",
                            "uri": "spotify:artist:6mEQK9m2krja6X1cfsAjfl"
                        }
                    ],
                    "is_playable": true
                },
                "artists": [
                    {
                        "external_urls": {
                            "spotify": "https://open.spotify.com/artist/6mEQK9m2krja6X1cfsAjfl"
                        },
                        "href": "https://api.spotify.com/v1/artists/6mEQK9m2krja6X1cfsAjfl",
                        "id": "6mEQK9m2krja6X1cfsAjfl",
                        "name": "Ado",
                        "type": "artist",
                        "uri": "spotify:artist:6mEQK9m2krja6X1cfsAjfl"
                    }
                ],
                "disc_number": 1,
                "duration_ms": 178000,
                "explicit": false,
                "external_ids": {
                    "isrc": "JPPO02402466"
                },
                "external_urls": {
                    "spotify": "https://open.spotify.com/track/0NtfH5RUt4V3Vzh18Wuc23"
                },
                "href": "https://api.spotify.com/v1/tracks/0NtfH5RUt4V3Vzh18Wuc23",
                "id": "0NtfH5RUt4V3Vzh18Wuc23",
                "is_playable": true,
                "name": "MIRROR",
                "popularity": 70,
                "preview_url": null,
                "track_number": 1,
                "type": "track",
                "uri": "spotify:track:0NtfH5RUt4V3Vzh18Wuc23",
                "is_local": false
            },
            {
                "album": {
                    "album_type": "album",
                    "total_tracks": 25,
                    "external_urls": {
                        "spotify": "https://open.spotify.com/album/31LvSRXGPVhYs2EZFK0BEU"
                    },
                    "href": "https://api.spotify.com/v1/albums/31LvSRXGPVhYs2EZFK0BEU",
                    "id": "31LvSRXGPVhYs2EZFK0BEU",
                    "images": [
                        {
                            "url": "https://i.scdn.co/image/ab67616d0000b273f29faf5699c2f7eb7970a290",
                            "height": 640,
                            "width": 640
                        },
                        {
                            "url": "https://i.scdn.co/image/ab67616d00001e02f29faf5699c2f7eb7970a290",
                            "height": 300,
                            "width": 300
                        },
                        {
                            "url": "https://i.scdn.co/image/ab67616d00004851f29faf5699c2f7eb7970a290",
                            "height": 64,
                            "width": 64
                        }
                    ],
                    "name": "Ado \"Ready For My Show Playlist\"",
                    "release_date": "2024-02-06",
                    "release_date_precision": "day",
                    "type": "album",
                    "uri": "spotify:album:31LvSRXGPVhYs2EZFK0BEU",
                    "artists": [
                        {
                            "external_urls": {
                                "spotify": "https://open.spotify.com/artist/6mEQK9m2krja6X1cfsAjfl"
                            },
                            "href": "https://api.spotify.com/v1/artists/6mEQK9m2krja6X1cfsAjfl",
                            "id": "6mEQK9m2krja6X1cfsAjfl",
                            "name": "Ado",
                            "type": "artist",
                            "uri": "spotify:artist:6mEQK9m2krja6X1cfsAjfl"
                        }
                    ],
                    "is_playable": true
                },
                "artists": [
                    {
                        "external_urls": {
                            "spotify": "https://open.spotify.com/artist/6mEQK9m2krja6X1cfsAjfl"
                        },
                        "href": "https://api.spotify.com/v1/artists/6mEQK9m2krja6X1cfsAjfl",
                        "id": "6mEQK9m2krja6X1cfsAjfl",
                        "name": "Ado",
                        "type": "artist",
                        "uri": "spotify:artist:6mEQK9m2krja6X1cfsAjfl"
                    }
                ],
                "disc_number": 1,
                "duration_ms": 189772,
                "explicit": false,
                "external_ids": {
                    "isrc": "JPPO02302806"
                },
                "external_urls": {
                    "spotify": "https://open.spotify.com/track/7o0TPSw494RG2Q4iWmd1v6"
                },
                "href": "https://api.spotify.com/v1/tracks/7o0TPSw494RG2Q4iWmd1v6",
                "id": "7o0TPSw494RG2Q4iWmd1v6",
                "is_playable": true,
                "name": "唱",
                "popularity": 71,
                "preview_url": null,
                "track_number": 2,
                "type": "track",
                "uri": "spotify:track:7o0TPSw494RG2Q4iWmd1v6",
                "is_local": false
            },
            {
                "album": {
                    "album_type": "album",
                    "total_tracks": 19,
                    "external_urls": {
                        "spotify": "https://open.spotify.com/album/3rDo7fQDUwJ6qmxwP5yQsY"
                    },
                    "href": "https://api.spotify.com/v1/albums/3rDo7fQDUwJ6qmxwP5yQsY",
                    "id": "3rDo7fQDUwJ6qmxwP5yQsY",
                    "images": [
                        {
                            "url": "https://i.scdn.co/image/ab67616d0000b273a68c06155b7c3cf82b00cb96",
                            "height": 640,
                            "width": 640
                        },
                        {
                            "url": "https://i.scdn.co/image/ab67616d00001e02a68c06155b7c3cf82b00cb96",
                            "height": 300,
                            "width": 300
                        },
                        {
                            "url": "https://i.scdn.co/image/ab67616d00004851a68c06155b7c3cf82b00cb96",
                            "height": 64,
                            "width": 64
                        }
                    ],
                    "name": "Home Alone (Original Motion Picture Soundtrack) [Anniversary Edition]",
                    "release_date": "1990",
                    "release_date_precision": "year",
                    "type": "album",
                    "uri": "spotify:album:3rDo7fQDUwJ6qmxwP5yQsY",
                    "artists": [
                        {
                            "external_urls": {
                                "spotify": "https://open.spotify.com/artist/3dRfiJ2650SZu6GbydcHNb"
                            },
                            "href": "https://api.spotify.com/v1/artists/3dRfiJ2650SZu6GbydcHNb",
                            "id": "3dRfiJ2650SZu6GbydcHNb",
                            "name": "ジョン・ウィリアムズ",
                            "type": "artist",
                            "uri": "spotify:artist:3dRfiJ2650SZu6GbydcHNb"
                        }
                    ],
                    "is_playable": true
                },
                "artists": [
                    {
                        "external_urls": {
                            "spotify": "https://open.spotify.com/artist/71VUVLmoTKKYfIugkavMeS"
                        },
                        "href": "https://api.spotify.com/v1/artists/71VUVLmoTKKYfIugkavMeS",
                        "id": "71VUVLmoTKKYfIugkavMeS",
                        "name": "アドルフ・アダン",
                        "type": "artist",
                        "uri": "spotify:artist:71VUVLmoTKKYfIugkavMeS"
                    },
                    {
                        "external_urls": {
                            "spotify": "https://open.spotify.com/artist/3dRfiJ2650SZu6GbydcHNb"
                        },
                        "href": "https://api.spotify.com/v1/artists/3dRfiJ2650SZu6GbydcHNb",
                        "id": "3dRfiJ2650SZu6GbydcHNb",
                        "name": "ジョン・ウィリアムズ",
                        "type": "artist",
                        "uri": "spotify:artist:3dRfiJ2650SZu6GbydcHNb"
                    }
                ],
                "disc_number": 1,
                "duration_ms": 167760,
                "explicit": false,
                "external_ids": {
                    "isrc": "USSM19912813"
                },
                "external_urls": {
                    "spotify": "https://open.spotify.com/track/11Hq1xTlR8Bgm3Pgv9EqGs"
                },
                "href": "https://api.spotify.com/v1/tracks/11Hq1xTlR8Bgm3Pgv9EqGs",
                "id": "11Hq1xTlR8Bgm3Pgv9EqGs",
                "is_playable": true,
                "name": "O Holy Night",
                "popularity": 38,
                "preview_url": "https://p.scdn.co/mp3-preview/2e83a9bee9468de6d1922d4e0cc917587ff6854a?cid=cfe923b2d660439caf2b557b21f31221",
                "track_number": 11,
                "type": "track",
                "uri": "spotify:track:11Hq1xTlR8Bgm3Pgv9EqGs",
                "is_local": false
            },
            {
                "album": {
                    "album_type": "album",
                    "total_tracks": 12,
                    "external_urls": {
                        "spotify": "https://open.spotify.com/album/1xSt8N8LCvgNwipvi77UBk"
                    },
                    "href": "https://api.spotify.com/v1/albums/1xSt8N8LCvgNwipvi77UBk",
                    "id": "1xSt8N8LCvgNwipvi77UBk",
                    "images": [
                        {
                            "url": "https://i.scdn.co/image/ab67616d0000b273b66c01fd7a3a7a1832598c60",
                            "height": 640,
                            "width": 640
                        },
                        {
                            "url": "https://i.scdn.co/image/ab67616d00001e02b66c01fd7a3a7a1832598c60",
                            "height": 300,
                            "width": 300
                        },
                        {
                            "url": "https://i.scdn.co/image/ab67616d00004851b66c01fd7a3a7a1832598c60",
                            "height": 64,
                            "width": 64
                        }
                    ],
                    "name": "Favorite Fix",
                    "release_date": "2010-01-01",
                    "release_date_precision": "day",
                    "type": "album",
                    "uri": "spotify:album:1xSt8N8LCvgNwipvi77UBk",
                    "artists": [
                        {
                            "external_urls": {
                                "spotify": "https://open.spotify.com/artist/3kYFawNQVZ00FQbgs4rVBe"
                            },
                            "href": "https://api.spotify.com/v1/artists/3kYFawNQVZ00FQbgs4rVBe",
                            "id": "3kYFawNQVZ00FQbgs4rVBe",
                            "name": "Artist Vs Poet",
                            "type": "artist",
                            "uri": "spotify:artist:3kYFawNQVZ00FQbgs4rVBe"
                        }
                    ],
                    "is_playable": true
                },
                "artists": [
                    {
                        "external_urls": {
                            "spotify": "https://open.spotify.com/artist/3kYFawNQVZ00FQbgs4rVBe"
                        },
                        "href": "https://api.spotify.com/v1/artists/3kYFawNQVZ00FQbgs4rVBe",
                        "id": "3kYFawNQVZ00FQbgs4rVBe",
                        "name": "Artist Vs Poet",
                        "type": "artist",
                        "uri": "spotify:artist:3kYFawNQVZ00FQbgs4rVBe"
                    }
                ],
                "disc_number": 1,
                "duration_ms": 212146,
                "explicit": false,
                "external_ids": {
                    "isrc": "US5261013602"
                },
                "external_urls": {
                    "spotify": "https://open.spotify.com/track/6XkLdAGky28Ju6Rmr1gZBA"
                },
                "href": "https://api.spotify.com/v1/tracks/6XkLdAGky28Ju6Rmr1gZBA",
                "id": "6XkLdAGky28Ju6Rmr1gZBA",
                "is_playable": true,
                "name": "Adorable",
                "popularity": 24,
                "preview_url": null,
                "track_number": 2,
                "type": "track",
                "uri": "spotify:track:6XkLdAGky28Ju6Rmr1gZBA",
                "is_local": false
            },
            {
                "album": {
                    "album_type": "single",
                    "total_tracks": 7,
                    "external_urls": {
                        "spotify": "https://open.spotify.com/album/2UmsJK8DpFC2GK1vtFEVwv"
                    },
                    "href": "https://api.spotify.com/v1/albums/2UmsJK8DpFC2GK1vtFEVwv",
                    "id": "2UmsJK8DpFC2GK1vtFEVwv",
                    "images": [
                        {
                            "url": "https://i.scdn.co/image/ab67616d0000b273eb3ce01e22846f2ebb8473e4",
                            "height": 640,
                            "width": 640
                        },
                        {
                            "url": "https://i.scdn.co/image/ab67616d00001e02eb3ce01e22846f2ebb8473e4",
                            "height": 300,
                            "width": 300
                        },
                        {
                            "url": "https://i.scdn.co/image/ab67616d00004851eb3ce01e22846f2ebb8473e4",
                            "height": 64,
                            "width": 64
                        }
                    ],
                    "name": "INSTANT",
                    "release_date": "2019-10-21",
                    "release_date_precision": "day",
                    "type": "album",
                    "uri": "spotify:album:2UmsJK8DpFC2GK1vtFEVwv",
                    "artists": [
                        {
                            "external_urls": {
                                "spotify": "https://open.spotify.com/artist/7nq2NwlzVsllu1h5qHPxIy"
                            },
                            "href": "https://api.spotify.com/v1/artists/7nq2NwlzVsllu1h5qHPxIy",
                            "id": "7nq2NwlzVsllu1h5qHPxIy",
                            "name": "YUNHWAY",
                            "type": "artist",
                            "uri": "spotify:artist:7nq2NwlzVsllu1h5qHPxIy"
                        }
                    ],
                    "is_playable": true
                },
                "artists": [
                    {
                        "external_urls": {
                            "spotify": "https://open.spotify.com/artist/7nq2NwlzVsllu1h5qHPxIy"
                        },
                        "href": "https://api.spotify.com/v1/artists/7nq2NwlzVsllu1h5qHPxIy",
                        "id": "7nq2NwlzVsllu1h5qHPxIy",
                        "name": "YUNHWAY",
                        "type": "artist",
                        "uri": "spotify:artist:7nq2NwlzVsllu1h5qHPxIy"
                    }
                ],
                "disc_number": 1,
                "duration_ms": 174054,
                "explicit": false,
                "external_ids": {
                    "isrc": "KRA381904513"
                },
                "external_urls": {
                    "spotify": "https://open.spotify.com/track/7pYJMnCdoR3unnLYQ3jB8q"
                },
                "href": "https://api.spotify.com/v1/tracks/7pYJMnCdoR3unnLYQ3jB8q",
                "id": "7pYJMnCdoR3unnLYQ3jB8q",
                "is_playable": true,
                "name": "Adolescent",
                "popularity": 17,
                "preview_url": "https://p.scdn.co/mp3-preview/d517bce159089c4a3d32ebcfbb33e08efe4a6b16?cid=cfe923b2d660439caf2b557b21f31221",
                "track_number": 3,
                "type": "track",
                "uri": "spotify:track:7pYJMnCdoR3unnLYQ3jB8q",
                "is_local": false
            },
            {
                "album": {
                    "album_type": "album",
                    "total_tracks": 33,
                    "external_urls": {
                        "spotify": "https://open.spotify.com/album/7dXJjabk2Fcn4lE3g3VpPU"
                    },
                    "href": "https://api.spotify.com/v1/albums/7dXJjabk2Fcn4lE3g3VpPU",
                    "id": "7dXJjabk2Fcn4lE3g3VpPU",
                    "images": [
                        {
                            "url": "https://i.scdn.co/image/ab67616d0000b273127aebe2e001447cfe8b5b10",
                            "height": 640,
                            "width": 640
                        },
                        {
                            "url": "https://i.scdn.co/image/ab67616d00001e02127aebe2e001447cfe8b5b10",
                            "height": 300,
                            "width": 300
                        },
                        {
                            "url": "https://i.scdn.co/image/ab67616d00004851127aebe2e001447cfe8b5b10",
                            "height": 64,
                            "width": 64
                        }
                    ],
                    "name": "Femmes",
                    "release_date": "2023-02-03",
                    "release_date_precision": "day",
                    "type": "album",
                    "uri": "spotify:album:7dXJjabk2Fcn4lE3g3VpPU",
                    "artists": [
                        {
                            "external_urls": {
                                "spotify": "https://open.spotify.com/artist/1MBdqvpYGau9IvRqwsSS50"
                            },
                            "href": "https://api.spotify.com/v1/artists/1MBdqvpYGau9IvRqwsSS50",
                            "id": "1MBdqvpYGau9IvRqwsSS50",
                            "name": "Raphaela Gromes",
                            "type": "artist",
                            "uri": "spotify:artist:1MBdqvpYGau9IvRqwsSS50"
                        },
                        {
                            "external_urls": {
                                "spotify": "https://open.spotify.com/artist/0sABleOLUMLgjJa6mpIaVc"
                            },
                            "href": "https://api.spotify.com/v1/artists/0sABleOLUMLgjJa6mpIaVc",
                            "id": "0sABleOLUMLgjJa6mpIaVc",
                            "name": "Lucerne Festival Strings",
                            "type": "artist",
                            "uri": "spotify:artist:0sABleOLUMLgjJa6mpIaVc"
                        },
                        {
                            "external_urls": {
                                "spotify": "https://open.spotify.com/artist/7xblEPvRNj5mqQ1vzV0g2D"
                            },
                            "href": "https://api.spotify.com/v1/artists/7xblEPvRNj5mqQ1vzV0g2D",
                            "id": "7xblEPvRNj5mqQ1vzV0g2D",
                            "name": "Julian Riem",
                            "type": "artist",
                            "uri": "spotify:artist:7xblEPvRNj5mqQ1vzV0g2D"
                        },
                        {
                            "external_urls": {
                                "spotify": "https://open.spotify.com/artist/6o63U8OvSH1UfxT7xEbnEY"
                            },
                            "href": "https://api.spotify.com/v1/artists/6o63U8OvSH1UfxT7xEbnEY",
                            "id": "6o63U8OvSH1UfxT7xEbnEY",
                            "name": "Daniel Dodds",
                            "type": "artist",
                            "uri": "spotify:artist:6o63U8OvSH1UfxT7xEbnEY"
                        }
                    ],
                    "is_playable": true
                },
                "artists": [
                    {
                        "external_urls": {
                            "spotify": "https://open.spotify.com/artist/1M9s5TbPcKurMEzvvW0FFH"
                        },
                        "href": "https://api.spotify.com/v1/artists/1M9s5TbPcKurMEzvvW0FFH",
                        "id": "1M9s5TbPcKurMEzvvW0FFH",
                        "name": "Florence Beatrice Price",
                        "type": "artist",
                        "uri": "spotify:artist:1M9s5TbPcKurMEzvvW0FFH"
                    },
                    {
                        "external_urls": {
                            "spotify": "https://open.spotify.com/artist/1MBdqvpYGau9IvRqwsSS50"
                        },
                        "href": "https://api.spotify.com/v1/artists/1MBdqvpYGau9IvRqwsSS50",
                        "id": "1MBdqvpYGau9IvRqwsSS50",
                        "name": "Raphaela Gromes",
                        "type": "artist",
                        "uri": "spotify:artist:1MBdqvpYGau9IvRqwsSS50"
                    },
                    {
                        "external_urls": {
                            "spotify": "https://open.spotify.com/artist/0sABleOLUMLgjJa6mpIaVc"
                        },
                        "href": "https://api.spotify.com/v1/artists/0sABleOLUMLgjJa6mpIaVc",
                        "id": "0sABleOLUMLgjJa6mpIaVc",
                        "name": "Lucerne Festival Strings",
                        "type": "artist",
                        "uri": "spotify:artist:0sABleOLUMLgjJa6mpIaVc"
                    },
                    {
                        "external_urls": {
                            "spotify": "https://open.spotify.com/artist/6o63U8OvSH1UfxT7xEbnEY"
                        },
                        "href": "https://api.spotify.com/v1/artists/6o63U8OvSH1UfxT7xEbnEY",
                        "id": "6o63U8OvSH1UfxT7xEbnEY",
                        "name": "Daniel Dodds",
                        "type": "artist",
                        "uri": "spotify:artist:6o63U8OvSH1UfxT7xEbnEY"
                    }
                ],
                "disc_number": 1,
                "duration_ms": 199573,
                "explicit": false,
                "external_ids": {
                    "isrc": "DEE862201853"
                },
                "external_urls": {
                    "spotify": "https://open.spotify.com/track/7BXEyMmzTPhGVtRmcNC1pK"
                },
                "href": "https://api.spotify.com/v1/tracks/7BXEyMmzTPhGVtRmcNC1pK",
                "id": "7BXEyMmzTPhGVtRmcNC1pK",
                "is_playable": true,
                "name": "Adoration (Arr. for Cello & Orchestra by Julian Riem)",
                "popularity": 38,
                "preview_url": "https://p.scdn.co/mp3-preview/9b8ab9c19e7a366aa7bedf592df01554de653a0e?cid=cfe923b2d660439caf2b557b21f31221",
                "track_number": 14,
                "type": "track",
                "uri": "spotify:track:7BXEyMmzTPhGVtRmcNC1pK",
                "is_local": false
            },
            {
                "album": {
                    "album_type": "album",
                    "total_tracks": 94,
                    "external_urls": {
                        "spotify": "https://open.spotify.com/album/1UWbPxdx60LnVoFYGsLxMQ"
                    },
                    "href": "https://api.spotify.com/v1/albums/1UWbPxdx60LnVoFYGsLxMQ",
                    "id": "1UWbPxdx60LnVoFYGsLxMQ",
                    "images": [
                        {
                            "url": "https://i.scdn.co/image/ab67616d0000b273a226dd16aa52504094b08501",
                            "height": 640,
                            "width": 640
                        },
                        {
                            "url": "https://i.scdn.co/image/ab67616d00001e02a226dd16aa52504094b08501",
                            "height": 300,
                            "width": 300
                        },
                        {
                            "url": "https://i.scdn.co/image/ab67616d00004851a226dd16aa52504094b08501",
                            "height": 64,
                            "width": 64
                        }
                    ],
                    "name": "Afternoon at the Beach",
                    "release_date": "2024-06-23",
                    "release_date_precision": "day",
                    "type": "album",
                    "uri": "spotify:album:1UWbPxdx60LnVoFYGsLxMQ",
                    "artists": [
                        {
                            "external_urls": {
                                "spotify": "https://open.spotify.com/artist/4NJhFmfw43RLBLjQvxDuRS"
                            },
                            "href": "https://api.spotify.com/v1/artists/4NJhFmfw43RLBLjQvxDuRS",
                            "id": "4NJhFmfw43RLBLjQvxDuRS",
                            "name": "ヴォルフガング・アマデウス・モーツァルト",
                            "type": "artist",
                            "uri": "spotify:artist:4NJhFmfw43RLBLjQvxDuRS"
                        },
                        {
                            "external_urls": {
                                "spotify": "https://open.spotify.com/artist/5wTAi7QkpP6kp8a54lmTOq"
                            },
                            "href": "https://api.spotify.com/v1/artists/5wTAi7QkpP6kp8a54lmTOq",
                            "id": "5wTAi7QkpP6kp8a54lmTOq",
                            "name": "ヨハネス・ブラームス",
                            "type": "artist",
                            "uri": "spotify:artist:5wTAi7QkpP6kp8a54lmTOq"
                        },
                        {
                            "external_urls": {
                                "spotify": "https://open.spotify.com/artist/5aIqB5nVVvmFsvSdExz408"
                            },
                            "href": "https://api.spotify.com/v1/artists/5aIqB5nVVvmFsvSdExz408",
                            "id": "5aIqB5nVVvmFsvSdExz408",
                            "name": "J.S.バッハ",
                            "type": "artist",
                            "uri": "spotify:artist:5aIqB5nVVvmFsvSdExz408"
                        },
                        {
                            "external_urls": {
                                "spotify": "https://open.spotify.com/artist/2wOqMjp9TyABvtHdOSOTUS"
                            },
                            "href": "https://api.spotify.com/v1/artists/2wOqMjp9TyABvtHdOSOTUS",
                            "id": "2wOqMjp9TyABvtHdOSOTUS",
                            "name": "ルートヴィヒ・ヴァン・ベートーヴェン",
                            "type": "artist",
                            "uri": "spotify:artist:2wOqMjp9TyABvtHdOSOTUS"
                        }
                    ],
                    "is_playable": true
                },
                "artists": [
                    {
                        "external_urls": {
                            "spotify": "https://open.spotify.com/artist/2wOqMjp9TyABvtHdOSOTUS"
                        },
                        "href": "https://api.spotify.com/v1/artists/2wOqMjp9TyABvtHdOSOTUS",
                        "id": "2wOqMjp9TyABvtHdOSOTUS",
                        "name": "ルートヴィヒ・ヴァン・ベートーヴェン",
                        "type": "artist",
                        "uri": "spotify:artist:2wOqMjp9TyABvtHdOSOTUS"
                    },
                    {
                        "external_urls": {
                            "spotify": "https://open.spotify.com/artist/003f4bk13c6Q3gAUXv7dGJ"
                        },
                        "href": "https://api.spotify.com/v1/artists/003f4bk13c6Q3gAUXv7dGJ",
                        "id": "003f4bk13c6Q3gAUXv7dGJ",
                        "name": "ウィーン・フィルハーモニー管弦楽団",
                        "type": "artist",
                        "uri": "spotify:artist:003f4bk13c6Q3gAUXv7dGJ"
                    },
                    {
                        "external_urls": {
                            "spotify": "https://open.spotify.com/artist/2LmyJyCF5V1eQyvHgJNbTn"
                        },
                        "href": "https://api.spotify.com/v1/artists/2LmyJyCF5V1eQyvHgJNbTn",
                        "id": "2LmyJyCF5V1eQyvHgJNbTn",
                        "name": "レナード・バーンスタイン",
                        "type": "artist",
                        "uri": "spotify:artist:2LmyJyCF5V1eQyvHgJNbTn"
                    }
                ],
                "disc_number": 1,
                "duration_ms": 54120,
                "explicit": false,
                "external_ids": {
                    "isrc": "DEF057701643"
                },
                "external_urls": {
                    "spotify": "https://open.spotify.com/track/56oHSP18ZUjc5rIZcdwkJO"
                },
                "href": "https://api.spotify.com/v1/tracks/56oHSP18ZUjc5rIZcdwkJO",
                "id": "56oHSP18ZUjc5rIZcdwkJO",
                "is_playable": true,
                "name": "String Quartet No. 14 in C-Sharp Minor, Op. 131 (Arr. Mitropoulos for String Orchestra): III. Allegro moderato – - Live",
                "popularity": 21,
                "preview_url": null,
                "track_number": 7,
                "type": "track",
                "uri": "spotify:track:56oHSP18ZUjc5rIZcdwkJO",
                "is_local": false
            }
        ]
    }
}
*/
