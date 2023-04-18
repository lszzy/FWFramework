//
//  TestButtonController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/20.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestButtonController: UIViewController, ViewControllerProtocol {
    
    var count: Int = 0
    
    func setupNavbar() {
        app.extendedLayoutEdge = .bottom
    }
    
    func setupSubviews() {
        var button = UIButton.app.button(title: "Button重复点击", font: APP.font(15), titleColor: AppTheme.textColor)
        button.frame = CGRect(x: 25, y: 15, width: 150, height: 30)
        button.app.highlightedAlpha = UIButton.app.highlightedAlpha
        button.app.addTouch(target: self, action: #selector(onClick1(_:)))
        view.addSubview(button)
        
        var label = UILabel.app.label(font: APP.font(15), textColor: AppTheme.textColor, text: "View重复点击")
        label.textAlignment = .center
        label.isUserInteractionEnabled = true
        label.frame = CGRect(x: 200, y: 15, width: 150, height: 30)
        label.app.addTapGesture(target: self, action: #selector(onClick2(_:))) { gesture in
            gesture.highlightedAlpha = UIButton.app.highlightedAlpha
        }
        view.addSubview(label)
        
        button = UIButton.app.button(title: "Button不可重复点击", font: APP.font(15), titleColor: AppTheme.textColor)
        button.frame = CGRect(x: 25, y: 60, width: 150, height: 30)
        button.app.highlightedAlpha = UIButton.app.highlightedAlpha
        button.app.disabledAlpha = UIButton.app.disabledAlpha
        button.app.addTouch(target: self, action: #selector(onClick3(_:)))
        view.addSubview(button)
        
        label = UILabel.app.label(font: APP.font(15), textColor: AppTheme.textColor, text: "View不可重复点击")
        label.textAlignment = .center
        label.isUserInteractionEnabled = true
        label.frame = CGRect(x: 200, y: 60, width: 150, height: 30)
        label.app.addTapGesture(target: self, action: #selector(onClick4(_:))) { gesture in
            gesture.disabledAlpha = UIButton.app.disabledAlpha
            gesture.highlightedAlpha = UIButton.app.highlightedAlpha
        }
        view.addSubview(label)
        
        button = UIButton.app.button(title: "Button1秒内不可重复点击", font: APP.font(15), titleColor: AppTheme.textColor)
        button.app.touchEventInterval = 1
        button.frame = CGRect(x: 25, y: 105, width: 200, height: 30)
        button.app.highlightedAlpha = UIButton.app.highlightedAlpha
        button.app.addTouch(target: self, action: #selector(onClick5(_:)))
        view.addSubview(button)
        
        let timerButton = UIButton(type: .custom)
        timerButton.frame = CGRect(x: 30, y: 160, width: 80, height: 30)
        timerButton.titleLabel?.font = APP.font(15)
        timerButton.setTitleColor(AppTheme.textColor, for: .normal)
        timerButton.setTitle("=>", for: .normal)
        view.addSubview(timerButton)
        
        let timerButton1 = UIButton(type: .custom)
        timerButton1.frame = CGRect(x: 120, y: 160, width: 80, height: 30)
        timerButton1.titleLabel?.font = APP.font(15)
        timerButton1.setTitleColor(AppTheme.textColor, for: .normal)
        timerButton1.setTitle("=>", for: .normal)
        view.addSubview(timerButton1)
        
        let timerButton2 = UIButton(type: .custom)
        timerButton2.frame = CGRect(x: 220, y: 160, width: 80, height: 30)
        timerButton2.titleLabel?.font = APP.font(15)
        timerButton2.setTitleColor(AppTheme.textColor, for: .normal)
        timerButton2.setTitle("发送", for: .normal)
        view.addSubview(timerButton2)
        var timer1: Timer?
        var timer2: Timer?
        timerButton2.app.addTouch { sender in
            timerButton.app.startCountDown(60, title: "=>", waitTitle: "%lds")
            timer1?.invalidate()
            timer1 = Timer.app.commonTimer(countDown: 60, block: { countDown in
                let title = countDown > 0 ? String(format: "%lds", countDown) : "=>"
                timerButton1.setTitle(title, for: .normal)
            })
            timer2?.invalidate()
            let startTime = Date.app.currentTime
            timer2 = Timer.app.commonTimer(timeInterval: 1, block: { timer in
                let countDown = 60 - Int(round(Date.app.currentTime - startTime))
                if countDown < 1 {
                    timer2?.invalidate()
                }
                let title = countDown > 0 ? String(format: "%lds", countDown) : "发送"
                timerButton2.setTitle(title, for: .normal)
                timerButton2.isEnabled = countDown < 1
            }, repeats: true)
            timer2?.fire()
        }
        
        var button1 = UIButton(type: .system)
        button1.frame = CGRect(x: 25, y: 205, width: 150, height: 50)
        button1.isEnabled = false
        button1.setTitle("System不可点", for: .normal)
        button1.setTitleColor(UIColor.black, for: .normal)
        button1.backgroundColor = APP.color(0xFFDA00)
        button1.app.setCornerRadius(5)
        view.addSubview(button1)
        
        var button2 = UIButton(type: .system)
        button2.frame = CGRect(x: 200, y: 205, width: 150, height: 50)
        button2.setTitle("System可点击", for: .normal)
        button2.setTitleColor(UIColor.black, for: .normal)
        button2.backgroundColor = APP.color(0xFFDA00)
        button2.app.setCornerRadius(5)
        view.addSubview(button2)
        
        var button3 = UIButton(type: .custom)
        button3.frame = CGRect(x: 25, y: 270, width: 150, height: 50)
        button3.isEnabled = false
        button3.setTitle("Custom不可点", for: .normal)
        button3.setTitleColor(UIColor.black, for: .normal)
        button3.backgroundColor = APP.color(0xFFDA00)
        button3.app.setCornerRadius(5)
        view.addSubview(button3)
        
        var button4 = UIButton(type: .custom)
        button4.frame = CGRect(x: 200, y: 270, width: 150, height: 50)
        button4.setTitle("Custom可点击", for: .normal)
        button4.setTitleColor(UIColor.black, for: .normal)
        button4.backgroundColor = APP.color(0xFFDA00)
        button4.app.setCornerRadius(5)
        view.addSubview(button4)
        
        button1 = UIButton(type: .system)
        button1.frame = CGRect(x: 25, y: 335, width: 150, height: 50)
        button1.isEnabled = false
        button1.app.disabledAlpha = UIButton.app.disabledAlpha
        button1.setTitle("System不可点2", for: .normal)
        button1.setTitleColor(UIColor.black, for: .normal)
        button1.backgroundColor = APP.color(0xFFDA00)
        button1.app.setCornerRadius(5)
        view.addSubview(button1)
        
        button2 = UIButton(type: .system)
        button2.frame = CGRect(x: 200, y: 335, width: 150, height: 50)
        button2.app.highlightedAlpha = UIButton.app.highlightedAlpha
        button2.setTitle("System可点击2", for: .normal)
        button2.setTitleColor(UIColor.black, for: .normal)
        button2.backgroundColor = APP.color(0xFFDA00)
        button2.app.setCornerRadius(5)
        view.addSubview(button2)
        
        button3 = UIButton(type: .custom)
        button3.frame = CGRect(x: 25, y: 400, width: 150, height: 50)
        button3.isEnabled = false
        button3.app.disabledAlpha = UIButton.app.disabledAlpha
        button3.app.highlightedAlpha = UIButton.app.highlightedAlpha
        button3.setTitle("Custom不可点2", for: .normal)
        button3.setTitleColor(UIColor.black, for: .normal)
        button3.backgroundColor = APP.color(0xFFDA00)
        button3.app.setCornerRadius(5)
        view.addSubview(button3)
        
        button4 = UIButton(type: .custom)
        button4.frame = CGRect(x: 200, y: 400, width: 150, height: 50)
        button4.app.disabledAlpha = UIButton.app.disabledAlpha
        button4.app.highlightedAlpha = UIButton.app.highlightedAlpha
        button4.setTitle("Custom可点击2", for: .normal)
        button4.setTitleColor(UIColor.black, for: .normal)
        button4.backgroundColor = APP.color(0xFFDA00)
        button4.app.setCornerRadius(5)
        view.addSubview(button4)
        
        button1 = UIButton(type: .custom)
        button1.frame = CGRect(x: 25, y: 465, width: 150, height: 50)
        button1.backgroundColor = APP.color(0xFFDA00)
        button1.app.setCornerRadius(5)
        button1.app.disabledAlpha = UIButton.app.disabledAlpha
        button1.app.highlightedAlpha = UIButton.app.highlightedAlpha
        button1.app.setTitle("按钮文字", font: APP.font(10), titleColor: .black)
        button1.app.setImage(UIImage.app.appIconImage()?.app.image(scaleSize: CGSize(width: 24, height: 24)))
        button1.app.setImageEdge(.top, spacing: 4)
        view.addSubview(button1)
        
        button2 = UIButton(type: .custom)
        button2.frame = CGRect(x: 200, y: 465, width: 150, height: 50)
        button2.backgroundColor = APP.color(0xFFDA00)
        button2.app.setCornerRadius(5)
        button2.app.disabledAlpha = UIButton.app.disabledAlpha
        button2.app.highlightedAlpha = UIButton.app.highlightedAlpha
        button2.app.setTitle("按钮文字", font: APP.font(10), titleColor: .black)
        button2.app.setImage(UIImage.app.appIconImage()?.app.image(scaleSize: CGSize(width: 24, height: 24)))
        button2.app.setImageEdge(.left, spacing: 4)
        view.addSubview(button2)
        
        button3 = UIButton(type: .custom)
        button3.frame = CGRect(x: 25, y: 530, width: 150, height: 50)
        button3.backgroundColor = APP.color(0xFFDA00)
        button3.app.setCornerRadius(5)
        button3.app.disabledAlpha = UIButton.app.disabledAlpha
        button3.app.highlightedAlpha = UIButton.app.highlightedAlpha
        button3.app.setTitle("按钮文字", font: APP.font(10), titleColor: .black)
        button3.app.setImage(UIImage.app.appIconImage()?.app.image(scaleSize: CGSize(width: 24, height: 24)))
        button3.app.setImageEdge(.bottom, spacing: 4)
        view.addSubview(button3)
        
        button4 = UIButton(type: .custom)
        button4.frame = CGRect(x: 200, y: 530, width: 150, height: 50)
        button4.backgroundColor = APP.color(0xFFDA00)
        button4.app.setCornerRadius(5)
        button4.app.disabledAlpha = UIButton.app.disabledAlpha
        button4.app.highlightedAlpha = UIButton.app.highlightedAlpha
        button4.app.setTitle("按钮文字", font: APP.font(10), titleColor: .black)
        button4.app.setImage(UIImage.app.appIconImage()?.app.image(scaleSize: CGSize(width: 24, height: 24)))
        button4.app.setImageEdge(.right, spacing: 4)
        view.addSubview(button4)
    }
    
    @objc func onClick1(_ sender: UIButton) {
        count += 1
        showCount()
    }
    
    @objc func onClick2(_ sender: UITapGestureRecognizer) {
        count += 1
        showCount()
    }
    
    @objc func onClick3(_ sender: UIButton) {
        count += 1
        showCount()
        
        sender.isEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            sender.isEnabled = true
        }
    }
    
    @objc func onClick4(_ sender: UITapGestureRecognizer) {
        count += 1
        showCount()
        
        sender.isEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            sender.isEnabled = true
        }
    }
    
    @objc func onClick5(_ sender: UIButton) {
        count += 1
        showCount()
    }
    
    func showCount() {
        UIWindow.app.showMessage(text: "点击计数：\(count)")
    }
    
}
