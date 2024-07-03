//
//  TestAnimationController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/21.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework
#if DEBUG
import FWDebug
#endif

class TestAnimationController: UIViewController, ViewControllerProtocol {
    
    var animationIndex: Int = 0
    
    lazy var animationView: UIView = {
        let result = UIView()
        result.frame = CGRect(x: APP.screenWidth / 2 - 75, y: 170, width: 150, height: 200)
        result.backgroundColor = UIColor.red
        return result
    }()
    
    func didInitialize() {
        app.extendedLayoutEdge = .bottom
    }
    
    func setupNavbar() {
        app.setRightBarItem(Icon.iconImage("zmdi-var-bug", size: 24)) { _ in
            guard UIWindow.app.main?.app.subview(tag: 1000) == nil else {
                UIWindow.app.main?.app.subview(tag: 1000)?.removeFromSuperview()
                return
            }
            
            let circleView = UIView(frame: CGRect(x: APP.screenWidth / 2 - 25, y: APP.screenHeight / 2 - 25, width: 50, height: 50))
            circleView.tag = 1000
            circleView.app.setCornerRadius(25)
            circleView.backgroundColor = UIColor.app.randomColor
            circleView.app.dragEnabled = true
            circleView.app.dragLimit = CGRect(x: 0, y: 0, width: APP.screenWidth, height: APP.screenHeight)
            circleView.app.isPenetrable = true
            UIWindow.app.main?.addSubview(circleView)
            
            let clickView = UIImageView(frame: CGRect(x: 10, y: 10, width: 30, height: 30))
            clickView.isUserInteractionEnabled = true
            clickView.image = UIImage.app.appIconImage()
            clickView.app.setCornerRadius(15)
            clickView.app.addTapGesture { _ in
                #if DEBUG
                FWDebugManager.sharedInstance().toggle()
                #endif
            }
            clickView.addGestureRecognizer(UILongPressGestureRecognizer.app.gestureRecognizer(block: { _ in
                UIWindow.app.main?.app.subview(tag: 1000)?.removeFromSuperview()
            }))
            circleView.addSubview(clickView)
        }
    }
    
    func setupSubviews() {
        let button = AppTheme.largeButton()
        button.setTitle("转场动画", for: .normal)
        button.app.addTouch(target: self, action: #selector(onPresent))
        view.addSubview(button)
        button.app.layoutChain
            .bottom(15)
            .centerX()
        
        let button2 = AppTheme.largeButton()
        button2.setTitle("切换拖动", for: .normal)
        button2.app.addTouch(target: self, action: #selector(onDrag(_:)))
        view.addSubview(button2)
        button2.app.layoutChain
            .bottom(toViewTop: button, offset: -15)
            .centerX()
        
        let button3 = AppTheme.largeButton()
        button3.setTitle("切换动画", for: .normal)
        button3.app.addTouch(target: self, action: #selector(onAnimation(_:)))
        view.addSubview(button3)
        button3.app.layoutChain
            .bottom(toViewTop: button2, offset: -15)
            .centerX()
        
        view.addSubview(animationView)
    }
    
    @objc func onPresent() {
        app.showSheet(title: nil, message: nil, cancel: "取消", actions: ["VC present", "VC alert", "VC fade", "nav present", "nav alert", "nav fade", "view present", "view alert", "view fade", "wrapped present", "wrapped alert", "wrapped fade"], currentIndex: -1) { [weak self] index in
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
            animationView.app.addTransition(type: .push, subtype: .fromTop, timingFunction: .init(name: .easeInEaseOut), duration: 1.0)
        } else if animationIndex == 2 {
            title = "CurlUp"
            animationView.app.addAnimation(curve: .curveEaseInOut, transition: .transitionCurlUp, duration: 1.0)
        } else if animationIndex == 3 {
            title = "transform.rotation.y"
            animationView.app.addAnimation(keyPath: "transform.rotation.y", fromValue: NSNumber(value: 0), toValue: NSNumber(value: CGFloat.pi), duration: 1.0)
        } else if animationIndex == 4 {
            title = "Shake"
            animationView.app.shake(times: 10, delta: 0, duration: 0.1)
        } else if animationIndex == 5 {
            title = "Alpha"
            animationView.app.fade(alpha: 0, duration: 1.0) { [weak self] _ in
                self?.animationView.app.fade(alpha: 1.0, duration: 1.0)
            }
        } else if animationIndex == 6 {
            title = "Rotate"
            animationView.app.rotate(degree: 180, duration: 1.0)
        } else if animationIndex == 7 {
            title = "Scale"
            animationView.app.scale(scaleX: 0.5, scaleY: 0.5, duration: 1.0) { [weak self] _ in
                self?.animationView.app.scale(scaleX: 2.0, scaleY: 2.0, duration: 1.0)
            }
        } else if animationIndex == 8 {
            title = "Move"
            let point = animationView.frame.origin
            animationView.app.move(point: CGPoint(x: 10, y: 10), duration: 1.0) { [weak self] _ in
                self?.animationView.app.move(point: point, duration: 1.0)
            }
        } else if animationIndex == 9 {
            title = "Frame"
            let frame = animationView.frame
            animationView.app.move(frame: CGRect(x: 10, y: 10, width: 50, height: 50), duration: 1.0) { [weak self] _ in
                self?.animationView.app.move(frame: frame, duration: 1.0)
            }
        } else if animationIndex == 10 {
            title = "切换动画"
            animationIndex = 0
        }
        
        sender.setTitle(title, for: .normal)
    }
    
    @objc func onDrag(_ sender: UIButton) {
        if !animationView.app.dragEnabled {
            animationView.app.dragEnabled = true
            animationView.app.dragLimit = CGRect(x: 0, y: 0, width: APP.screenWidth, height: APP.screenHeight - APP.topBarHeight)
        } else {
            animationView.app.dragEnabled = false
        }
    }
    
}

class TestAnimationView: UIView {
    
    var transitionType: Int = 0
    var edge: UIRectEdge = .bottom
    
    lazy var bottomView: UIView = {
        let result = UIView()
        result.backgroundColor = .white
        return result
    }()
    
    init(transitionType: Int) {
        super.init(frame: .zero)
        self.transitionType = transitionType
        if transitionType == 6 || transitionType == 9 {
            let edges: [UIRectEdge] = [.top, .left, .right, .bottom]
            edge = edges.randomElement()!
        }
        if transitionType > 8 {
            backgroundColor = .clear
        } else {
            backgroundColor = .app.color(hex: 0x000000, alpha: 0.5)
        }
        
        addSubview(bottomView)
        if transitionType == 6 || transitionType == 9 {
            switch edge {
            case .top:
                bottomView.app.layoutChain.horizontal().top().height(APP.screenHeight / 2)
            case .left:
                bottomView.app.layoutChain.vertical().left().width(APP.screenWidth / 2)
            case .right:
                bottomView.app.layoutChain.vertical().right().width(APP.screenWidth / 2)
            default:
                bottomView.app.layoutChain.horizontal().bottom().height(APP.screenHeight / 2)
            }
        } else {
            bottomView.app.layoutChain.center().width(300).height(200)
        }
        
        app.addTapGesture { [weak self] _ in
            guard let self = self else { return }
            if self.transitionType > 8 {
                self.app.viewController?.dismiss(animated: true)
                return
            }
            
            if self.transitionType == 6 {
                self.app.setPresentTransition(.dismiss, contentView: self.bottomView, edge: edge, completion: nil)
            } else if self.transitionType == 7 {
                self.app.setAlertTransition(.dismiss, completion: nil)
            } else {
                self.app.setFadeTransition(.dismiss, completion: nil)
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show(in viewController: UIViewController) {
        if transitionType > 8 {
            let wrappedVC = app.wrappedTransitionController(true)
            if transitionType == 9 {
                wrappedVC.app.setPresentTransition(edge: edge)
            } else if transitionType == 10 {
                wrappedVC.app.setAlertTransition(nil)
            } else {
                wrappedVC.app.setFadeTransition(nil)
            }
            viewController.present(wrappedVC, animated: true)
            return
        }
        
        app.transition(to: viewController, pinEdges: true)
        if transitionType == 6 {
            app.setPresentTransition(.present, contentView: self.bottomView, edge: edge, completion: nil)
        } else if transitionType == 7 {
            app.setAlertTransition(.present, completion: nil)
        } else {
            app.setFadeTransition(.present, completion: nil)
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
        app.navigationBarHidden = true
        view.backgroundColor = .clear
        view.app.addTapGesture { [weak self] _ in
            self?.app.close()
        }
        
        view.addSubview(self.bottomView)
        if transitionType == 0 || transitionType == 3 {
            bottomView.app.layoutChain.horizontal().bottom().height(APP.screenHeight / 2)
        } else {
            bottomView.app.layoutChain.center().width(300).height(200)
        }
        
        let button = UIButton()
        button.setTitleColor(.black, for: .normal)
        button.setTitle(self.navigationController != nil ? "支持push" : "不支持push", for: .normal)
        bottomView.addSubview(button)
        button.app.addTouch { [weak self] _ in
            let vc = TestAnimationChildController()
            vc.transitionType = self?.transitionType ?? 0
            self?.navigationController?.pushViewController(vc, animated: true)
        }
        button.app.layoutChain.center()
    }
    
    func show(in viewController: UIViewController) {
        if transitionType == 0 {
            app.setPresentTransition(nil)
        } else if transitionType == 1 {
            app.setAlertTransition(nil)
        } else {
            app.setFadeTransition(nil)
        }
        viewController.present(self, animated: true)
    }
    
    func showNav(in viewController: UIViewController) {
        let nav = UINavigationController(rootViewController: self)
        if transitionType == 3 {
            nav.app.setPresentTransition(nil)
        } else if transitionType == 4 {
            nav.app.setAlertTransition(nil)
        } else {
            nav.app.setFadeTransition(nil)
        }
        viewController.present(nav, animated: true)
    }
    
}
