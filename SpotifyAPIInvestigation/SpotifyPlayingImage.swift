//
//  SpotifyPlayingImage.swift
//  SpotifyAPIInvestigation
//
//  Created by 長内幸太郎 on 2024/07/12.
//

import SwiftUI
import UIKit
import SpotifyiOS

struct SpotifyPlayingImage: UIViewRepresentable {
    var image: UIImage

    func makeUIView(context: Context) -> some UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
        uiView.image = image
    }
}
