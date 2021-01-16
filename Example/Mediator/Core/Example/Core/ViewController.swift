//
//  ViewController.swift
//  Core
//
//  Created by lingshizhuangzi@gmail.com on 01/15/2021.
//  Copyright (c) 2021 lingshizhuangzi@gmail.com. All rights reserved.
//

import FWFramework
import Core

class ViewController: UIViewController, FWViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "CoreModule Example"
        
        let button = Theme.largeButton()
        button.setTitle("Next", for: .normal)
        button.fwAddTouch { (_) in
            FWRouter.push(ViewController(), animated: true)
        }
        view.addSubview(button)
        button.fwLayoutChain.centerX().top(20)
    }

}

