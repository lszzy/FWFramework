//
//  TestPagingController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/10/18.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestPagingController: UIViewController, ViewControllerProtocol, PagingViewDelegate {
    
    static let headerViewHeight: CGFloat = 150
    static let segmentViewHeight: CGFloat = 50
    static let navigationViewHeight: CGFloat = APP.topBarHeight
    static let cartViewHeight: CGFloat = APP.tabBarHeight
    static let categoryViewWidth: CGFloat = 84
    static let itemViewHeight: CGFloat = 40
    
    var refreshList = false
    var isRefreshed = false
    
    lazy var pagerView: PagingView = {
        if refreshList {
            let pagerView = PagingListRefreshView(delegate: self, listContainerType: .scrollView)
            pagerView.listScrollViewPinContentInsetBlock = { scrollView in
                if let vc = scrollView.app.viewController as? TestNestChildController {
                    if vc.refreshList && vc.section && !vc.isInserted {
                        return APP.screenHeight
                    }
                }
                return 0
            }
            pagerView.pinSectionHeaderVerticalOffset = Int(APP.topBarHeight)
            pagerView.isHidden = true
            return pagerView
        } else {
            let pagerView = PagingView(delegate: self, listContainerType: .scrollView)
            pagerView.pinSectionHeaderVerticalOffset = Int(APP.topBarHeight)
            pagerView.isHidden = true
            return pagerView
        }
    }()
    
    lazy var headerView: UIImageView = {
        let result = UIImageView()
        result.image = UIImage.app.appIconImage()?.app.blurredImage()
        return result
    }()
    
    lazy var segmentedControl: SegmentedControl = {
        let result = SegmentedControl()
        result.backgroundColor = AppTheme.cellColor
        result.titleTextAttributes = [NSAttributedString.Key.foregroundColor: AppTheme.textColor]
        result.selectedTitleTextAttributes = [NSAttributedString.Key.foregroundColor: AppTheme.textColor]
        result.sectionTitles = ["下单", "评价", "商家"]
        result.indexChangedBlock = { [weak self] index in
            self?.pagerView.scrollToIndex(Int(index))
        }
        return result
    }()
    
    lazy var cartView: UIView = {
        let result = UIView()
        result.backgroundColor = .green
        result.isHidden = true
        
        let cartLabel = UILabel()
        cartLabel.font = UIFont.app.font(ofSize: 15)
        cartLabel.textColor = .black
        cartLabel.text = "我是购物车"
        cartLabel.textAlignment = .center
        result.addSubview(cartLabel)
        cartLabel.chain.edges()
        return result
    }()
    
    lazy var barAppearance: NavigationBarAppearance = {
        let result = NavigationBarAppearance()
        result.foregroundColor = AppTheme.textColor
        result.backgroundColor = .clear
        result.leftBackImage = Icon.backImage
        return result
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = ""
        
        if !refreshList {
            pagerView.mainTableView.app.setRefreshing(target: self, action: #selector(onRefreshing))
            pagerView.mainTableView.app.pullRefreshView?.height = PullRefreshView.height + UIScreen.app.safeAreaInsets.top
            pagerView.mainTableView.app.pullRefreshView?.indicatorPadding = UIScreen.app.safeAreaInsets.top
            
            app.setRightBarItem(Icon.iconImage("zmdi-var-arrow-right", size: 24)) { [weak self] _ in
                let vc = TestPagingController()
                vc.refreshList = true
                self?.app.open(vc)
            }
        }
        
        requestData()
    }
    
    func requestData() {
        app.extendedLayoutEdge = .top
        app.navigationBarAppearance = barAppearance
        app.statusBarStyle = .default
        
        app.showLoading()
        let soFast = [true, false].randomElement()!
        // 模拟启用转场且请求太快的情况时导航栏是否正常
        if soFast { UINavigationController.app.enableBarTransition() }
        DispatchQueue.main.asyncAfter(deadline: .now() + (soFast ? 0.2 : 1)) {
            self.app.hideLoading()
            
            self.barAppearance.foregroundColor = .white
            self.app.navigationBarAppearance = self.barAppearance
            self.app.statusBarStyle = .lightContent
            
            self.pagerView.isHidden = false
            self.cartView.isHidden = false
            self.pagerView.reloadData()
        }
    }
    
    @objc func onRefreshing() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isRefreshed = !self.isRefreshed
            self.pagerView.mainTableView.app.endRefreshing()
            self.segmentedControl.sectionTitles = self.segmentedControl.sectionTitles.count == 2 ? ["下单", "评价", "商家"] : ["下单", "评价"]
            self.pagerView.reloadData()
        }
    }
    
    func setupSubviews() {
        view.addSubview(self.pagerView)
        pagerView.chain.edges()
        
        view.addSubview(cartView)
        cartView.chain.edges(excludingEdge: .top).height(TestPagingController.cartViewHeight)
    }
    
    func tableHeaderViewHeight(in pagingView: PagingView) -> Int {
        return Int(TestPagingController.headerViewHeight)
    }
    
    func tableHeaderView(in pagingView: PagingView) -> UIView {
        return self.headerView
    }
    
    func heightForPinSectionHeader(in pagingView: PagingView) -> Int {
        return Int(TestPagingController.segmentViewHeight)
    }
    
    func viewForPinSectionHeader(in pagingView: PagingView) -> UIView {
        return self.segmentedControl
    }
    
    func numberOfLists(in pagingView: PagingView) -> Int {
        return segmentedControl.sectionTitles.count
    }
    
    func pagingView(_ pagingView: PagingView, initListAtIndex index: Int) -> PagingViewListViewDelegate {
        let listView = TestNestChildController()
        listView.pagerView = pagingView
        listView.refreshList = self.refreshList
        listView.isRefreshed = self.isRefreshed
        if index == 0 {
            listView.rows = 30
            listView.section = true
            listView.cart = true
        } else if index == 1 {
            listView.rows = 50
        } else {
            listView.rows = 5
        }
        return listView
    }
    
    func pagingView(_ pagingView: PagingView, mainTableViewDidScroll scrollView: UIScrollView) {
        let progress = scrollView.contentOffset.y / (TestPagingController.headerViewHeight - TestPagingController.navigationViewHeight)
        if progress >= 1 {
            barAppearance.backgroundColor = AppTheme.barColor
            barAppearance.foregroundColor = AppTheme.textColor
            app.navigationBarAppearance = barAppearance
            app.statusBarStyle = .default
        } else if progress >= 0 && progress < 1 {
            barAppearance.backgroundColor = AppTheme.barColor.withAlphaComponent(progress)
            if progress <= 0.5 {
                barAppearance.foregroundColor = .white.withAlphaComponent(1 - progress)
            } else {
                barAppearance.foregroundColor = AppTheme.textColor.withAlphaComponent(progress)
            }
            app.navigationBarAppearance = barAppearance
            app.statusBarStyle = progress <= 0.5 ? .lightContent : .default
        }
    }
    
    func pagingView(_ pagingView: PagingView, didScrollToIndex index: Int) {
        segmentedControl.selectedSegmentIndex = index
        if !self.pagerView.isHidden {
            self.cartView.isHidden = index != 0
        }
    }
    
}

class TestNestCollectionCell: UICollectionViewCell {
    
    lazy var textLabel: UILabel = {
        let result = UILabel()
        result.font = .app.font(ofSize: 15)
        result.textColor = AppTheme.textColor
        result.textAlignment = .center
        return result
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(textLabel)
        textLabel.app.layoutChain.edges()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var isSelected: Bool {
        didSet {
            contentView.backgroundColor = isSelected ? .gray : AppTheme.cellColor
        }
    }
    
}

class TestNestChildController: UIViewController, TableViewControllerProtocol, CollectionViewControllerProtocol, PagingViewListViewDelegate {
    
    var refreshList = false
    var rows: Int = 0
    var section = false
    var cart = false
    var isRefreshed = false
    var isInserted = false
    var pagerView: PagingView?
    
    var scrollCallback: ((UIScrollView) -> Void)?
    
    func setupTableLayout() {
        tableView.chain.edges(UIEdgeInsets(top: 0, left: self.cart ? TestPagingController.categoryViewWidth : 0, bottom: self.cart ? TestPagingController.cartViewHeight : 0, right: 0))
    }
    
    func setupCollectionViewLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: TestPagingController.categoryViewWidth, height: TestPagingController.itemViewHeight)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = .zero
        return layout
    }
    
    func setupCollectionLayout() {
        collectionView.backgroundColor = AppTheme.backgroundColor
        collectionView.chain.edges(UIEdgeInsets(top: 0, left: 0, bottom: self.cart ? TestPagingController.cartViewHeight : 0, right: 0), excludingEdge: .right)
        collectionView.chain.width(self.cart ? TestPagingController.categoryViewWidth : 0)
    }
    
    func setupSubviews() {
        if refreshList {
            tableView.app.setRefreshing(target: self, action: #selector(onRefreshing))
        }
        tableView.app.setLoading(target: self, action: #selector(onLoading))
    }
    
    func setupLayout() {
        for i in 0 ..< rows {
            if isRefreshed {
                tableData.append("我是刷新的测试数据\(i)")
            } else {
                tableData.append("我是测试数据\(i)")
            }
        }
        collectionView.reloadData()
        
        tableView.app.reloadData { [weak self] in
            guard let self = self else { return }
            self.selectCollectionView(offset: self.tableView.contentOffset.y)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Logger.debug("TestNestChildController.viewDidLoad")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Logger.debug("TestNestChildController.viewWillAppear")
    }
    
    @objc func onRefreshing() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.tableView.app.endRefreshing()
            if self.refreshList && self.section && !self.isInserted {
                self.isInserted = true
                for i in 0 ..< 5 {
                    self.tableData.insert("我是插入的测试数据\(4 - i)", at: 0)
                }
            } else {
                self.tableData.removeAll()
                self.setupLayout()
            }
            self.collectionView.reloadData()
            
            self.tableView.app.reloadData { [weak self] in
                guard let self = self else { return }
                self.selectCollectionView(offset: self.tableView.contentOffset.y)
            }
        }
    }
    
    @objc func onLoading() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.tableView.app.endRefreshing()
            let rows = self.tableData.count
            for i in 0 ..< 5 {
                if self.isRefreshed {
                    self.tableData.append("我是刷新的测试数据\(rows + i)")
                } else {
                    self.tableData.append("我是测试数据\(rows + i)")
                }
            }
            self.collectionView.reloadData()
            
            self.tableView.app.reloadData { [weak self] in
                guard let self = self else { return }
                self.selectCollectionView(offset: self.tableView.contentOffset.y)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Int(ceil(Double(self.tableData.count) / 5.0))
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = TestNestCollectionCell.app.cell(collectionView: collectionView, indexPath: indexPath)
        cell.textLabel.text = "\(indexPath.row)"
        cell.isSelected = false
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        pagerView?.setMainTableViewToMaxContentOffsetY()
        tableView.selectRow(at: IndexPath(row: 0, section: indexPath.row), animated: true, scrollPosition: .top)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Int(ceil(Double(self.tableData.count) / 5.0))
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.app.cell(tableView: tableView)
        let index = indexPath.section * 5 + indexPath.row
        cell.textLabel?.text = tableData[index] as? String
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return self.section ? TestPagingController.itemViewHeight : 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = AppTheme.cellColor
        
        let headerLabel = UILabel()
        headerLabel.font = UIFont.app.font(ofSize: 15)
        headerLabel.textColor = AppTheme.textColor
        headerLabel.text = "Header\(section)"
        headerLabel.frame = CGRect(x: 0, y: 0, width: APP.screenWidth, height: TestPagingController.itemViewHeight)
        view.addSubview(headerLabel)
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return TestPagingController.itemViewHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        app.showAlert(title: "点击\(indexPath.row)", message: nil)
    }
    
    func selectCollectionView(offset: CGFloat) {
        if !self.cart { return }
        
        for i in 0 ..< tableData.count {
            let sectionOffsetY: CGFloat = TestPagingController.itemViewHeight * (CGFloat(i) + 1.0) + (CGFloat(i) / 5.0 + 1.0) * TestPagingController.itemViewHeight
            if offset < sectionOffsetY {
                collectionView.selectItem(at: IndexPath(row: i / 5, section: 0), animated: true, scrollPosition: .top)
                break
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == self.tableView {
            // 拖动或减速时选中左侧菜单
            if tableView.isDragging || tableView.isDecelerating {
                selectCollectionView(offset: scrollView.contentOffset.y)
            }
            
            self.scrollCallback?(scrollView)
        }
    }
    
    func listView() -> UIView {
        return self.view
    }
    
    func listScrollView() -> UIScrollView {
        return self.tableView
    }
    
    func listViewDidScrollCallback(callback: @escaping (UIScrollView) -> ()) {
        self.scrollCallback = callback
    }
    
}
