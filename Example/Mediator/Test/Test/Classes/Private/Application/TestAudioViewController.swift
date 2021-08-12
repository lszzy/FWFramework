//
//  TestAudioViewController.swift
//  Example
//
//  Created by wuyong on 2020/6/5.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import FWFramework

@objcMembers class TestAudioViewController: TestViewController, FWAudioPlayerDelegate, FWAudioPlayerDataSource {
    lazy var audioPlayer = FWAudioPlayer.sharedInstance()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        audioPlayer.delegate = self
        audioPlayer.dataSource = self
        audioPlayer.fetchAndPlayPlayerItem(0)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        audioPlayer.destroy()
    }
    
    override func renderData() {
        if audioPlayer.isPlaying() {
            fwSetRightBarItem("暂停") { [weak self] sender in
                self?.audioPlayer.pause()
            }
        } else {
            fwSetRightBarItem("播放") { [weak self] sender in
                self?.audioPlayer.play()
            }
        }
    }
    
    func audioPlayerNumberOfItems() -> Int {
        return 3
    }
    
    func audioPlayerURLForItem(at index: Int, preBuffer: Bool) -> URL {
        var url: URL
        switch index {
            case 0:
                url = URL(string: "http://downsc.chinaz.net/Files/DownLoad/sound1/201906/11582.mp3")!
                break
            case 1:
                url = URL(string: "http://a1136.phobos.apple.com/us/r1000/042/Music5/v4/85/34/8d/85348d57-5bf9-a4a3-9f54-0c3f1d8bc6af/mzaf_5184604190043403959.plus.aac.p.m4a")!
                break
            case 2:
                url = URL(string: "http://a345.phobos.apple.com/us/r1000/046/Music5/v4/52/53/4b/52534b36-620e-d7f3-c9a8-2f9661652ff5/mzaf_2360247732780989514.plus.aac.p.m4a")!
                break
            default:
                    url = URL(string: "")!
                break
        }
        
        return url
    }
    
    func audioPlayerReady(_ identifier: FWAudioPlayerReadyToPlay) {
        switch(identifier) {
            case .currentItem:
                audioPlayer.play()
                renderData()
                break
            default:
                break
        }
    }
    
    func audioPlayerDidReachEnd() {
        renderData()
    }
}
