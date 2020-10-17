//
//  TestLocationViewController.swift
//  Example
//
//  Created by wuyong on 2020/3/18.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import FWFramework

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
        FWLocationManager.sharedInstance.locationChanged = { [weak self] (manager) in
            if manager.error != nil {
                self?.resultLabel.text = manager.error?.localizedDescription
            } else {
                self?.resultLabel.text = FWLocationStringWithCoordinate(manager.location?.coordinate ?? CLLocationCoordinate2DMake(0, 0));
            }
        }
    }
    
    override func renderData() {
        let json: FWJSON = FWJSON([
            "array": [12.34, 56.78],
            "users": [
                [
                    "id": 987654,
                    "info": [
                        "name": "jack",
                        "email": "jack@gmail.com"
                    ],
                    "feeds": [98833, 23443, 213239, 23232]
                ],
                [
                    "id": 654321,
                    "info": [
                        "name": "jeffgukang",
                        "email": "jeffgukang@gmail.com"
                    ],
                    "feeds": [12345, 56789, 12423, 12412]
                ]
            ]
            ])

        let _ = json["array"][0].double

        let arrayOfString = json["users"].arrayValue.map({$0["info"]["name"]})
        print(arrayOfString)

        let _ = json["users"][0]["info"]["name"].stringValue
        let _ = ["users", 1, "info", "name"] as [FWJSONSubscriptType]
        let _ = json["users", 1, "info", "name"].string

        let keys: [FWJSONSubscriptType] = ["users", 1, "info", "name"]
        let _ = json[keys].string

        let _ = json["users"][1]["info"]["name"].string
        let _ = json["users", 1, "info", "name"].string
        
        for (key, subJson):(String, FWJSON) in json {
            print(key)
            print(subJson)
        }

        for (index, subJson):(String, FWJSON) in json["array"] {
            print("\(index): \(subJson)")
        }
        
        let errorJson = FWJSON(["name", "age"])
        if let name = errorJson[999].string {
            print(name)
        } else {
            print(errorJson[999].error!)
        }

        let errorJson2 = FWJSON(["name": "Jack", "age": 25])
        if let name = errorJson2["address"].string {
            print(name)
        } else {
            print(errorJson2["address"].error!)
        }

        let errorJson3 = FWJSON(12345)
        if let age = errorJson3[0].string {
            print(age)
        } else {
            print(errorJson3[0])
            print(errorJson3[0].error!)
        }

        if let name = json["name"].string {
            print(name)
        } else {
            print(json["name"])
            print(json["name"].error!)
        }
    }
}
