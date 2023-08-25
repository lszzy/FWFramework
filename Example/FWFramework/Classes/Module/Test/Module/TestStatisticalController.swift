//
//  TestStatisticalController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/10/19.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestStatisticalController: UIViewController, TableViewControllerProtocol, CollectionViewControllerProtocol, BannerViewDelegate {
    
    private var tableObject = "table"
    
    lazy var shieldView: UIView = {
        let result = UIView()
        result.backgroundColor = AppTheme.tableColor
        result.app.addTapGesture { [weak self] _ in
            self?.shieldView.isHidden = true
            self?.shieldView.removeFromSuperview()
            // 手工触发曝光计算
            self?.view.app.statisticalCheckExposure()
        }
        
        let label = UILabel()
        label.text = "点击关闭"
        label.textAlignment = .center
        result.addSubview(label)
        label.app.layoutChain.edges()
        return result
    }()
    
    lazy var bannerView: BannerView = {
        let result = BannerView()
        result.autoScroll = true
        result.autoScrollTimeInterval = 6
        result.delegate = self
        result.placeholderImage = UIImage.app.appIconImage()
        result.didScrollToItemBlock = { index in
            // APP.debug("currentIndex: \(index)")
        }
        return result
    }()
    
    lazy var hoverView: UIView = {
        let result = UIView()
        result.backgroundColor = UIColor.app.randomColor
        result.app.dragEnabled = true
        result.app.addTapGesture { [weak self] _ in
            self?.hoverView.removeFromSuperview()
        }
        return result
    }()
    
    lazy var testView: UIView = {
        let result = UIView()
        result.backgroundColor = .white
        
        let label = UILabel()
        label.text = "View"
        label.textAlignment = .center
        result.addSubview(label)
        label.app.layoutChain.edges()
        return result
    }()
    
    lazy var testButton: UIButton = {
        let result = UIButton(type: .custom)
        result.setTitle("Button", for: .normal)
        result.app.setBackgroundColor(.white, for: .normal)
        return result
    }()
    
    lazy var testSwitch: UISwitch = {
        let result = UISwitch()
        result.thumbTintColor = .white
        result.onTintColor = result.thumbTintColor
        return result
    }()
    
    lazy var segmentedControl: SegmentedControl = {
        let result = SegmentedControl()
        result.backgroundColor = AppTheme.cellColor
        result.selectedSegmentIndex = 1
        result.selectionStyle = .box
        result.segmentEdgeInset = UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 5)
        result.selectionIndicatorEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        result.segmentWidthStyle = .dynamic
        result.selectionIndicatorLocation = .bottom
        result.titleTextAttributes = [NSAttributedString.Key.font: UIFont.app.font(ofSize: 16), NSAttributedString.Key.foregroundColor: AppTheme.textColor]
        result.selectedTitleTextAttributes = [NSAttributedString.Key.font: UIFont.app.boldFont(ofSize: 18), NSAttributedString.Key.foregroundColor: AppTheme.textColor]
        return result
    }()
    
    lazy var tagCollectionView: TextTagCollectionView = {
        let result = TextTagCollectionView()
        result.backgroundColor = AppTheme.cellColor
        result.verticalSpacing = 10
        result.horizontalSpacing = 10
        return result
    }()
    
    func setupTableView() {
        let headerView = UIView()
        headerView.addSubview(bannerView)
        bannerView.app.layoutChain.left(10).top(50).right(10).height(100)
        
        headerView.addSubview(testView)
        testView.app.layoutChain.width(100).height(30).centerX().top(toViewBottom: bannerView, offset: 50)
        
        headerView.addSubview(testButton)
        testButton.app.layoutChain.width(100).height(30).centerX().top(toViewBottom: testView, offset: 50)
        
        headerView.addSubview(testSwitch)
        testSwitch.app.layoutChain.centerX().top(toViewBottom: testButton, offset: 50)
        
        headerView.addSubview(segmentedControl)
        segmentedControl.app.layoutChain.left(10).right(10).top(toViewBottom: testSwitch, offset: 50).height(50)
        
        headerView.addSubview(tagCollectionView)
        tagCollectionView.app.layoutChain.left(10).right(10).top(toViewBottom: segmentedControl, offset: 50).height(100).bottom(50)
        
        tableView.tableHeaderView = headerView
        headerView.app.autoLayoutSubviews()
    }
    
    func setupTableLayout() {
        tableView.app.layoutChain.edges()
    }
    
    func setupCollectionViewLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: (APP.screenWidth - 10) / 2.0, height: 100)
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        return layout
    }
    
    func setupCollectionLayout() {
        collectionView.backgroundColor = AppTheme.backgroundColor
        collectionView.app.layoutChain.edges()
    }
    
    func setupSubviews() {
        UIWindow.app.main?.addSubview(shieldView)
        shieldView.app.layoutChain.edges()
        
        view.addSubview(hoverView)
        view.bringSubviewToFront(hoverView)
        hoverView.app.layoutChain
            .center()
            .size(CGSize(width: 100, height: 100))
        
        testView.app.addTapGesture { [weak self] _ in
            self?.bannerView.scrollToIndex(0)
        }
        
        testButton.app.addTouch { [weak self] _ in
            self?.bannerView.scrollToIndex(1)
        }
        
        testSwitch.app.addBlock({ [weak self] _ in
            self?.testSwitch.thumbTintColor = UIColor.app.randomColor
        }, for: .valueChanged)
        
        self.bannerView.didSelectItemBlock = { index in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                Router.openURL("https://www.baidu.com", userInfo: [
                    Router.Parameter.routerOptionsKey: NavigatorOptions.embedInNavigation
                ])
                /*
                Router.openURL("https://www.baidu.com", userInfo: {
                    let userInfo = RouterParameter()
                    userInfo.routerOptions = .embedInNavigation
                    return userInfo
                }())
                */
            }
        }
        
        self.segmentedControl.indexChangedBlock = { [weak self] index in
            self?.bannerView.scrollToIndex(2)
        }
    }
    
    func setupLayout() {
        collectionView.isHidden = true
        StatisticalManager.shared.exposureTime = UserDefaults.app.object(forKey: "TestExposureTime").safeBool
        app.setRightBarItem(UIBarButtonItem.SystemItem.refresh.rawValue) { [weak self] _ in
            self?.app.showSheet(title: nil, message: nil, actions: [StatisticalManager.shared.exposureTime ? "关闭曝光时长" : "开启曝光时长", StatisticalManager.shared.exposureBecomeActive ? "回到前台时不重新曝光" : "回到前台时重新曝光", StatisticalManager.shared.exposureThresholds == 1 ? "设置曝光比率为0.5" : "设置曝光比率为1.0", "切换collectionView", "表格reloadData", "切换控制器statisticalExposure"], actionBlock: { [weak self] index in
                if index == 0 {
                    StatisticalManager.shared.exposureTime = !StatisticalManager.shared.exposureTime
                    UserDefaults.app.setObject(StatisticalManager.shared.exposureTime, forKey: "TestExposureTime")
                } else if index == 1 {
                    StatisticalManager.shared.exposureBecomeActive = !StatisticalManager.shared.exposureBecomeActive
                } else if index == 2 {
                    StatisticalManager.shared.exposureThresholds = StatisticalManager.shared.exposureThresholds == 1 ? 0.5 : 1
                } else if index == 3 {
                    if self?.collectionView.isHidden ?? false {
                        self?.collectionView.isHidden = false
                        self?.tableView.isHidden = true
                    } else {
                        self?.collectionView.isHidden = true
                        self?.tableView.isHidden = false
                    }
                } else if index == 4 {
                    self?.tableObject = self?.tableObject == "table" ? "table2" : "table"
                    self?.tableView.reloadData()
                } else {
                    let object = self?.app.statisticalExposure?.object.safeString == "viewController" ? "viewController2" : "viewController"
                    self?.app.statisticalExposure = StatisticalEvent(name: "exposure_viewController", object: object)
                }
            })
        }
        
        let imageUrls = [
            "http://e.hiphotos.baidu.com/image/h%3D300/sign=0e95c82fa90f4bfb93d09854334e788f/10dfa9ec8a136327ee4765839c8fa0ec09fac7dc.jpg",
            UIImage.app.appIconImage() as Any,
            "http://kvm.wuyong.site/images/images/animation.png",
            "http://littlesvr.ca/apng/images/SteamEngine.webp",
            "not_found.jpg",
            "http://ww2.sinaimg.cn/bmiddle/642beb18gw1ep3629gfm0g206o050b2a.gif"
        ]
        bannerView.imagesGroup = imageUrls
        
        let sectionTitles = ["Section0", "Section1", "Section2", "Section3", "Section4", "Section5", "Section6", "Section7", "Section8"]
        segmentedControl.sectionTitles = sectionTitles
        
        tagCollectionView.addTags(["标签0", "标签1", "标签2", "标签3", "标签4", "标签5"])
        tagCollectionView.removeTag("标签4")
        tagCollectionView.removeTag("标签5")
        tagCollectionView.addTags(["标签4", "标签5", "标签6", "标签7"])
        
        renderData()
    }
    
    func renderData() {
        StatisticalManager.shared.eventHandler = { [weak self] event in
            if event.isExposure {
                APP.debug("%@曝光%@: \nindexPath: %@\ncount: %@\nname: %@\nobject: %@\nuserInfo: %@\nduration: %@\ntotalDuration: %@", NSStringFromClass(event.view?.classForCoder ?? Self.classForCoder()), !event.isFinished ? "开始" : "结束", "\(event.indexPath?.section ?? 0).\(event.indexPath?.row ?? 0)", "\(event.triggerCount)", APP.safeString(event.name), APP.safeString(event.object), APP.safeString(event.userInfo), "\(event.triggerDuration)", "\(event.totalDuration)")
            } else {
                self?.showToast(String(format: "%@点击事件: \nindexPath: %@\ncount: %@\nname: %@\nobject: %@\nuserInfo: %@", NSStringFromClass(event.view?.classForCoder ?? Self.classForCoder()), "\(event.indexPath?.section ?? 0).\(event.indexPath?.row ?? 0)", "\(event.triggerCount)", APP.safeString(event.name), APP.safeString(event.object), APP.safeString(event.userInfo)))
            }
        }
        
        // ViewController
        app.statisticalExposure = StatisticalEvent(name: "exposure_viewController", object: "viewController")
        app.statisticalExposureListener = { event in
            if event.isFinished {
                UIWindow.app.showMessage(text: "\(event.name)曝光结束: \(String(format: "%.1f", event.triggerDuration))s - \(String(format: "%.1f", event.totalDuration))s")
            } else {
                UIWindow.app.showMessage(text: "\(event.name)曝光开始")
            }
        }
        
        // Click
        testView.app.statisticalClick = StatisticalEvent(name: "click_view", object: "view")
        testButton.app.statisticalClick = StatisticalEvent(name: "click_button", object: "button")
        testSwitch.app.statisticalClick = StatisticalEvent(name: "click_switch", object: "switch")
        bannerView.app.statisticalClick = StatisticalEvent(name: "click_banner", object: "banner")
        segmentedControl.app.statisticalClick = StatisticalEvent(name: "click_segment", object: "segment")
        tagCollectionView.app.statisticalClick = StatisticalEvent(name: "click_tag", object: "tag")
        
        // Exposure
        testView.app.statisticalExposure = StatisticalEvent(name: "exposure_view", object: "view")
        testView.app.statisticalExposureListener = { [weak self] event in
            self?.testView.backgroundColor = event.isFinished ? .white : UIColor.app.randomColor
        }
        configShieldView(testView.app.statisticalExposure)
        testButton.app.statisticalExposure = StatisticalEvent(name: "exposure_button", object: "button")
        testButton.app.statisticalExposureListener = { [weak self] event in
            self?.testButton.app.setBackgroundColor(event.isFinished ? .white : UIColor.app.randomColor, for: .normal)
        }
        configShieldView(testButton.app.statisticalExposure)
        testSwitch.app.statisticalExposure = StatisticalEvent(name: "exposure_switch", object: "switch")
        testSwitch.app.statisticalExposureListener = { [weak self] event in
            self?.testSwitch.thumbTintColor = event.isFinished ? .white : UIColor.app.randomColor
        }
        configShieldView(testSwitch.app.statisticalExposure)
        segmentedControl.app.statisticalExposure = StatisticalEvent(name: "exposure_segment", object: "segment")
        segmentedControl.app.statisticalExposure?.eventFormatter = { [weak self] event in
            guard let indexPath = event.indexPath else { return event }
            event.userInfo = [
                "title": self?.segmentedControl.sectionTitles?[safe: indexPath.row] ?? ""
            ]
            return event
        }
        segmentedControl.app.statisticalExposureListener = { [weak self] event in
            self?.segmentedControl.backgroundColor = event.isFinished ? AppTheme.cellColor : UIColor.app.randomColor
        }
        configShieldView(segmentedControl.app.statisticalExposure)
        tagCollectionView.app.statisticalExposure = StatisticalEvent(name: "exposure_tag", object: "tag")
        tagCollectionView.app.statisticalExposureListener = { [weak self] event in
            self?.tagCollectionView.backgroundColor = event.isFinished ? AppTheme.cellColor : UIColor.app.randomColor
        }
        configShieldView(tagCollectionView.app.statisticalExposure)
    }
    
    func configShieldView(_ object: StatisticalEvent?) {
        object?.shieldView = { [weak self] _ in
            if !(self?.shieldView.isHidden ?? false) {
                return self?.shieldView
            }
            return self?.hoverView
        }
    }
    
    func showToast(_ message: String) {
        app.showMessage(text: message)
    }
    
    func clickHandler(_ index: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            Router.openURL("https://www.baidu.com")
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        50
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        100
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.app.cell(tableView: tableView, style: .default)
        cell.contentView.backgroundColor = AppTheme.cellColor
        cell.textLabel?.text = "\(indexPath.row)"
        cell.app.statisticalClick = StatisticalEvent(name: "click_tableView", object: tableObject)
        cell.app.statisticalExposure = StatisticalEvent(name: "exposure_tableView", object: tableObject)
        cell.app.statisticalExposureListener = { event in
            cell.contentView.backgroundColor = event.isFinished ? AppTheme.cellColor : UIColor.app.randomColor
        }
        configShieldView(cell.app.statisticalExposure)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        clickHandler(indexPath.row)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        50
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = TestStatisticalCell.app.cell(collectionView: collectionView, indexPath: indexPath)
        cell.contentView.backgroundColor = AppTheme.cellColor
        cell.textLabel.text = "\(indexPath.row)"
        cell.app.statisticalClick = StatisticalEvent(name: "click_collectionView", object: "cell")
        cell.app.statisticalExposure = StatisticalEvent(name: "exposure_collectionView", object: "cell")
        cell.app.statisticalExposureListener = { event in
            cell.contentView.backgroundColor = event.isFinished ? AppTheme.cellColor : UIColor.app.randomColor
        }
        configShieldView(cell.app.statisticalExposure)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        clickHandler(indexPath.row)
    }
    
    func bannerView(_ bannerView: BannerView, customCell cell: UICollectionViewCell, for index: Int) {
        cell.app.statisticalExposure = StatisticalEvent(name: "exposure_banner", object: "banner")
        cell.app.statisticalExposureListener = { [weak self] event in
            let index = "\(event.indexPath?.row ?? -1)"
            self?.bannerView.titlesGroup = [index, index, index, index, index, index]
        }
        configShieldView(cell.app.statisticalExposure)
    }
    
}

class TestStatisticalCell: UICollectionViewCell {
    
    lazy var textLabel: UILabel = {
        let result = UILabel()
        result.font = UIFont.app.font(ofSize: 15)
        result.textColor = AppTheme.textColor
        return result
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(textLabel)
        textLabel.app.layoutChain.center()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
