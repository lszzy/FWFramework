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
    lazy var audioPlayer = AudioPlayer.sharedInstance
    lazy var resourceLoader = PlayerCacheLoaderManager()
    
    @UserDefaultAnnotation("TestAudioCacheEnabled", defaultValue: false)
    private var cacheEnabled: Bool
    
    // MARK: - Subviews
    private lazy var audioImage: UIImageView = {
        let result = UIImageView()
        result.isUserInteractionEnabled = true
        result.fw.addTapGesture { [weak self] sender in
            self?.toggleAudio()
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
        
        audioPlayer.destroy()
    }
    
}

extension TestAudioController: ViewControllerProtocol {
    
    func setupNavbar() {
        fw.setRightBarItem(cacheEnabled ? "禁用缓存" : "启用缓存") { [weak self] sender in
            guard let strongSelf = self else { return }
            strongSelf.cacheEnabled = !strongSelf.cacheEnabled
            strongSelf.audioPlayer.playItem(from: 0)
            strongSelf.renderData()
            strongSelf.setupNavbar()
        }
    }
    
    func setupSubviews() {
        view.addSubview(audioImage)
        view.addSubview(audioLabel)
    }
    
    func setupLayout() {
        audioImage.fw.layoutChain.centerX().size(CGSize(width: 100, height: 100))
            .centerY(toView: view as Any, offset: -58)
        audioLabel.fw.layoutChain.centerX().attribute(.top, toAttribute: .centerY, ofView: view, offset: 8)
        
        audioPlayer.delegate = self
        audioPlayer.dataSource = self
        audioPlayer.observePeriodicTime = true
        audioPlayer.playItem(from: 0)
        renderData()
    }
    
    func renderData() {
        if audioPlayer.isPlaying {
            audioImage.image = FW.iconImage("zmdi-var-pause", 100)
        } else {
            audioImage.image = FW.iconImage("zmdi-var-play", 100)
        }
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
    
    func renderLabel() {
        guard let currentItem = audioPlayer.currentItem else {
            audioLabel.text = ""
            return
        }
        
        let indexStr = String(describing: (audioPlayer.getAudioIndex(currentItem)?.intValue ?? 0) + 1)
        let totalStr = String(describing: audioPlayerNumberOfItems())
        let timeStr = Date.fw.formatDuration(TimeInterval(audioPlayer.playingItemCurrentTime), hasHour: false)
        let durationStr = Date.fw.formatDuration(TimeInterval(audioPlayer.playingItemDurationTime), hasHour: false)
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
                url = URL(string: "http://downsc.chinaz.net/Files/DownLoad/sound1/201906/11582.mp3")
                break
            case 1:
                url = URL(string: "http://a1136.phobos.apple.com/us/r1000/042/Music5/v4/85/34/8d/85348d57-5bf9-a4a3-9f54-0c3f1d8bc6af/mzaf_5184604190043403959.plus.aac.p.m4a")
                break
            case 2:
                url = URL(string: "http://downsc.chinaz.net/files/download/sound1/201206/1638.mp3")
                break
            default:
                break
        }
        
        if let audioUrl = url, cacheEnabled {
            return resourceLoader.urlAsset(with: audioUrl)
        }
        return url
    }
    
    func audioPlayerReady(toPlay item: AVPlayerItem?) {
        if item != nil {
            audioPlayer.play()
            renderData()
        }
    }
    
    func audioPlayerDidReachEnd() {
        renderData()
    }
    
    func audioPlayerCurrentItemChanged(_ item: AVPlayerItem) {
        renderData()
    }
    
    func audioPlayerCurrentTimeChanged(_ time: CMTime) {
        renderLabel()
    }
    
}
