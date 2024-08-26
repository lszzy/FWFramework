//
//  TestVideoController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/25.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestVideoController: UIViewController, ViewControllerProtocol {
    // MARK: - Accessor
    fileprivate var player = VideoPlayer()
    lazy var resourceLoader = PlayerCacheLoaderManager()

    @StoredValue("TestVideoCacheEnabled")
    private var cacheEnabled: Bool = false

    @StoredValue("TestVideoUrl")
    private var videoUrl: String = ""

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        player.playerDelegate = self
        player.playbackDelegate = self

        player.playerView.playerBackgroundColor = AppTheme.backgroundColor

        addChild(player)
        view.addSubview(player.view)
        player.view.layoutChain.edges()
        player.didMove(toParent: self)

        playVideo()
        player.playbackLoops = true

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGestureRecognizer(_:)))
        tapGestureRecognizer.numberOfTapsRequired = 1
        player.view.addGestureRecognizer(tapGestureRecognizer)

        app.showLoading()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        player.willMove(toParent: nil)
        player.view.removeFromSuperview()
        player.removeFromParent()
    }

    // MARK: - Private
    func setupNavbar() {
        app.setRightBarItem(UIBarButtonItem.SystemItem.action.rawValue) { [weak self] _ in
            guard let self else { return }

            app.showSheet(title: nil, message: nil, actions: [
                cacheEnabled ? "禁用缓存" : "启用缓存",
                "自定义视频URL"
            ], actionBlock: { [weak self] index in
                guard let self else { return }

                if index == 0 {
                    cacheEnabled = !cacheEnabled
                    if !cacheEnabled {
                        FileManager.app.removeItem(atPath: PlayerCacheManager.cacheDirectory)
                    }
                    playVideo()
                } else {
                    app.showPrompt(title: "请输入视频URL", message: nil) { [weak self] textField in
                        guard let self else { return }

                        textField.text = !videoUrl.isEmpty ? videoUrl : "http://vjs.zencdn.net/v/oceans.mp4"
                    } confirmBlock: { [weak self] text in
                        self?.videoUrl = text
                        self?.playVideo()
                    }
                }
            })
        }
    }

    private func playVideo() {
        var url: URL?
        if !videoUrl.isEmpty {
            url = URL.app.url(string: videoUrl)
        } else {
            url = Bundle.main.url(forResource: "Video", withExtension: "mp4")
        }
        guard let url else { return }

        if cacheEnabled {
            player.asset = resourceLoader.urlAsset(url: url)
        } else {
            player.url = url
        }
    }

    @objc func handleTapGestureRecognizer(_ gestureRecognizer: UITapGestureRecognizer) {
        switch player.playbackState {
        case .stopped:
            player.playFromBeginning()
        case .paused:
            player.playFromCurrentTime()
        case .playing:
            player.pause()
        case .failed:
            player.pause()
        }
    }
}

extension TestVideoController: VideoPlayerDelegate, VideoPlayerPlaybackDelegate {
    func playerReady(_ player: VideoPlayer) {
        print("\(#function) ready")

        app.hideLoading()
    }

    func playerPlaybackStateDidChange(_ player: VideoPlayer) {
        print("\(#function) \(player.playbackState.rawValue)")
    }

    func player(_ player: VideoPlayer, didFailWithError error: Error?) {
        print("\(#function) error.description")

        app.hideLoading()
    }
}

class TestPlayerView: VideoPlayerView, VideoPlayerDelegate {
    static func videoPlayer() -> VideoPlayer {
        let result = VideoPlayer()
        result.modalPresentationStyle = .fullScreen
        let playerView = TestPlayerView(frame: .zero)
        playerView.videoPlayer = result
        result.playerView = playerView
        return result
    }

    weak var videoPlayer: VideoPlayer? {
        didSet {
            videoPlayer?.playerDelegate = self
        }
    }

    private lazy var closeButton: ToolbarButton = {
        let result = ToolbarButton(image: Icon.closeImage)
        result.tintColor = AppTheme.textColor
        result.app.addTouch { _ in
            Navigator.close(animated: true)
        }
        return result
    }()

    private lazy var playButton: ToolbarButton = {
        let result = ToolbarButton(image: APP.iconImage("zdmi-var-play", 24))
        result.tintColor = AppTheme.textColor
        result.app.addTouch { [weak self] _ in
            guard let player = self?.videoPlayer else { return }

            if player.playbackState == .playing {
                player.pause()
            } else if player.playbackState == .paused {
                player.playFromCurrentTime()
            } else {
                player.playFromBeginning()
            }
        }
        return result
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = AppTheme.backgroundColor

        addSubview(closeButton)
        addSubview(playButton)
        closeButton.app.layoutChain.left(toSafeArea: 8).top(toSafeArea: 8)
        playButton.app.layoutChain.right(toSafeArea: 8).top(toSafeArea: 8)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func playerPlaybackStateDidChange(_ player: VideoPlayer) {
        if player.playbackState == .playing {
            playButton.setImage(APP.iconImage("zdmi-var-pause", 24), for: .normal)
        } else {
            playButton.setImage(APP.iconImage("zdmi-var-play", 24), for: .normal)
        }
    }
}
