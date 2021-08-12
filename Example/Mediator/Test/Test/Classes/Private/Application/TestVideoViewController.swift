//
//  TestVideoViewController.swift
//  Example
//
//  Created by wuyong on 2020/6/5.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import FWFramework

@objcMembers class TestVideoViewController: TestViewController, FWVideoPlayerDelegate, FWVideoPlayerPlaybackDelegate {
    fileprivate var player = FWVideoPlayer()
    
    // MARK: object lifecycle
    deinit {
        self.player.willMove(toParent: nil)
        self.player.view.removeFromSuperview()
        self.player.removeFromParent()
    }

    // MARK: view lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.player.playerDelegate = self
        self.player.playbackDelegate = self
        
        self.player.playerView.playerBackgroundColor = Theme.backgroundColor
        
        self.addChild(self.player)
        self.fwView.addSubview(self.player.view)
        self.player.view.fwPinEdgesToSuperview()
        self.player.didMove(toParent: self)
        
//        let localUrl = Bundle.main.url(forResource: "IMG_3267", withExtension: "MOV")
//        self.player.url = localUrl
        let videoUrl = URL(string: "https://v.cdn.vine.co/r/videos/AA3C120C521177175800441692160_38f2cbd1ffb.1.5.13763579289575020226.mp4")!
        self.player.url = videoUrl
        
        self.player.playbackLoops = true
        
        let tapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGestureRecognizer(_:)))
        tapGestureRecognizer.numberOfTapsRequired = 1
        self.player.view.addGestureRecognizer(tapGestureRecognizer)
        
        fwShowLoading()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.player.playFromBeginning()
    }
    
    // MARK: -
    
    @objc func handleTapGestureRecognizer(_ gestureRecognizer: UITapGestureRecognizer) {
        switch self.player.playbackState {
        case .stopped:
            self.player.playFromBeginning()
            break
        case .paused:
            self.player.playFromCurrentTime()
            break
        case .playing:
            self.player.pause()
            break
        case .failed:
            self.player.pause()
            break
        }
    }
    
    func playerReady(_ player: FWVideoPlayer) {
        print("\(#function) ready")
        
        fwHideLoading()
    }
    
    func playerPlaybackStateDidChange(_ player: FWVideoPlayer) {
        print("\(#function) \(player.playbackState.rawValue)")
    }
    
    func player(_ player: FWVideoPlayer, didFailWithError error: Error?) {
        print("\(#function) error.description")
        
        fwHideLoading()
    }
}
