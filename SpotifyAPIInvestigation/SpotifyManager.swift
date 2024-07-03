//
//  SpotifyManager.swift
//  SpotifyAPIInvestigation
//
//  Created by 長内幸太郎 on 2024/07/03.
//

import Foundation
import SpotifyiOS
import Alamofire

class SpotifyManager: NSObject {
    static var shared = SpotifyManager()
    
    let SpotifyClientID = "3623294cf27f4dfe831c90917056af15"
    let SpotifyRedirectURL = URL(string: "spotify-ios-quick-start://spotify-login-callback")!
    let secret = "f38984ba02e6490eb9bae628be68cf87"

    // Set Up User Authorization
    var configuration: SPTConfiguration
    var appRemote: SPTAppRemote

    override init() {
        configuration = SPTConfiguration(
            clientID: SpotifyClientID,
            redirectURL: SpotifyRedirectURL
        )
        appRemote = SPTAppRemote(configuration: self.configuration, logLevel: .debug)
        appRemote.connectionParameters.accessToken = self.accessToken
        super.init()
        appRemote.delegate = self
    }

    var accessToken: String? {
        didSet {
            // Update appRemote with new access token
            appRemote.connectionParameters.accessToken = accessToken
        }
    }

    func authorizeAndPlayURI(playUrl: String) {
        appRemote.authorizeAndPlayURI(playUrl)
    }
}

extension SpotifyManager: SPTAppRemoteDelegate {
    // SPTAppRemoteDelegate methods
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        print("Connected")

        appRemote.playerAPI?.delegate = self
        appRemote.playerAPI?.subscribe(toPlayerState: { (result, error) in
            if let error = error {
                debugPrint(error.localizedDescription)
            }
        })
    }
    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        print("Disconnected")
    }

    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        print("Failed to connect", error?.localizedDescription)
    }
}

extension SpotifyManager: SPTAppRemotePlayerStateDelegate {
    func playerStateDidChange(_ playerState: any SPTAppRemotePlayerState) {
        print("playerStateDidChange", playerState)
    }
}

// Web API
// 1.再生制御
// 2.音楽ライブラリの取得
// 3.音楽検索
// 4.おすすめ機能
// 5.新着リリースやチャート
// 6.ユーザ情報の取得・更新

extension SpotifyManager {
    // トークンレスポンス用のモデル
    struct Response: Decodable {
        let access_token: String
        let token_type: String
        let expires_in: Int
    }

    // Base64エンコードされたクライアントIDとクライアントシークレット
    private var credentials: String {
        return "\(SpotifyClientID):\(secret)".data(using: .utf8)!.base64EncodedString()
    }

    // トークン取得
    func fetchAccessToken() async throws {
        let headers: HTTPHeaders = [
            "Authorization": "Basic \(credentials)"
        ]
        let parameters: [String: String] = [
            "grant_type": "client_credentials"
        ]

        let request =  AF.request("https://accounts.spotify.com/api/token",
                                  method: .post,
                                  parameters: parameters,
                                  headers: headers)
        let response = await request.serializingDecodable(Response.self).response

        switch response.result {
        case .success(let tokenResponse):
            accessToken = tokenResponse.access_token
            print("access token", accessToken)
        case .failure(let error):
            throw error
        }
    }
}

struct Tracks: Decodable {
    let items: [TrackItem]
}
struct Artist: Decodable {
    let external_urls: ExternalURL
    let href: String
    let id: String
    let name: String
    let type: String
    let uri: String
}
struct TrackItem: Decodable {
    let album: Album
    let artists: [Artist]
    let available_markets: [String]
    let disc_number: Int
    let duration_ms: Int
    let explicit: Bool
    let external_ids: ExternalID
    let external_urls: ExternalURL
    let href: String
    let id: String
    let is_local: Bool
    let name: String
    let popularity: Int
    let preview_url: String?
    let track_number: Int
    let type: String
    let uri: String
}
struct Album: Decodable {
    let album_type: String
    let total_tracks: Int
    let available_markets: [String]
    let external_urls: ExternalURL
    let href: String
    let id: String
    let images: [Image]
    let name: String
    let release_date: String
    let release_date_precision: String
    let type: String
    let uri: String
}
struct ExternalID: Decodable {
    let isrc: String?
}
struct ExternalURL: Decodable {
    let spotify: String
}
struct Image: Decodable {
    let url: String
    let height: Int?
    let width: Int?
}

extension SpotifyManager {

    struct SearchResponse: Decodable {
        let tracks: Tracks
    }

    // 楽曲検索
    func searchTrack(query: String) async throws -> [TrackItem] {
        guard let accessToken else {
            return []
        }

        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(accessToken)"
        ]

        let parameters: [String: String] = [
            "q": query,
            "type": "track"
        ]

        let response = await AF.request("https://api.spotify.com/v1/search", parameters: parameters, headers: headers).serializingDecodable(SearchResponse.self).response
        switch response.result {
        case .success(let searchResponse):
            return searchResponse.tracks.items
        case .failure(let error):
            throw error
        }
    }
}
