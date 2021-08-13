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
    lazy var resourceLoader = FWPlayerCacheLoaderManager()
    
    @FWUserDefaultAnnotation("TestVideoCacheEnabled", defaultValue: false)
    private var cacheEnabled: Bool
    
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
        
        self.playVideo()
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
    
    override func renderModel() {
        fwSetRightBarItem(cacheEnabled ? "禁用缓存" : "启用缓存") { [weak self] sender in
            guard let strongSelf = self else { return }
            strongSelf.cacheEnabled = !strongSelf.cacheEnabled
            strongSelf.playVideo()
            strongSelf.renderModel()
        }
    }
    
    private func playVideo() {
        let videoUrl = URL(string: "http://vfx.mtime.cn/Video/2019/02/04/mp4/190204084208765161.mp4")!
        if cacheEnabled {
            self.player.asset = resourceLoader.urlAsset(with: videoUrl)
        } else {
            self.player.url = videoUrl
        }
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
