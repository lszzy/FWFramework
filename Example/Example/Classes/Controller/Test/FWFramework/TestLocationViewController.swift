//
//  TestLocationViewController.swift
//  Example
//
//  Created by wuyong on 2020/3/18.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import Foundation

@objcMembers class TestLocationViewController: BaseViewController {
    lazy var startButton: UIButton = {
        let view = UIButton.fwButton(with: UIFont.appFontNormal(), titleColor: UIColor.appColorBlackOpacityLarge(), title: "Start")
        view.frame = CGRect(x: 20, y: 50, width: 100, height: 50)
        view.fwAddTouch { (sender) in
            FWLocationManager.sharedInstance.startUpdateLocation()
        }
        return view
    }()
    
    lazy var stopButton: UIButton = {
        let view = UIButton.fwButton(with: UIFont.appFontNormal(), titleColor: UIColor.appColorBlackOpacityLarge(), title: "Stop")
        view.frame = CGRect(x: 170, y: 50, width: 100, height: 50)
        view.fwAddTouch { (sender) in
            FWLocationManager.sharedInstance.stopUpdateLocation()
        }
        return view
    }()
    
    lazy var resultLabel: UILabel = {
        let view = UILabel.fwLabel(with: UIFont.appFontNormal(), textColor: UIColor.appColorBlackOpacityLarge(), text: "")
        view.numberOfLines = 0
        view.frame = CGRect(x: 20, y: 100, width: FWScreenWidth - 40, height: 450)
        return view
    }()
    
    override func renderView() {
        view.addSubview(startButton)
        view.addSubview(stopButton)
        view.addSubview(resultLabel)
    }
    
    override func renderModel() {
        fwObserveNotification("FWLocationUpdatedNotification") { [weak self] (notification) in
            self?.resultLabel.text = "\(notification.userInfo ?? [:])"
        }
        fwObserveNotification("FWLocationFailedNotification") { [weak self] (notification) in
            self?.resultLabel.text = "\(notification.userInfo ?? [:])"
        }
    }
}
