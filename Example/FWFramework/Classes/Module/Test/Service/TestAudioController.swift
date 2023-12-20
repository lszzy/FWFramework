//
//  TestAudioController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/25.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestAudioController: UIViewController {
    
    // MARK: - Accessor
    lazy var audioPlayer = AudioPlayer.shared
    lazy var resourceLoader = PlayerCacheLoaderManager()
    
    @StoredValue("TestAudioCacheEnabled")
    private var cacheEnabled: Bool = false
    
    // MARK: - Subviews
    private lazy var audioImage: UIImageView = {
        let result = UIImageView()
        result.isUserInteractionEnabled = true
        result.app.addTapGesture { [weak self] sender in
            self?.toggleAudio()
        }
        return result
    }()
    
    private lazy var previousImage: UIImageView = {
        let result = UIImageView()
        result.isHidden = true
        result.image = APP.iconImage("zmdi-var-skip-previous", 100)
        result.isUserInteractionEnabled = true
        result.app.addTapGesture { [weak self] sender in
            self?.playPrevious()
        }
        return result
    }()
    
    private lazy var nextImage: UIImageView = {
        let result = UIImageView()
        result.isHidden = true
        result.image = APP.iconImage("zmdi-var-skip-next", 100)
        result.isUserInteractionEnabled = true
        result.app.addTapGesture { [weak self] sender in
            self?.playNext()
        }
        return result
    }()
    
    private lazy var audioLabel: UILabel = {
        let result = UILabel()
        result.textColor = AppTheme.textColor
        result.textAlignment = .center
        result.numberOfLines = 0
        return result
    }()
    
    // MARK: - Lifecycle
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        audioPlayer.destroyPlayer()
    }
    
}

extension TestAudioController: ViewControllerProtocol {
    
    func setupNavbar() {
        app.setRightBarItem(UIBarButtonItem.SystemItem.action.rawValue) { [weak self] _ in
            guard let self = self else { return }
            
            self.app.showSheet(title: nil, message: nil, actions: [self.audioPlayer.repeatMode == .on ? "关闭循环" : "循环播放", self.audioPlayer.shuffleMode == .on ? "顺序播放" : "随机播放", self.cacheEnabled ? "禁用缓存" : "启用缓存"]) { [weak self] index in
                guard let self = self else { return }
                
                if index == 0 {
                    self.audioPlayer.repeatMode = self.audioPlayer.repeatMode == .on ? .off : .on
                } else if index == 1 {
                    self.audioPlayer.shuffleMode = self.audioPlayer.shuffleMode == .on ? .off : .on
                } else {
                    self.cacheEnabled = !self.cacheEnabled
                    self.audioPlayer.playItem(from: 0)
                    self.renderData()
                }
            }
        }
    }
    
    func setupSubviews() {
        view.addSubview(audioImage)
        view.addSubview(previousImage)
        view.addSubview(nextImage)
        view.addSubview(audioLabel)
    }
    
    func setupLayout() {
        audioImage.app.layoutChain.centerX().size(CGSize(width: 100, height: 100))
            .centerY(toView: view as Any, offset: -58)
        audioLabel.app.layoutChain.centerX().attribute(.top, toAttribute: .centerY, ofView: view, offset: 8)
        
        let margin = (APP.screenWidth - 100.0 * 3) / 4.0
        previousImage.chain.centerY(toView: audioImage).right(toViewLeft: audioImage, offset: -margin).size(CGSize(width: 100, height: 100))
        nextImage.chain.centerY(toView: audioImage).left(toViewRight: audioImage, offset: margin).size(CGSize(width: 100, height: 100))
        
        audioPlayer.delegate = self
        audioPlayer.dataSource = self
        audioPlayer.observePeriodicTime = true
        audioPlayer.playItem(from: 0)
        renderData()
    }
    
    func renderData(ended: Bool = false) {
        if audioPlayer.isPlaying {
            audioImage.image = APP.iconImage("zmdi-var-pause", 100)
        } else {
            audioImage.image = APP.iconImage("zmdi-var-play", 100)
        }
        previousImage.isHidden = audioPlayer.lastItemIndex == 0 || ended
        nextImage.isHidden = audioPlayer.lastItemIndex == audioPlayerNumberOfItems() - 1 || ended
    }
    
    private func toggleAudio() {
        if audioPlayer.isPlaying {
            self.audioPlayer.pause()
        } else {
            if self.audioPlayer.currentItem != nil {
                self.audioPlayer.play()
            } else {
                self.audioPlayer.playItem(from: 0)
            }
        }
        self.renderData()
    }
    
    private func playPrevious() {
        audioPlayer.playPrevious()
    }
    
    private func playNext() {
        audioPlayer.playNext()
    }
    
    func renderLabel() {
        guard let currentItem = audioPlayer.currentItem else {
            audioLabel.text = ""
            return
        }
        
        let indexStr = String(describing: (audioPlayer.getAudioIndex(currentItem) ?? 0) + 1)
        let totalStr = String(describing: audioPlayerNumberOfItems())
        let timeStr = Date.app.formatDuration(TimeInterval(audioPlayer.playingItemCurrentTime), hasHour: false)
        let durationStr = Date.app.formatDuration(TimeInterval(audioPlayer.playingItemDurationTime), hasHour: false)
        audioLabel.text = String(format: "%@/%@\n%@\n%@", indexStr, totalStr, timeStr, durationStr)
    }
    
}

extension TestAudioController: AudioPlayerDelegate, AudioPlayerDataSource {
    
    func audioPlayerNumberOfItems() -> Int {
        return 3
    }
    
    func audioPlayerURLForItem(at index: Int, preBuffer: Bool) -> Any? {
        var url: URL?
        switch index {
            case 0:
                url = Bundle.main.url(forResource: "Audio1", withExtension: "mp3")
                break
            case 1:
                url = Bundle.main.url(forResource: "Audio2", withExtension: "m4a")
                break
            case 2:
                url = Bundle.main.url(forResource: "Audio3", withExtension: "m4a")
                break
            default:
                break
        }
        
        if let audioUrl = url, cacheEnabled {
            return resourceLoader.urlAsset(with: audioUrl)
        }
        return url
    }
    
    func audioPlayerRateChanged(_ isPlaying: Bool) {
        renderData()
    }
    
    func audioPlayerDidReachEnd() {
        renderData(ended: true)
    }
    
    func audioPlayerCurrentItemChanged(_ item: AVPlayerItem) {
        renderData()
    }
    
    func audioPlayerCurrentTimeChanged(_ time: CMTime) {
        renderLabel()
    }
    
}
