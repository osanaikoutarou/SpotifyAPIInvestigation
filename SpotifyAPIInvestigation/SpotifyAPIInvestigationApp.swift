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
                    // リダイレクト処理 -> token保持

                    print("onOpenURL", url)
                    // spotify-ios-quick-start://spotify-login-callback/?spotify_version=8.9.50.491#access_token=BQDdQjk4EPUrZpQanUYvDH3RKubXmubP3sTiE0hBQBCW_9SdXHx5Y-vjQ4WlgFyOQ24niuonQCneaso13ZoC3eM7Op25tx0oiM1GnPRCC66_lV88inr4KY0DooyWBOTFrXsdIBs6_cY9BmocSIXk2vAOZm8aYspPpFq_WKsNpRRdQ_hXpnd9I2Jvmr_hM0wkr3zx&token_type=Bearer&expires_in=3600

                    let parameters = SpotifyManager.shared.appRemote.authorizationParameters(from: url)

                    if let access_token = parameters?[SPTAppRemoteAccessTokenKey] {
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
        print("AppDelegate: didFinishLaunchingWithOptions")
        return true
    }
}
