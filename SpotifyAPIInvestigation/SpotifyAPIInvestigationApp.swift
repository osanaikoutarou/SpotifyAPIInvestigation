//
//  SpotifyAPIInvestigationApp.swift
//  SpotifyAPIInvestigation
//
//  Created by 長内幸太郎 on 2024/06/24.
//

// Docs
// https://developer.spotify.com/documentation/ios
// https://developer.spotify.com/documentation/ios/getting-started

// Dashboard
// https://developer.spotify.com/dashboard

// Spotify iOS SDK
// バックグラウンドで実行されているSpotifyアプリとやり取りして、音楽再生や情報取得を行うためのSDK
// 1.ダッシュボードでのアプリ登録
//   name,descriptioin,Redirect URLs,Bundle IDs
//   Client ID
// 2.Info.plistの設定
// 3.Other Linker Flagsの設定
// 4.-Bridge-Header.hを追加
// 5.SpotifyiOS SDKを追加


import SwiftUI
import SpotifyiOS

@main
struct SpotifyAPIInvestigationApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    print("onOpenURL", url)

                    let parameters = SpotifyManager.shared.appRemote.authorizationParameters(from: url);

                    if let access_token = parameters?[SPTAppRemoteAccessTokenKey] {
                        SpotifyManager.shared.appRemote.connectionParameters.accessToken = access_token
                        SpotifyManager.shared.accessToken = access_token
                    } else if (parameters?[SPTAppRemoteErrorDescriptionKey]) != nil {
                        // Show the error
                        print("error")
                    }
                }
        }
    }
}


class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    //MARK: -

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        print("didFinishLaunchingWithOptions")
        return true
    }
}
