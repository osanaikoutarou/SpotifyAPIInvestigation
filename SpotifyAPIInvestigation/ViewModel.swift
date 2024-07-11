//
//  ViewModel.swift
//  SpotifyAPIInvestigation
//
//  Created by 長内幸太郎 on 2024/07/12.
//

import Foundation
import SpotifyiOS

class ViewModel: NSObject, ObservableObject {
    @Published var secret: String = "f38984ba02e6490eb9bae628be68cf87"   //78fc

    @Published var currentSPTAppRemotePlayerState: SPTAppRemotePlayerState?
    @Published var currentTrack: SPTAppRemoteTrack?
    @Published var trackItems: [TrackItem] = []
    @Published var currentTrackImage: UIImage? = nil

    @Published var token: String?
    @Published var searchQuery: String = "track:怪獣の花唄"
    @Published var playUrl: String = ""
    @Published var isConnected: Bool = false

    func inject(appRemote: SPTAppRemote) {
        appRemote.delegate = self
    }
}

extension ViewModel {
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

extension ViewModel: SPTAppRemoteDelegate {
    // SPTAppRemoteDelegate methods
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        print("Connected")

        appRemote.playerAPI?.delegate = self
        appRemote.playerAPI?.subscribe(toPlayerState: { (result, error) in
            print(result)
            if let error = error {
                print(error.localizedDescription)
            } else {
                print("success subscribe")
            }
        })

        NotificationCenter.default.post(name: Notification.Name.SPTAppRemoteConnected, object: self)
    }
    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        print("Disconnected")
        NotificationCenter.default.post(name: Notification.Name.SPTAppRemoteDisConnected, object: self)

    }

    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        print("Failed to connect", error?.localizedDescription)
    }
}

extension ViewModel: SPTAppRemotePlayerStateDelegate {
    func playerStateDidChange(_ playerState: any SPTAppRemotePlayerState) {
        print("playerStateDidChange", playerState)
        self.currentSPTAppRemotePlayerState = playerState

        if let currentSPTAppRemotePlayerState = SpotifyManager.shared.currentSPTAppRemotePlayerState {
            fetchImage(for: currentSPTAppRemotePlayerState.track)
        }

        NotificationCenter.default.post(name: Notification.Name.playerStateDidChange, object: self)
    }
}
