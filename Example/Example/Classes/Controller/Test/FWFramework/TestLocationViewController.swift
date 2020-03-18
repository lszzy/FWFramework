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
        view.frame = CGRect(x: 20, y: 50, width: 60, height: 50)
        view.fwAddTouch { (sender) in
            FWLocationManager.sharedInstance.startUpdateLocation()
        }
        return view
    }()
    
    lazy var stopButton: UIButton = {
        let view = UIButton.fwButton(with: UIFont.appFontNormal(), titleColor: UIColor.appColorBlackOpacityLarge(), title: "Stop")
        view.frame = CGRect(x: 100, y: 50, width: 60, height: 50)
        view.fwAddTouch { (sender) in
            FWLocationManager.sharedInstance.stopUpdateLocation()
        }
        return view
    }()
    
    lazy var configButton: UIButton = {
        let view = UIButton.fwButton(with: UIFont.appFontNormal(), titleColor: UIColor.appColorBlackOpacityLarge(), title: "Once")
        view.frame = CGRect(x: 180, y: 50, width: 60, height: 50)
        view.fwAddTouch { (sender) in
            FWLocationManager.sharedInstance.stopWhenCompleted = !FWLocationManager.sharedInstance.stopWhenCompleted
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
        view.addSubview(configButton)
        view.addSubview(resultLabel)
    }
    
    override func renderModel() {
        FWLocationManager.sharedInstance.locationChanged = { [weak self] in
            if FWLocationManager.sharedInstance.error != nil {
                self?.resultLabel.text = FWLocationManager.sharedInstance.error?.localizedDescription
            } else {
                self?.resultLabel.text = FWLocationStringWithCoordinate(FWLocationManager.sharedInstance.location?.coordinate ?? CLLocationCoordinate2DMake(0, 0));
            }
        }
    }
}
