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
        result.fw.addTapGesture { [weak self] _ in
            self?.shieldView.isHidden = true
            self?.shieldView.removeFromSuperview()
            // 手工触发曝光计算
            self?.view.fw.statisticalCheckExposure()
        }
        
        let label = UILabel()
        label.text = "点击关闭"
        label.textAlignment = .center
        result.addSubview(label)
        label.fw.layoutChain.edges()
        return result
    }()
    
    lazy var bannerView: BannerView = {
        let result = BannerView()
        result.autoScroll = true
        result.autoScrollTimeInterval = 6
        result.delegate = self
        result.placeholderImage = UIImage.fw.appIconImage()
        result.itemDidScrollOperationBlock = { index in
            // FW.debug("currentIndex: \(index)")
        }
        return result
    }()
    
    lazy var hoverView: UIView = {
        let result = UIView()
        result.backgroundColor = UIColor.fw.randomColor
        result.fw.dragEnabled = true
        result.fw.addTapGesture { [weak self] _ in
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
        label.fw.layoutChain.edges()
        return result
    }()
    
    lazy var testButton: UIButton = {
        let result = UIButton(type: .custom)
        result.setTitle("Button", for: .normal)
        result.fw.setBackgroundColor(.white, for: .normal)
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
        result.titleTextAttributes = [NSAttributedString.Key.font: UIFont.fw.font(ofSize: 16), NSAttributedString.Key.foregroundColor: AppTheme.textColor]
        result.selectedTitleTextAttributes = [NSAttributedString.Key.font: UIFont.fw.boldFont(ofSize: 18), NSAttributedString.Key.foregroundColor: AppTheme.textColor]
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
        bannerView.fw.layoutChain.left(10).top(50).right(10).height(100)
        
        headerView.addSubview(testView)
        testView.fw.layoutChain.width(100).height(30).centerX().top(toViewBottom: bannerView, offset: 50)
        
        headerView.addSubview(testButton)
        testButton.fw.layoutChain.width(100).height(30).centerX().top(toViewBottom: testView, offset: 50)
        
        headerView.addSubview(testSwitch)
        testSwitch.fw.layoutChain.centerX().top(toViewBottom: testButton, offset: 50)
        
        headerView.addSubview(segmentedControl)
        segmentedControl.fw.layoutChain.left(10).right(10).top(toViewBottom: testSwitch, offset: 50).height(50)
        
        headerView.addSubview(tagCollectionView)
        tagCollectionView.fw.layoutChain.left(10).right(10).top(toViewBottom: segmentedControl, offset: 50).height(100).bottom(50)
        
        tableView.tableHeaderView = headerView
        headerView.fw.autoLayoutSubviews()
    }
    
    func setupTableLayout() {
        tableView.fw.layoutChain.edges()
    }
    
    func setupCollectionViewLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: (FW.screenWidth - 10) / 2.0, height: 100)
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        return layout
    }
    
    func setupCollectionLayout() {
        collectionView.backgroundColor = AppTheme.backgroundColor
        collectionView.fw.layoutChain.edges()
    }
    
    func setupSubviews() {
        UIWindow.fw.main?.addSubview(shieldView)
        shieldView.fw.layoutChain.edges()
        
        view.addSubview(hoverView)
        view.bringSubviewToFront(hoverView)
        hoverView.fw.layoutChain
            .center()
            .size(CGSize(width: 100, height: 100))
        
        testView.fw.addTapGesture { [weak self] _ in
            self?.bannerView.makeScrollScroll(to: 0)
        }
        
        testButton.fw.addTouch { [weak self] _ in
            self?.bannerView.makeScrollScroll(to: 1)
        }
        
        testSwitch.fw.addBlock({ [weak self] _ in
            self?.testSwitch.thumbTintColor = UIColor.fw.randomColor
        }, for: .valueChanged)
        
        self.bannerView.clickItemOperationBlock = { index in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                Router.openURL("https://www.baidu.com", userInfo: [
                    RouterParameter.routerOptionsKey: NavigatorOptions.embedInNavigation
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
        
        self.segmentedControl.indexChangeBlock = { [weak self] index in
            self?.bannerView.makeScrollScroll(to: 2)
        }
    }
    
    func setupLayout() {
        collectionView.isHidden = true
        StatisticalManager.shared.exposureTime = UserDefaults.fw.object(forKey: "TestExposureTime").safeBool
        fw.setRightBarItem(UIBarButtonItem.SystemItem.refresh.rawValue) { [weak self] _ in
            self?.fw.showSheet(title: nil, message: nil, actions: [StatisticalManager.shared.exposureTime ? "关闭曝光时长" : "开启曝光时长", StatisticalManager.shared.exposureBecomeActive ? "回到前台时不重新曝光" : "回到前台时重新曝光", StatisticalManager.shared.exposureVisibleCells ? "关闭曝光visibleCells" : "开启曝光visibleCells", StatisticalManager.shared.exposureThresholds == 1 ? "设置曝光比率为0.5" : "设置曝光比率为1.0", "切换collectionView", "表格reloadData", "切换控制器statisticalExposure"], actionBlock: { [weak self] index in
                if index == 0 {
                    StatisticalManager.shared.exposureTime = !StatisticalManager.shared.exposureTime
                    UserDefaults.fw.setObject(StatisticalManager.shared.exposureTime, forKey: "TestExposureTime")
                } else if index == 1 {
                    StatisticalManager.shared.exposureBecomeActive = !StatisticalManager.shared.exposureBecomeActive
                } else if index == 2 {
                    StatisticalManager.shared.exposureVisibleCells = !StatisticalManager.shared.exposureVisibleCells
                } else if index == 3 {
                    StatisticalManager.shared.exposureThresholds = StatisticalManager.shared.exposureThresholds == 1 ? 0.5 : 1
                } else if index == 4 {
                    if self?.collectionView.isHidden ?? false {
                        self?.collectionView.isHidden = false
                        self?.tableView.isHidden = true
                    } else {
                        self?.collectionView.isHidden = true
                        self?.tableView.isHidden = false
                    }
                } else if index == 5 {
                    self?.tableObject = self?.tableObject == "table" ? "table2" : "table"
                    self?.tableView.reloadData()
                } else {
                    let object = self?.fw.statisticalExposure?.object.safeString == "viewController" ? "viewController2" : "viewController"
                    self?.fw.statisticalExposure = StatisticalEvent(name: "exposure_viewController", object: object)
                }
            })
        }
        
        let imageUrls = [
            "http://e.hiphotos.baidu.com/image/h%3D300/sign=0e95c82fa90f4bfb93d09854334e788f/10dfa9ec8a136327ee4765839c8fa0ec09fac7dc.jpg",
            UIImage.fw.appIconImage() as Any,
            "http://kvm.wuyong.site/images/images/animation.png",
            "http://littlesvr.ca/apng/images/SteamEngine.webp",
            "not_found.jpg",
            "http://ww2.sinaimg.cn/bmiddle/642beb18gw1ep3629gfm0g206o050b2a.gif"
        ]
        bannerView.imageURLStringsGroup = imageUrls
        
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
                FW.debug("%@曝光%@: \nindexPath: %@\ncount: %@\nname: %@\nobject: %@\nuserInfo: %@\nduration: %@\ntotalDuration: %@", NSStringFromClass(event.view?.classForCoder ?? Self.classForCoder()), !event.isFinished ? "开始" : "结束", "\(event.indexPath?.section ?? 0).\(event.indexPath?.row ?? 0)", "\(event.triggerCount)", FW.safeString(event.name), FW.safeString(event.object), FW.safeString(event.userInfo), "\(event.triggerDuration)", "\(event.totalDuration)")
            } else {
                self?.showToast(String(format: "%@点击事件: \nindexPath: %@\ncount: %@\nname: %@\nobject: %@\nuserInfo: %@", NSStringFromClass(event.view?.classForCoder ?? Self.classForCoder()), "\(event.indexPath?.section ?? 0).\(event.indexPath?.row ?? 0)", "\(event.triggerCount)", FW.safeString(event.name), FW.safeString(event.object), FW.safeString(event.userInfo)))
            }
        }
        
        // ViewController
        fw.statisticalExposure = StatisticalEvent(name: "exposure_viewController", object: "viewController")
        fw.statisticalExposureListener = { event in
            if event.isFinished {
                UIWindow.fw.showMessage(text: "\(event.name)曝光结束: \(String(format: "%.1f", event.triggerDuration))s - \(String(format: "%.1f", event.totalDuration))s")
            } else {
                UIWindow.fw.showMessage(text: "\(event.name)曝光开始")
            }
        }
        
        // Click
        testView.fw.statisticalClick = StatisticalEvent(name: "click_view", object: "view")
        testButton.fw.statisticalClick = StatisticalEvent(name: "click_button", object: "button")
        testSwitch.fw.statisticalClick = StatisticalEvent(name: "click_switch", object: "switch")
        bannerView.fw.statisticalClick = StatisticalEvent(name: "click_banner", object: "banner")
        segmentedControl.fw.statisticalClick = StatisticalEvent(name: "click_segment", object: "segment")
        tagCollectionView.fw.statisticalClick = StatisticalEvent(name: "click_tag", object: "tag")
        
        // Exposure
        testView.fw.statisticalExposure = StatisticalEvent(name: "exposure_view", object: "view")
        testView.fw.statisticalExposureListener = { [weak self] event in
            self?.testView.backgroundColor = event.isFinished ? .white : UIColor.fw.randomColor
        }
        configShieldView(testView.fw.statisticalExposure)
        testButton.fw.statisticalExposure = StatisticalEvent(name: "exposure_button", object: "button")
        testButton.fw.statisticalExposureListener = { [weak self] event in
            self?.testButton.fw.setBackgroundColor(event.isFinished ? .white : UIColor.fw.randomColor, for: .normal)
        }
        configShieldView(testButton.fw.statisticalExposure)
        testSwitch.fw.statisticalExposure = StatisticalEvent(name: "exposure_switch", object: "switch")
        testSwitch.fw.statisticalExposureListener = { [weak self] event in
            self?.testSwitch.thumbTintColor = event.isFinished ? .white : UIColor.fw.randomColor
        }
        configShieldView(testSwitch.fw.statisticalExposure)
        segmentedControl.fw.statisticalExposure = StatisticalEvent(name: "exposure_segment", object: "segment")
        segmentedControl.fw.statisticalExposureListener = { [weak self] event in
            self?.segmentedControl.backgroundColor = event.isFinished ? AppTheme.cellColor : UIColor.fw.randomColor
        }
        configShieldView(segmentedControl.fw.statisticalExposure)
        tagCollectionView.fw.statisticalExposure = StatisticalEvent(name: "exposure_tag", object: "tag")
        tagCollectionView.fw.statisticalExposureListener = { [weak self] event in
            self?.tagCollectionView.backgroundColor = event.isFinished ? AppTheme.cellColor : UIColor.fw.randomColor
        }
        configShieldView(tagCollectionView.fw.statisticalExposure)
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
        fw.showMessage(text: message)
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
        let cell = UITableViewCell.fw.cell(tableView: tableView, style: .default)
        cell.contentView.backgroundColor = AppTheme.cellColor
        cell.textLabel?.text = "\(indexPath.row)"
        cell.fw.statisticalClick = StatisticalEvent(name: "click_tableView", object: tableObject)
        cell.fw.statisticalExposure = StatisticalEvent(name: "exposure_tableView", object: tableObject)
        cell.fw.statisticalExposureListener = { event in
            cell.contentView.backgroundColor = event.isFinished ? AppTheme.cellColor : UIColor.fw.randomColor
        }
        configShieldView(cell.fw.statisticalExposure)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        clickHandler(indexPath.row)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        50
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = TestStatisticalCell.fw.cell(collectionView: collectionView, indexPath: indexPath)
        cell.contentView.backgroundColor = AppTheme.cellColor
        cell.textLabel.text = "\(indexPath.row)"
        cell.fw.statisticalClick = StatisticalEvent(name: "click_collectionView", object: "cell")
        cell.fw.statisticalExposure = StatisticalEvent(name: "exposure_collectionView", object: "cell")
        cell.fw.statisticalExposureListener = { event in
            cell.contentView.backgroundColor = event.isFinished ? AppTheme.cellColor : UIColor.fw.randomColor
        }
        configShieldView(cell.fw.statisticalExposure)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        clickHandler(indexPath.row)
    }
    
    func bannerView(_ bannerView: BannerView, customCell cell: UICollectionViewCell, for index: Int) {
        cell.fw.statisticalExposure = StatisticalEvent(name: "exposure_banner", object: "banner")
        cell.fw.statisticalExposureListener = { [weak self] event in
            let index = "\(event.indexPath?.row ?? -1)"
            self?.bannerView.titlesGroup = [index, index, index, index, index, index]
        }
        configShieldView(cell.fw.statisticalExposure)
    }
    
}

class TestStatisticalCell: UICollectionViewCell {
    
    lazy var textLabel: UILabel = {
        let result = UILabel()
        result.font = UIFont.fw.font(ofSize: 15)
        result.textColor = AppTheme.textColor
        return result
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(textLabel)
        textLabel.fw.layoutChain.center()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
