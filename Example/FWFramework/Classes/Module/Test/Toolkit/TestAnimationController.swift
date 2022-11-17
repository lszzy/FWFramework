//
//  TestAnimationController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/21.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestAnimationController: UIViewController, ViewControllerProtocol {
    
    var animationIndex: Int = 0
    
    lazy var animationView: UIView = {
        let result = UIView()
        result.frame = CGRect(x: FW.screenWidth / 2 - 75, y: 170, width: 150, height: 200)
        result.backgroundColor = UIColor.red
        return result
    }()
    
    func didInitialize() {
        fw.extendedLayoutEdge = .bottom
    }
    
    func setupSubviews() {
        let button = AppTheme.largeButton()
        button.setTitle("转场动画", for: .normal)
        button.fw.addTouch(target: self, action: #selector(onPresent))
        view.addSubview(button)
        button.fw.layoutChain
            .bottom(15)
            .centerX()
        
        let button2 = AppTheme.largeButton()
        button2.setTitle("切换拖动", for: .normal)
        button2.fw.addTouch(target: self, action: #selector(onDrag(_:)))
        view.addSubview(button2)
        button2.fw.layoutChain
            .bottom(toViewTop: button, offset: -15)
            .centerX()
        
        let button3 = AppTheme.largeButton()
        button3.setTitle("切换动画", for: .normal)
        button3.fw.addTouch(target: self, action: #selector(onAnimation(_:)))
        view.addSubview(button3)
        button3.fw.layoutChain
            .bottom(toViewTop: button2, offset: -15)
            .centerX()
        
        view.addSubview(animationView)
    }
    
    @objc func onPresent() {
        fw.showSheet(title: nil, message: nil, cancel: "取消", actions: ["VC present", "VC alert", "VC fade", "nav present", "nav alert", "nav fade", "view present", "view alert", "view fade", "wrapped present", "wrapped alert", "wrapped fade"], currentIndex: -1) { [weak self] index in
            guard let self = self else { return }
            if index < 3 {
                let vc = TestAnimationChildController()
                vc.transitionType = index
                vc.show(in: self)
            } else if index < 6 {
                let vc = TestAnimationChildController()
                vc.transitionType = index
                vc.showNav(in: self)
            } else {
                let view = TestAnimationView(transitionType: index)
                view.show(in: self)
            }
        }
    }
    
    @objc func onAnimation(_ sender: UIButton) {
        self.animationIndex += 1
        var title: String? = nil
        if animationIndex == 1 {
            title = "Push.FromTop"
            animationView.fw.addTransition(type: .push, subtype: .fromTop, timingFunction: .init(name: .easeInEaseOut), duration: 1.0)
        } else if animationIndex == 2 {
            title = "CurlUp"
            animationView.fw.addAnimation(curve: .easeInOut, transition: .curlUp, duration: 1.0)
        } else if animationIndex == 3 {
            title = "transform.rotation.y"
            animationView.fw.addAnimation(keyPath: "transform.rotation.y", fromValue: NSNumber(value: 0), toValue: NSNumber(value: CGFloat.pi), duration: 1.0)
        } else if animationIndex == 4 {
            title = "Shake"
            animationView.fw.shake(times: 10, delta: 0, duration: 0.1)
        } else if animationIndex == 5 {
            title = "Alpha"
            animationView.fw.fade(alpha: 0, duration: 1.0) { [weak self] _ in
                self?.animationView.fw.fade(alpha: 1.0, duration: 1.0)
            }
        } else if animationIndex == 6 {
            title = "Rotate"
            animationView.fw.rotate(degree: 180, duration: 1.0)
        } else if animationIndex == 7 {
            title = "Scale"
            animationView.fw.scale(scaleX: 0.5, scaleY: 0.5, duration: 1.0) { [weak self] _ in
                self?.animationView.fw.scale(scaleX: 2.0, scaleY: 2.0, duration: 1.0)
            }
        } else if animationIndex == 8 {
            title = "Move"
            let point = animationView.frame.origin
            animationView.fw.move(point: CGPoint(x: 10, y: 10), duration: 1.0) { [weak self] _ in
                self?.animationView.fw.move(point: point, duration: 1.0)
            }
        } else if animationIndex == 9 {
            title = "Frame"
            let frame = animationView.frame
            animationView.fw.move(frame: CGRect(x: 10, y: 10, width: 50, height: 50), duration: 1.0) { [weak self] _ in
                self?.animationView.fw.move(frame: frame, duration: 1.0)
            }
        } else if animationIndex == 10 {
            title = "切换动画"
            animationIndex = 0
        }
        
        sender.setTitle(title, for: .normal)
    }
    
    @objc func onDrag(_ sender: UIButton) {
        if !animationView.fw.dragEnabled {
            animationView.fw.dragEnabled = true
            animationView.fw.dragLimit = CGRect(x: 0, y: 0, width: FW.screenWidth, height: FW.screenHeight - FW.topBarHeight)
        } else {
            animationView.fw.dragEnabled = false
        }
    }
    
}

class TestAnimationView: UIView {
    
    var transitionType: Int = 0
    
    lazy var bottomView: UIView = {
        let result = UIView()
        result.backgroundColor = .white
        return result
    }()
    
    init(transitionType: Int) {
        super.init(frame: .zero)
        self.transitionType = transitionType
        if transitionType > 8 {
            backgroundColor = .clear
        } else {
            backgroundColor = .fw.color(hex: 0x000000, alpha: 0.5)
        }
        
        addSubview(bottomView)
        if transitionType == 6 || transitionType == 9 {
            bottomView.fw.layoutChain.horizontal().bottom().height(FW.screenHeight / 2)
        } else {
            bottomView.fw.layoutChain.center().width(300).height(200)
        }
        
        fw.addTapGesture { [weak self] _ in
            guard let self = self else { return }
            if self.transitionType > 8 {
                self.fw.viewController?.dismiss(animated: true)
                return
            }
            
            if self.transitionType == 6 {
                self.fw.setPresentTransition(.dismiss, contentView: self.bottomView, completion: nil)
            } else if self.transitionType == 7 {
                self.fw.setAlertTransition(.dismiss, completion: nil)
            } else {
                self.fw.setFadeTransition(.dismiss, completion: nil)
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show(in viewController: UIViewController) {
        if transitionType > 8 {
            let wrappedVC = fw.wrappedTransitionController(true)
            if transitionType == 9 {
                wrappedVC.fw.setPresentTransition(nil)
            } else if transitionType == 10 {
                wrappedVC.fw.setAlertTransition(nil)
            } else {
                wrappedVC.fw.setFadeTransition(nil)
            }
            viewController.present(wrappedVC, animated: true)
            return
        }
        
        fw.transition(to: viewController, pinEdges: true)
        if transitionType == 6 {
            fw.setPresentTransition(.present, contentView: self.bottomView, completion: nil)
        } else if transitionType == 7 {
            fw.setAlertTransition(.present, completion: nil)
        } else {
            fw.setFadeTransition(.present, completion: nil)
        }
    }
    
}

class TestAnimationChildController: UIViewController, ViewControllerProtocol {
    
    var transitionType: Int = 0
    
    lazy var bottomView: UIView = {
        let result = UIView()
        result.backgroundColor = .white
        return result
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fw.navigationBarHidden = true
        view.backgroundColor = .clear
        view.fw.addTapGesture { [weak self] _ in
            self?.fw.close()
        }
        
        view.addSubview(self.bottomView)
        if transitionType == 0 || transitionType == 3 {
            bottomView.fw.layoutChain.horizontal().bottom().height(FW.screenHeight / 2)
        } else {
            bottomView.fw.layoutChain.center().width(300).height(200)
        }
        
        let button = UIButton()
        button.setTitleColor(.black, for: .normal)
        button.setTitle(self.navigationController != nil ? "支持push" : "不支持push", for: .normal)
        bottomView.addSubview(button)
        button.fw.addTouch { [weak self] _ in
            let vc = TestAnimationChildController()
            vc.transitionType = self?.transitionType ?? 0
            self?.navigationController?.pushViewController(vc, animated: true)
        }
        button.fw.layoutChain.center()
    }
    
    func show(in viewController: UIViewController) {
        if transitionType == 0 {
            fw.setPresentTransition(nil)
        } else if transitionType == 1 {
            fw.setAlertTransition(nil)
        } else {
            fw.setFadeTransition(nil)
        }
        viewController.present(self, animated: true)
    }
    
    func showNav(in viewController: UIViewController) {
        let nav = UINavigationController(rootViewController: self)
        if transitionType == 3 {
            nav.fw.setPresentTransition(nil)
        } else if transitionType == 4 {
            nav.fw.setAlertTransition(nil)
        } else {
            nav.fw.setFadeTransition(nil)
        }
        viewController.present(nav, animated: true)
    }
    
}
