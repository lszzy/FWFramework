//
//  TestAudioViewController.swift
//  Example
//
//  Created by wuyong on 2020/6/5.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import FWFramework

@objcMembers class TestAudioViewController: TestViewController, FWAudioPlayerDelegate, FWAudioPlayerDataSource {
    lazy var audioPlayer = FWAudioPlayer.sharedInstance
    
    private lazy var audioLabel: UILabel = {
        let result = UILabel()
        result.textColor = Theme.textColor
        result.numberOfLines = 0
        return result
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        fwView.addSubview(audioLabel)
        audioLabel.fwLayoutChain.center()
        
        audioPlayer.delegate = self
        audioPlayer.dataSource = self
        audioPlayer.fetchAndPlayPlayerItem(0)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        audioPlayer.destroy()
    }
    
    override func renderData() {
        if audioPlayer.isPlaying {
            fwSetRightBarItem(FWIconImage("octicon-playback-pause", 24)) { [weak self] sender in
                self?.audioPlayer.pause()
                self?.renderData()
            }
        } else {
            fwSetRightBarItem(FWIconImage("octicon-playback-play", 24)) { [weak self] sender in
                if self?.audioPlayer.currentItem != nil {
                    self?.audioPlayer.play()
                } else {
                    self?.audioPlayer.fetchAndPlayPlayerItem(0)
                }
                self?.renderData()
            }
        }
        
        if let index = audioPlayer.getAudioIndex(audioPlayer.currentItem) {
            audioLabel.text = "\(String(describing: index.intValue + 1))\n\(audioPlayer.playingItemCurrentTime):\(audioPlayer.playingItemDurationTime)"
        } else {
            audioLabel.text = ""
        }
    }
    
    func audioPlayerNumberOfItems() -> Int {
        return 3
    }
    
    func audioPlayerURLForItem(at index: Int, preBuffer: Bool) -> URL? {
        var url: URL?
        switch index {
            case 0:
                url = URL(string: "http://downsc.chinaz.net/Files/DownLoad/sound1/201906/11582.mp3")
                break
            case 1:
                url = URL(string: "http://a1136.phobos.apple.com/us/r1000/042/Music5/v4/85/34/8d/85348d57-5bf9-a4a3-9f54-0c3f1d8bc6af/mzaf_5184604190043403959.plus.aac.p.m4a")
                break
            case 2:
                url = URL(string: "http://a345.phobos.apple.com/us/r1000/046/Music5/v4/52/53/4b/52534b36-620e-d7f3-c9a8-2f9661652ff5/mzaf_2360247732780989514.plus.aac.p.m4a")
                break
            default:
                break
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
}
