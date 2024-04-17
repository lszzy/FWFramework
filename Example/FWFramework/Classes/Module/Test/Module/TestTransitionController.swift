//
//  TestTransitionController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/10/19.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestTransitionController: UIViewController, TableViewControllerProtocol {
    
    typealias TableElement = [String]
    
    let duration: TimeInterval = 0.35
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        app.navigationBarHidden = true
        
        UIWindow.app.showMessage(text: "viewWillAppear:\(animated)")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.app.navigationTransition = nil
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        UIWindow.app.showMessage(text: "viewWillDisappear:\(animated)")
    }
    
    func setupTableStyle() -> UITableView.Style {
        .grouped
    }
    
    func setupTableView() {
        tableData.append(contentsOf: [
            ["默认Present", "onPresent"],
            ["全屏Present", "onPresentFullScreen"],
            ["转场present", "onPresentTransition"],
            ["滑动present", "onPresentSwipe"],
            ["边缘present", "onPresentEdge"],
            ["自定义controller", "onPresentController"],
            ["自定义alert", "onPresentAlert"],
            ["自定义animator", "onPresentAnimator"],
            ["自定义custom", "onPresentCustom"],
            ["interactive present", "onPresentInteractive"],
            ["present without animation", "onPresentNoAnimate"],
            ["System Push", "onPush"],
            ["Swipe Push", "onPushSwipe"],
            ["Proxy Push", "onPushProxy"],
            ["interactive Push", "onPushInteractive"],
            ["push without animation", "onPushNoAnimate"],
        ])
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.app.cell(tableView: tableView)
        let rowData = tableData[indexPath.row]
        cell.textLabel?.text = rowData[0]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let rowData = tableData[indexPath.row]
        _ = self.perform(NSSelectorFromString(rowData[1]))
    }
    
    @objc func onPresent() {
        let vc = TestFullScreenViewController()
        vc.canScroll = true
        present(vc, animated: true)
    }
    
    @objc func onPresentFullScreen() {
        let vc = TestFullScreenViewController()
        vc.canScroll = true
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
    
    @objc func onPresentTransition() {
        let transition = AnimatedTransition()
        transition.transitionDuration = duration
        transition.transitionBlock = { transiton in
            if transition.transitionType == .present {
                transition.start()
                transition.transitionContext?.view(forKey: .to)?.transform = .init(scaleX: 0, y: 0)
                transition.transitionContext?.view(forKey: .to)?.alpha = 0
                UIView.animate(withDuration: transition.transitionDuration(using: transition.transitionContext)) {
                    transition.transitionContext?.view(forKey: .to)?.transform = .init(scaleX: 1, y: 1)
                    transition.transitionContext?.view(forKey: .to)?.alpha = 1
                } completion: { _ in
                    transition.complete()
                }
            } else if transition.transitionType == .dismiss {
                transition.start()
                transition.transitionContext?.view(forKey: .from)?.transform = .init(scaleX: 1, y: 1)
                transition.transitionContext?.view(forKey: .from)?.alpha = 1
                UIView.animate(withDuration: transition.transitionDuration(using: transition.transitionContext)) {
                    transition.transitionContext?.view(forKey: .from)?.transform = .init(scaleX: 0.01, y: 0.01)
                    transition.transitionContext?.view(forKey: .from)?.alpha = 0
                } completion: { _ in
                    transition.complete()
                }
            }
        }
        
        let vc = TestFullScreenViewController()
        vc.app.modalTransition = transition
        present(vc, animated: true)
    }
    
    @objc func onPresentSwipe() {
        let transition = SwipeAnimatedTransition()
        transition.transitionDuration = duration
        transition.inDirection = .left
        transition.outDirection = .right
        
        let vc = TestFullScreenViewController()
        vc.app.modalTransition = transition
        present(vc, animated: true)
    }
    
    @objc func onPresentEdge() {
        let nav = UINavigationController(rootViewController: TestFullScreenViewController())
        let transition = nav.app.setPresentTransition()
        transition.interactEnabled = true
        transition.interactScreenEdge = true
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
    
    @objc func onPresentController() {
        let transition = SwipeAnimatedTransition()
        transition.interactEnabled = true
        transition.interactScreenEdge = true
        if let gesture = transition.gestureRecognizer as? PanGestureRecognizer {
            gesture.direction = .right
            gesture.maximumDistance = 44
        }
        transition.presentationBlock = { presented, presenting in
            let presentation = PresentationController(presentedViewController: presented, presenting: presenting)
            presentation.verticalInset = 200
            presentation.cornerRadius = 10
            return presentation
        }
        transition.dismissCompletion = { [weak self] in
            self?.app.showMessage(text: "dismiss完成")
        }
        
        let nav = UINavigationController(rootViewController: TestFullScreenViewController())
        nav.modalPresentationStyle = .custom
        nav.app.modalTransition = transition
        present(nav, animated: true)
    }
    
    @objc func onPresentAlert() {
        let vc = TestTransitionAlertViewController()
        present(vc, animated: true)
    }
    
    @objc func onPresentAnimator() {
        let vc = TestTransitionAlertViewController()
        vc.useAnimator = true
        present(vc, animated: true)
    }
    
    @objc func onPresentCustom() {
        let vc = TestTransitionCustomViewController()
        vc.present(in: self)
    }
    
    @objc func onPresentInteractive() {
        let transtion = SwipeAnimatedTransition(inDirection: .up, outDirection: .down)
        transtion.transitionDuration = duration
        transtion.interactEnabled = true
        
        let vc = TestFullScreenViewController()
        vc.canScroll = true
        let nav = UINavigationController(rootViewController: vc)
        nav.app.modalTransition = transtion
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
    
    @objc func onPresentNoAnimate() {
        let transition = SwipeAnimatedTransition()
        transition.interactEnabled = true
        transition.presentationBlock = { presented, presenting in
            let presentation = PresentationController(presentedViewController: presented, presenting: presenting)
            presentation.verticalInset = 200
            presentation.cornerRadius = 10
            return presentation
        }
        
        let vc = TestFullScreenViewController()
        vc.canScroll = true
        vc.noAnimate = true
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .custom
        
        transition.interactBlock = { gesture in
            if gesture.state == .began {
                vc.dismiss(animated: true)
                return false
            }
            return true
        }
        transition.interact(with: nav)
        
        nav.app.modalTransition = transition
        present(nav, animated: false)
    }
    
    @objc func onPush() {
        let vc = TestFullScreenViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func onPushSwipe() {
        let transition = SwipeAnimatedTransition()
        transition.transitionDuration = duration
        transition.inDirection = .up
        transition.outDirection = .down
        
        let vc = TestFullScreenViewController()
        navigationController?.app.navigationTransition = transition
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func onPushProxy() {
        let transition = AnimatedTransition()
        transition.transitionDuration = duration
        transition.transitionBlock = { transition in
            if transition.transitionType == .push {
                transition.start()
                transition.transitionContext?.view(forKey: .to)?.frame = CGRect(x: 0, y: APP.screenHeight, width: APP.screenWidth, height: APP.screenHeight)
                UIView.animate(withDuration: transition.transitionDuration(using: transition.transitionContext)) {
                    transition.transitionContext?.view(forKey: .to)?.frame = CGRect(x: 0, y: 0, width: APP.screenWidth, height: APP.screenHeight)
                } completion: { _ in
                    transition.complete()
                }
            } else if transition.transitionType == .pop {
                transition.start()
                transition.transitionContext?.view(forKey: .from)?.frame = CGRect(x: 0, y: 0, width: APP.screenWidth, height: APP.screenHeight)
                UIView.animate(withDuration: transition.transitionDuration(using: transition.transitionContext)) {
                    transition.transitionContext?.view(forKey: .from)?.frame = CGRect(x: 0, y: APP.screenHeight, width: APP.screenWidth, height: APP.screenHeight)
                } completion: { _ in
                    transition.complete()
                }
            }
        }
        
        let vc = TestFullScreenViewController()
        vc.app.viewTransition = transition
        navigationController?.app.navigationTransition = AnimatedTransition.system
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func onPushInteractive() {
        let transition = SwipeAnimatedTransition(inDirection: .up, outDirection: .down)
        transition.transitionDuration = duration
        transition.interactEnabled = true
        
        let vc = TestFullScreenViewController()
        vc.canScroll = true
        navigationController?.app.navigationTransition = transition
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func onPushNoAnimate() {
        let transition = SwipeAnimatedTransition(inDirection: .up, outDirection: .down)
        transition.transitionDuration = duration
        transition.interactEnabled = true
        
        let vc = TestFullScreenViewController()
        vc.canScroll = true
        vc.noAnimate = true
        
        transition.interactBlock = { [weak self] gesture in
            if gesture.state == .began {
                self?.navigationController?.popViewController(animated: true)
                return false
            }
            return true
        }
        transition.interact(with: vc)
        
        navigationController?.app.navigationTransition = transition
        navigationController?.pushViewController(vc, animated: false)
    }
    
}

class TestFullScreenViewController: UIViewController, ScrollViewControllerProtocol {
    
    var canScroll = false
    var noAnimate = false
    
    lazy var frameLabel: UILabel = {
        let result = UILabel()
        result.textColor = AppTheme.textColor
        return result
    }()
    
    func setupSubviews() {
        if self.canScroll {
            if let modalRecognizer = navigationController?.app.modalTransition?.gestureRecognizer as? PanGestureRecognizer {
                modalRecognizer.scrollView = self.scrollView
            }
            if let navRecognizer = navigationController?.app.navigationTransition?.gestureRecognizer as? PanGestureRecognizer {
                navRecognizer.scrollView = self.scrollView
            }
        }
        self.scrollView.isScrollEnabled = self.canScroll
        
        let cycleView = BannerView()
        cycleView.autoScroll = true
        cycleView.autoScrollTimeInterval = 4
        cycleView.placeholderImage = UIImage.app.appIconImage()
        contentView.addSubview(cycleView)
        cycleView.app.layoutChain.left().top().width(APP.screenWidth).height(200)
        
        let imageUrls = [
            "http://e.hiphotos.baidu.com/image/h%3D300/sign=0e95c82fa90f4bfb93d09854334e788f/10dfa9ec8a136327ee4765839c8fa0ec09fac7dc.jpg",
            UIImage.app.appIconImage() as Any,
            "http://www.ioncannon.net/wp-content/uploads/2011/06/test2.webp",
            "http://littlesvr.ca/apng/images/SteamEngine.webp",
            "not_found.jpg",
            "http://ww2.sinaimg.cn/bmiddle/642beb18gw1ep3629gfm0g206o050b2a.gif"
        ]
        cycleView.imagesGroup = imageUrls
        cycleView.titlesGroup = ["1", "2", "3", "4"]
        
        let footerView = UIView()
        footerView.backgroundColor = AppTheme.tableColor
        contentView.addSubview(footerView)
        footerView.app.layoutChain.left().bottom().top(toViewBottom: cycleView).width(APP.screenWidth).height(1000)
        
        frameLabel.text = NSCoder.string(for: view.frame)
        footerView.addSubview(frameLabel)
        frameLabel.app.layoutChain.centerX().top(50)
        
        let button = UIButton()
        button.backgroundColor = AppTheme.cellColor
        button.titleLabel?.font = UIFont.app.font(ofSize: 15)
        button.setTitleColor(AppTheme.textColor, for: .normal)
        button.setTitle("点击背景关闭", for: .normal)
        footerView.addSubview(button)
        button.app.setDimensions(CGSize(width: 200, height: 100))
        button.app.alignCenter()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "全屏弹出框"
        app.extendedLayoutEdge = []
        
        app.setLeftBarItem(Icon.closeImage) { [weak self] _ in
            self?.app.close(animated: !(self?.noAnimate ?? false))
        }
        
        view.backgroundColor = navigationController != nil ? AppTheme.tableColor : AppTheme.tableColor.withAlphaComponent(0.9)
        view.app.addTapGesture { [weak self] _ in
            self?.app.close(animated: !(self?.noAnimate ?? false))
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        frameLabel.text = NSCoder.string(for: view.frame)
        if !app.isPresented {
            app.navigationBarHidden = true
        }
    }
    
}

class TestTransitionAlertViewController: UIViewController, ViewControllerProtocol {
    
    var useAnimator: Bool = false
    var animator: UIDynamicAnimator?
    
    lazy var contentView: UIView = {
        let result = UIView()
        result.backgroundColor = AppTheme.cellColor
        return result
    }()
    
    func didInitialize() {
        modalPresentationStyle = .custom
        
        // 也可以封装present方法，手工指定UIPresentationController，无需使用block
        let transition = TransformAnimatedTransition(inTransform: .init(scaleX: 1.1, y: 1.1), outTransform: .identity)
        transition.presentationBlock = { [weak self] presented, presenting in
            let presentation = PresentationController(presentedViewController: presented, presenting: presenting)
            presentation.cornerRadius = 10
            presentation.rectCorner = .allCorners
            // 方式1：自动布局view，更新frame
            presented.view.setNeedsLayout()
            presented.view.layoutIfNeeded()
            presentation.presentedFrame = self?.contentView.frame ?? .zero
            return presentation
        }
        app.modalTransition = transition
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 方式2：不指定presentedFrame，背景手势不生效，自己添加手势和圆角即可
        view.addSubview(contentView)
        contentView.app.layoutChain.center()
        
        let childView = UIView()
        contentView.addSubview(childView)
        childView.app.layoutChain.edges().size(CGSize(width: 300, height: 250))
        
        contentView.app.addTapGesture { [weak self] _ in
            guard let self = self else { return }
            if self.useAnimator {
                self.configAnimator()
            }
            self.app.close()
        }
    }
    
    func configAnimator() {
        app.modalTransition = nil
        
        var radian = Double.pi
        if [true, false].randomElement() == true {
            radian = 2 * radian
        } else {
            radian = -1 * radian
        }
        animator = UIDynamicAnimator(referenceView: self.contentView)
        
        let gravityBehavior = UIGravityBehavior(items: [contentView])
        gravityBehavior.gravityDirection = CGVectorMake(0, 10)
        animator?.addBehavior(gravityBehavior)
        
        let itemBehavior = UIDynamicItemBehavior(items: [contentView])
        itemBehavior.addAngularVelocity(radian, for: self.view)
        animator?.addBehavior(itemBehavior)
    }
    
}

class TestTransitionCustomViewController: UIViewController, ViewControllerProtocol {
    
    lazy var contentView: UIView = {
        let result = UIView()
        result.layer.masksToBounds = true
        result.layer.cornerRadius = 10
        result.backgroundColor = AppTheme.cellColor
        return result
    }()
    
    func didInitialize() {
        modalPresentationStyle = .custom
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(contentView)
        contentView.app.layoutChain.center()
        
        let childView = UIView()
        contentView.addSubview(childView)
        childView.app.layoutChain.edges().size(CGSize(width: 300, height: 250))
        
        view.backgroundColor = AppTheme.backgroundColor.withAlphaComponent(0.5)
        view.app.addTapGesture { [weak self] _ in
            self?.dismiss()
        }
    }
    
    func present(in viewController: UIViewController) {
        viewController.present(self, animated: false) { [weak self] in
            self?.view.alpha = 0
            self?.contentView.transform = .init(scaleX: 0.01, y: 0.01)
            UIView.animate(withDuration: 0.35) {
                self?.view.alpha = 1
                self?.contentView.transform = .identity
            }
        }
    }
    
    func dismiss() {
        UIView.animate(withDuration: 0.35) {
            self.view.alpha = 0
            self.contentView.transform = .init(scaleX: 0.01, y: 0.01)
        } completion: { _ in
            self.dismiss(animated: false)
        }
    }
    
}
