//
//  FWPagingView.swift
//  FWFramework
//
//  Created by wuyong on 2020/7/27.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import UIKit

// MARK: - FWPagingListContainerView

/// 列表容器视图的类型
///- ScrollView: UIScrollView。优势：没有其他副作用。劣势：实时的视图内存占用相对大一点，因为所有加载之后的列表视图都在视图层级里面。
/// - CollectionView: 使用UICollectionView。优势：因为列表被添加到cell上，实时的视图内存占用更少，适合内存要求特别高的场景。劣势：因为cell重用机制的问题，导致列表被移除屏幕外之后，会被放入缓存区，而不存在于视图层级中。如果刚好你的列表使用了下拉刷新视图，在快速切换过程中，就会导致下拉刷新回调不成功的问题。一句话概括：使用CollectionView的时候，就不要让列表使用下拉刷新加载。
@objc
public enum FWPagingListContainerType: Int {
    case scrollView
    case collectionView
}

@objc
public protocol FWPagingViewListViewDelegate {
    /// 如果列表是VC，就返回VC.view
    /// 如果列表是View，就返回View自己
    ///
    /// - Returns: 返回列表视图
    func listView() -> UIView
    /// 返回listView内部持有的UIScrollView或UITableView或UICollectionView
    /// 主要用于mainTableView已经显示了header，listView的contentOffset需要重置时，内部需要访问到外部传入进来的listView内的scrollView
    ///
    /// - Returns: listView内部持有的UIScrollView或UITableView或UICollectionView
    func listScrollView() -> UIScrollView
    /// 当listView内部持有的UIScrollView或UITableView或UICollectionView的代理方法`scrollViewDidScroll`回调时，需要调用该代理方法传入的callback
    ///
    /// - Parameter callback: `scrollViewDidScroll`回调时调用的callback
    func listViewDidScrollCallback(callback: @escaping (UIScrollView)->())

    /// 将要重置listScrollView的contentOffset
    @objc optional func listScrollViewWillResetContentOffset()
    /// 可选实现，列表将要显示的时候调用
    @objc optional func listWillAppear()
    /// 可选实现，列表显示的时候调用
    @objc optional func listDidAppear()
    /// 可选实现，列表将要消失的时候调用
    @objc optional func listWillDisappear()
    /// 可选实现，列表消失的时候调用
    @objc optional func listDidDisappear()
}

@objc
public protocol FWPagingListContainerViewDataSource {
    /// 返回list的数量
    ///
    /// - Parameter listContainerView: FWPagingListContainerView
    func numberOfLists(in listContainerView: FWPagingListContainerView) -> Int

    /// 根据index初始化一个对应列表实例，需要是遵从`FWPagingViewListViewDelegate`协议的对象。
    /// 如果列表是用自定义UIView封装的，就让自定义UIView遵从`FWPagingViewListViewDelegate`协议，该方法返回自定义UIView即可。
    /// 如果列表是用自定义UIViewController封装的，就让自定义UIViewController遵从`FWPagingViewListViewDelegate`协议，该方法返回自定义UIViewController即可。
    /// 注意：一定要是新生成的实例！！！
    ///
    /// - Parameters:
    ///   - listContainerView: FWPagingListContainerView
    ///   - index: 目标index
    /// - Returns: 遵从FWPagingViewListViewDelegate协议的实例
    func listContainerView(_ listContainerView: FWPagingListContainerView, initListAt index: Int) -> FWPagingViewListViewDelegate


    /// 控制能否初始化对应index的列表。有些业务需求，需要在某些情况才允许初始化某些列表，通过通过该代理实现控制。
    @objc optional func listContainerView(_ listContainerView: FWPagingListContainerView, canInitListAt index: Int) -> Bool

    /// 返回自定义UIScrollView或UICollectionView的Class
    /// 某些特殊情况需要自己处理UIScrollView内部逻辑。比如项目用了FDFullscreenPopGesture，需要处理手势相关代理。
    ///
    /// - Parameter listContainerView: FWPagingListContainerView
    /// - Returns: 自定义UIScrollView实例
    @objc optional func scrollViewClass(in listContainerView: FWPagingListContainerView) -> AnyClass
}

@objc protocol FWPagingListContainerViewDelegate {
    @objc optional func listContainerViewDidScroll(_ listContainerView: FWPagingListContainerView)
    @objc optional func listContainerViewWillBeginDragging(_ listContainerView: FWPagingListContainerView)
    @objc optional func listContainerViewDidEndScrolling(_ listContainerView: FWPagingListContainerView)
    @objc optional func listContainerView(_ listContainerView: FWPagingListContainerView, listDidAppearAt index: Int)
}

@objcMembers
open class FWPagingListContainerView: UIView {
    public private(set) var type: FWPagingListContainerType
    public private(set) weak var dataSource: FWPagingListContainerViewDataSource?
    public private(set) var scrollView: UIScrollView!
    public var isCategoryNestPagingEnabled = false {
        didSet {
            if let containerScrollView = scrollView as? FWPagingListContainerScrollView {
                containerScrollView.isCategoryNestPagingEnabled = isCategoryNestPagingEnabled
            }else if let containerScrollView = scrollView as? FWPagingListContainerCollectionView {
                containerScrollView.isCategoryNestPagingEnabled = isCategoryNestPagingEnabled
            }
        }
    }
    /// 已经加载过的列表字典。key是index，value是对应的列表
    open var validListDict = [Int:FWPagingViewListViewDelegate]()
    /// 滚动切换的时候，滚动距离超过一页的多少百分比，就触发列表的初始化。默认0.01（即列表显示了一点就触发加载）。范围0~1，开区间不包括0和1
    open var initListPercent: CGFloat = 0.01 {
        didSet {
            if initListPercent <= 0 || initListPercent >= 1 {
                assertionFailure("initListPercent值范围为开区间(0,1)，即不包括0和1")
            }
        }
    }
    public var listCellBackgroundColor: UIColor = .white
    /// 需要和segmentedView.defaultSelectedIndex保持一致，用于触发默认index列表的加载
    public var defaultSelectedIndex: Int = 0 {
        didSet {
            currentIndex = defaultSelectedIndex
        }
    }
    weak var delegate: FWPagingListContainerViewDelegate?
    private var currentIndex: Int = 0
    private var collectionView: UICollectionView!
    private var containerVC: FWPagingListContainerViewController!
    private var willAppearIndex: Int = -1
    private var willDisappearIndex: Int = -1

    public init(dataSource: FWPagingListContainerViewDataSource, type: FWPagingListContainerType = .collectionView) {
        self.dataSource = dataSource
        self.type = type
        super.init(frame: CGRect.zero)

        commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func commonInit() {
        guard let dataSource = dataSource else { return }
        containerVC = FWPagingListContainerViewController()
        containerVC.view.backgroundColor = .clear
        addSubview(containerVC.view)
        containerVC.viewWillAppearClosure = {[weak self] in
            self?.listWillAppear(at: self?.currentIndex ?? 0)
        }
        containerVC.viewDidAppearClosure = {[weak self] in
            self?.listDidAppear(at: self?.currentIndex ?? 0)
        }
        containerVC.viewWillDisappearClosure = {[weak self] in
            self?.listWillDisappear(at: self?.currentIndex ?? 0)
        }
        containerVC.viewDidDisappearClosure = {[weak self] in
            self?.listDidDisappear(at: self?.currentIndex ?? 0)
        }
        if type == .scrollView {
            if let scrollViewClass = dataSource.scrollViewClass?(in: self) as? UIScrollView.Type {
                scrollView = scrollViewClass.init()
            }else {
                scrollView = FWPagingListContainerScrollView.init()
            }
            scrollView.backgroundColor = .clear
            scrollView.delegate = self
            scrollView.isPagingEnabled = true
            scrollView.showsVerticalScrollIndicator = false
            scrollView.showsHorizontalScrollIndicator = false
            scrollView.scrollsToTop = false
            scrollView.bounces = false
            if #available(iOS 11.0, *) {
                scrollView.contentInsetAdjustmentBehavior = .never
            }
            containerVC.view.addSubview(scrollView)
        }else if type == .collectionView {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .horizontal
            layout.minimumLineSpacing = 0
            layout.minimumInteritemSpacing = 0
            if let collectionViewClass = dataSource.scrollViewClass?(in: self) as? UICollectionView.Type {
                collectionView = collectionViewClass.init(frame: CGRect.zero, collectionViewLayout: layout)
            }else {
                collectionView = FWPagingListContainerCollectionView.init(frame: CGRect.zero, collectionViewLayout: layout)
            }
            collectionView.backgroundColor = .clear
            collectionView.isPagingEnabled = true
            collectionView.showsHorizontalScrollIndicator = false
            collectionView.showsVerticalScrollIndicator = false
            collectionView.scrollsToTop = false
            collectionView.bounces = false
            collectionView.dataSource = self
            collectionView.delegate = self
            collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
            if #available(iOS 10.0, *) {
                collectionView.isPrefetchingEnabled = false
            }
            if #available(iOS 11.0, *) {
                self.collectionView.contentInsetAdjustmentBehavior = .never
            }
            containerVC.view.addSubview(collectionView)
            //让外部统一访问scrollView
            scrollView = collectionView
        }
    }

    open override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        var next: UIResponder? = newSuperview
        while next != nil {
            if let vc = next as? UIViewController{
                vc.addChild(containerVC)
                break
            }
            next = next?.next
        }
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        guard let dataSource = dataSource else { return }
        containerVC.view.frame = bounds
        if type == .scrollView {
            if scrollView.frame == CGRect.zero || scrollView.bounds.size != bounds.size {
                scrollView.frame = bounds
                scrollView.contentSize = CGSize(width: scrollView.bounds.size.width*CGFloat(dataSource.numberOfLists(in: self)), height: scrollView.bounds.size.height)
                for (index, list) in validListDict {
                    list.listView().frame = CGRect(x: CGFloat(index)*scrollView.bounds.size.width, y: 0, width: scrollView.bounds.size.width, height: scrollView.bounds.size.height)
                }
                scrollView.contentOffset = CGPoint(x: CGFloat(currentIndex)*scrollView.bounds.size.width, y: 0)
            }else {
                scrollView.frame = bounds
                scrollView.contentSize = CGSize(width: scrollView.bounds.size.width*CGFloat(dataSource.numberOfLists(in: self)), height: scrollView.bounds.size.height)
            }
        }else {
            if collectionView.frame == CGRect.zero || collectionView.bounds.size != bounds.size {
                collectionView.frame = bounds
                collectionView.collectionViewLayout.invalidateLayout()
                collectionView.setContentOffset(CGPoint(x: CGFloat(currentIndex)*collectionView.bounds.size.width, y: 0), animated: false)
            }else {
                collectionView.frame = bounds
            }
        }
    }

    //MARK: - ListContainer

    public func contentScrollView() -> UIScrollView {
           return scrollView
    }

    public func scrolling(from leftIndex: Int, to rightIndex: Int, percent: CGFloat, selectedIndex: Int) {
    }

    public func didClickSelectedItem(at index: Int) {
        guard checkIndexValid(index) else {
            return
        }
        willAppearIndex = -1
        willDisappearIndex = -1
        if currentIndex != index {
            listWillDisappear(at: currentIndex)
            listWillAppear(at: index)
            listDidDisappear(at: currentIndex)
            listDidAppear(at: index)
        }
    }

    public func reloadData() {
        guard let dataSource = dataSource else { return }
        if currentIndex < 0 || currentIndex >= dataSource.numberOfLists(in: self) {
            defaultSelectedIndex = 0
            currentIndex = 0
        }
        validListDict.values.forEach { (list) in
            if let listVC = list as? UIViewController {
                listVC.removeFromParent()
            }
            list.listView().removeFromSuperview()
        }
        validListDict.removeAll()
        if type == .scrollView {
            scrollView.contentSize = CGSize(width: scrollView.bounds.size.width*CGFloat(dataSource.numberOfLists(in: self)), height: scrollView.bounds.size.height)
        }else {
            collectionView.reloadData()
        }
        listWillAppear(at: currentIndex)
        listDidAppear(at: currentIndex)
    }

    //MARK: - Private
    func initListIfNeeded(at index: Int) {
        guard let dataSource = dataSource else { return }
        if dataSource.listContainerView?(self, canInitListAt: index) == false {
            return
        }
        var existedList = validListDict[index]
        if existedList != nil {
            //列表已经创建好了
            return
        }
        existedList = dataSource.listContainerView(self, initListAt: index)
        guard let list = existedList else {
            return
        }
        if let vc = list as? UIViewController {
            containerVC.addChild(vc)
        }
        validListDict[index] = list
        if type == .scrollView {
            list.listView().frame = CGRect(x: CGFloat(index)*scrollView.bounds.size.width, y: 0, width: scrollView.bounds.size.width, height: scrollView.bounds.size.height)
            scrollView.addSubview(list.listView())
        }else {
            let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0))
            cell?.contentView.subviews.forEach { $0.removeFromSuperview() }
            list.listView().frame = cell?.contentView.bounds ?? CGRect.zero
            cell?.contentView.addSubview(list.listView())
        }
        listWillAppear(at: index)
    }

    private func listWillAppear(at index: Int) {
        guard let dataSource = dataSource else { return }
        guard checkIndexValid(index) else {
            return
        }
        var existedList = validListDict[index]
        if existedList != nil {
            existedList?.listWillAppear?()
            if let vc = existedList as? UIViewController {
                vc.beginAppearanceTransition(true, animated: false)
            }
        }else {
            //当前列表未被创建（页面初始化或通过点击触发的listWillAppear）
            guard dataSource.listContainerView?(self, canInitListAt: index) != false else {
                return
            }
            existedList = dataSource.listContainerView(self, initListAt: index)
            guard let list = existedList else {
                return
            }
            if let vc = list as? UIViewController {
                containerVC.addChild(vc)
            }
            validListDict[index] = list
            if type == .scrollView {
                if list.listView().superview == nil {
                    list.listView().frame = CGRect(x: CGFloat(index)*scrollView.bounds.size.width, y: 0, width: scrollView.bounds.size.width, height: scrollView.bounds.size.height)
                    scrollView.addSubview(list.listView())
                }
                list.listWillAppear?()
                if let vc = list as? UIViewController {
                    vc.beginAppearanceTransition(true, animated: false)
                }
            }else {
                let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0))
                cell?.contentView.subviews.forEach { $0.removeFromSuperview() }
                list.listView().frame = cell?.contentView.bounds ?? CGRect.zero
                cell?.contentView.addSubview(list.listView())
                list.listWillAppear?()
                if let vc = list as? UIViewController {
                    vc.beginAppearanceTransition(true, animated: false)
                }
            }
        }
    }

    private func listDidAppear(at index: Int) {
        guard checkIndexValid(index) else {
            return
        }
        currentIndex = index
        let list = validListDict[index]
        list?.listDidAppear?()
        if let vc = list as? UIViewController {
            vc.endAppearanceTransition()
        }
        delegate?.listContainerView?(self, listDidAppearAt: index)
    }

    private func listWillDisappear(at index: Int) {
        guard checkIndexValid(index) else {
            return
        }
        let list = validListDict[index]
        list?.listWillDisappear?()
        if let vc = list as? UIViewController {
            vc.beginAppearanceTransition(false, animated: false)
        }
    }

    private func listDidDisappear(at index: Int) {
        guard checkIndexValid(index) else {
            return
        }
        let list = validListDict[index]
        list?.listDidDisappear?()
        if let vc = list as? UIViewController {
            vc.endAppearanceTransition()
        }
    }

    private func checkIndexValid(_ index: Int) -> Bool {
        guard let dataSource = dataSource else { return false }
        let count = dataSource.numberOfLists(in: self)
        if count <= 0 || index >= count {
            return false
        }
        return true
    }
}

@objc
extension FWPagingListContainerView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let dataSource = dataSource else { return 0 }
        return dataSource.numberOfLists(in: self)
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        cell.contentView.backgroundColor = listCellBackgroundColor
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        let list = validListDict[indexPath.item]
        if list != nil {
            list?.listView().frame = cell.contentView.bounds
            cell.contentView.addSubview(list!.listView())
        }
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return bounds.size
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.listContainerViewDidScroll?(self)

        let percent = scrollView.contentOffset.x/scrollView.bounds.size.width
        let maxCount = Int(round(scrollView.contentSize.width/scrollView.bounds.size.width))
        var leftIndex = Int(floor(Double(percent)))
        leftIndex = max(0, min(maxCount - 1, leftIndex))
        let rightIndex = leftIndex + 1;
        if percent < 0 || rightIndex >= maxCount {
            return
        }
        let remainderRatio = percent - CGFloat(leftIndex)
        if rightIndex == currentIndex {
            //当前选中的在右边，用户正在从右边往左边滑动
            if remainderRatio < (1 - initListPercent) {
                initListIfNeeded(at: leftIndex)
            }
            if willAppearIndex == -1 {
                willAppearIndex = leftIndex;
                if validListDict[leftIndex] != nil {
                    listWillAppear(at: willAppearIndex)
                }
            }
            if willDisappearIndex == -1 {
                willDisappearIndex = rightIndex
                listWillDisappear(at: willDisappearIndex)
            }
        }else {
            //当前选中的在左边，用户正在从左边往右边滑动
            if remainderRatio > initListPercent {
                initListIfNeeded(at: rightIndex)
            }
            if willAppearIndex == -1 {
                willAppearIndex = rightIndex
                if validListDict[rightIndex] != nil {
                    listWillAppear(at: willAppearIndex)
                }
            }
            if willDisappearIndex == -1 {
                willDisappearIndex = leftIndex
                listWillDisappear(at: willDisappearIndex)
            }
        }

        let currentIndexPercent = scrollView.contentOffset.x/scrollView.bounds.size.width
        if willAppearIndex != -1 || willDisappearIndex != -1 {
            let disappearIndex = willDisappearIndex
            let appearIndex = willAppearIndex
            if willAppearIndex > willDisappearIndex {
                //将要出现的列表在右边
                if currentIndexPercent >= CGFloat(willAppearIndex) {
                    willDisappearIndex = -1
                    willAppearIndex = -1
                    listDidDisappear(at: disappearIndex)
                    listDidAppear(at: appearIndex)
                }
            }else {
                //将要出现的列表在左边
                if currentIndexPercent <= CGFloat(willAppearIndex) {
                    willDisappearIndex = -1
                    willAppearIndex = -1
                    listDidDisappear(at: disappearIndex)
                    listDidAppear(at: appearIndex)
                }
            }
        }
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if willAppearIndex != -1 || willDisappearIndex != -1 {
            listWillDisappear(at: willAppearIndex)
            listWillAppear(at: willDisappearIndex)
            listDidDisappear(at: willAppearIndex)
            listDidAppear(at: willDisappearIndex)
            willDisappearIndex = -1
            willAppearIndex = -1
        }
        delegate?.listContainerViewDidEndScrolling?(self)
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        delegate?.listContainerViewWillBeginDragging?(self)
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            delegate?.listContainerViewDidEndScrolling?(self)
        }
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        delegate?.listContainerViewDidEndScrolling?(self)
    }
}

@objcMembers
class FWPagingListContainerViewController: UIViewController {
    var viewWillAppearClosure: (()->())?
    var viewDidAppearClosure: (()->())?
    var viewWillDisappearClosure: (()->())?
    var viewDidDisappearClosure: (()->())?
    override var shouldAutomaticallyForwardAppearanceMethods: Bool { return false }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearClosure?()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewDidAppearClosure?()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewWillDisappearClosure?()
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewDidDisappearClosure?()
    }
}

@objcMembers
class FWPagingListContainerScrollView: UIScrollView, UIGestureRecognizerDelegate {
    var isCategoryNestPagingEnabled = false
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if isCategoryNestPagingEnabled, let panGestureClass = NSClassFromString("UIScrollViewPanGestureRecognizer"), gestureRecognizer.isMember(of: panGestureClass) {
            let panGesture = gestureRecognizer as! UIPanGestureRecognizer
            let velocityX = panGesture.velocity(in: panGesture.view!).x
            if velocityX > 0 {
                //当前在第一个页面，且往左滑动，就放弃该手势响应，让外层接收，达到多个PagingView左右切换效果
                if contentOffset.x == 0 {
                    return false
                }
            }else if velocityX < 0 {
                //当前在最后一个页面，且往右滑动，就放弃该手势响应，让外层接收，达到多个PagingView左右切换效果
                if contentOffset.x + bounds.size.width == contentSize.width {
                    return false
                }
            }
        }
        return true
    }
}

@objcMembers
class FWPagingListContainerCollectionView: UICollectionView, UIGestureRecognizerDelegate {
    var isCategoryNestPagingEnabled = false
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if isCategoryNestPagingEnabled, let panGestureClass = NSClassFromString("UIScrollViewPanGestureRecognizer"), gestureRecognizer.isMember(of: panGestureClass)  {
            let panGesture = gestureRecognizer as! UIPanGestureRecognizer
            let velocityX = panGesture.velocity(in: panGesture.view!).x
            if velocityX > 0 {
                //当前在第一个页面，且往左滑动，就放弃该手势响应，让外层接收，达到多个PagingView左右切换效果
                if contentOffset.x == 0 {
                    return false
                }
            }else if velocityX < 0 {
                //当前在最后一个页面，且往右滑动，就放弃该手势响应，让外层接收，达到多个PagingView左右切换效果
                if contentOffset.x + bounds.size.width == contentSize.width {
                    return false
                }
            }
        }
        return true
    }
}

// MARK: - FWPagingMainTableView

@objc public protocol FWPagingMainTableViewGestureDelegate {
    //如果headerView（或其他地方）有水平滚动的scrollView，当其正在左右滑动的时候，就不能让列表上下滑动，所以有此代理方法进行对应处理
    func mainTableViewGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool
}

@objcMembers
open class FWPagingMainTableView: UITableView, UIGestureRecognizerDelegate {
    public weak var gestureDelegate: FWPagingMainTableViewGestureDelegate?

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureDelegate != nil {
            return gestureDelegate!.mainTableViewGestureRecognizer(gestureRecognizer, shouldRecognizeSimultaneouslyWith:otherGestureRecognizer)
        }else {
            return gestureRecognizer.isKind(of: UIPanGestureRecognizer.self) && otherGestureRecognizer.isKind(of: UIPanGestureRecognizer.self)
        }
    }
}

// MARK: - FWPagingView

@objc public protocol FWPagingViewDelegate {
    /// tableHeaderView的高度，因为内部需要比对判断，只能是整型数
    func tableHeaderViewHeight(in pagingView: FWPagingView) -> Int
    /// 返回tableHeaderView
    func tableHeaderView(in pagingView: FWPagingView) -> UIView
    /// 返回悬浮HeaderView的高度，因为内部需要比对判断，只能是整型数
    func heightForPinSectionHeader(in pagingView: FWPagingView) -> Int
    /// 返回悬浮HeaderView
    func viewForPinSectionHeader(in pagingView: FWPagingView) -> UIView
    /// 返回列表的数量
    func numberOfLists(in pagingView: FWPagingView) -> Int
    /// 根据index初始化一个对应列表实例，需要是遵从`FWPagerViewListViewDelegate`协议的对象。
    /// 如果列表是用自定义UIView封装的，就让自定义UIView遵从`FWPagerViewListViewDelegate`协议，该方法返回自定义UIView即可。
    /// 如果列表是用自定义UIViewController封装的，就让自定义UIViewController遵从`FWPagerViewListViewDelegate`协议，该方法返回自定义UIViewController即可。
    ///
    /// - Parameters:
    ///   - pagingView: pagingView description
    ///   - index: 新生成的列表实例
    func pagingView(_ pagingView: FWPagingView, initListAtIndex index: Int) -> FWPagingViewListViewDelegate

    @objc optional func pagingView(_ pagingView: FWPagingView, mainTableViewDidScroll scrollView: UIScrollView)
    @objc optional func pagingView(_ pagingView: FWPagingView, mainTableViewWillBeginDragging scrollView: UIScrollView)
    @objc optional func pagingView(_ pagingView: FWPagingView, mainTableViewDidEndDragging scrollView: UIScrollView, willDecelerate decelerate: Bool)
    @objc optional func pagingView(_ pagingView: FWPagingView, mainTableViewDidEndDecelerating scrollView: UIScrollView)
    @objc optional func pagingView(_ pagingView: FWPagingView, mainTableViewDidEndScrollingAnimation scrollView: UIScrollView)
    
    /// 滚动到指定index内容视图时回调方法
    @objc optional func pagingView(_ pagingView: FWPagingView, didScrollToIndex index: Int)

    /// 返回自定义UIScrollView或UICollectionView的Class
    /// 某些特殊情况需要自己处理列表容器内UIScrollView内部逻辑。比如项目用了FDFullscreenPopGesture，需要处理手势相关代理。
    ///
    /// - Parameter pagingView: FWPagingView
    /// - Returns: 自定义UIScrollView实例
    @objc optional func scrollViewClassInListContainerView(in pagingView: FWPagingView) -> AnyClass
}

/**
 FWPagingView
 
 [JXPagingView](https://github.com/pujiaxin33/JXPagingView)
 */
@objcMembers
open class FWPagingView: UIView {
    /// 需要和categoryView.defaultSelectedIndex保持一致
    public var defaultSelectedIndex: Int = 0 {
        didSet {
            listContainerView.defaultSelectedIndex = defaultSelectedIndex
        }
    }
    public private(set) lazy var mainTableView: FWPagingMainTableView = FWPagingMainTableView(frame: CGRect.zero, style: .plain)
    public private(set) lazy var listContainerView: FWPagingListContainerView = FWPagingListContainerView(dataSource: self, type: listContainerType)
    /// 当前已经加载过可用的列表字典，key就是index值，value是对应的列表。
    public private(set) var validListDict = [Int:FWPagingViewListViewDelegate]()
    /// 顶部固定sectionHeader的垂直偏移量。数值越大越往下沉。
    public var pinSectionHeaderVerticalOffset: Int = 0
    public var isListHorizontalScrollEnabled = true {
        didSet {
            listContainerView.scrollView.isScrollEnabled = isListHorizontalScrollEnabled
        }
    }
    /// 是否允许当前列表自动显示或隐藏列表是垂直滚动指示器。true：悬浮的headerView滚动到顶部开始滚动列表时，就会显示，反之隐藏。false：内部不会处理列表的垂直滚动指示器。默认为：true。
    public var automaticallyDisplayListVerticalScrollIndicator = true
    public var currentScrollingListView: UIScrollView?
    public var currentList: FWPagingViewListViewDelegate?
    private var currentIndex: Int = 0
    private weak var delegate: FWPagingViewDelegate?
    private var tableHeaderContainerView: UIView!
    private let cellIdentifier = "cell"
    private let listContainerType: FWPagingListContainerType

    public init(delegate: FWPagingViewDelegate, listContainerType: FWPagingListContainerType = .collectionView) {
        self.delegate = delegate
        self.listContainerType = listContainerType
        super.init(frame: CGRect.zero)

        listContainerView.delegate = self

        mainTableView.showsVerticalScrollIndicator = false
        mainTableView.showsHorizontalScrollIndicator = false
        mainTableView.separatorStyle = .none
        mainTableView.dataSource = self
        mainTableView.delegate = self
        mainTableView.scrollsToTop = false
        refreshTableHeaderView()
        mainTableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        if #available(iOS 11.0, *) {
            mainTableView.contentInsetAdjustmentBehavior = .never
        }
        addSubview(mainTableView)
    }

    @available(*, unavailable)
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func layoutSubviews() {
        super.layoutSubviews()

        if mainTableView.frame != bounds {
            mainTableView.frame = bounds
            mainTableView.reloadData()
        }
    }

    open func reloadData() {
        currentList = nil
        currentScrollingListView = nil
        validListDict.removeAll()
        refreshTableHeaderView()
        if pinSectionHeaderVerticalOffset != 0 {
            mainTableView.contentOffset = .zero
        }
        mainTableView.reloadData()
        listContainerView.reloadData()
    }

    open func resizeTableHeaderViewHeight(animatable: Bool = false, duration: TimeInterval = 0.25, curve: UIView.AnimationCurve = .linear) {
        guard let delegate = delegate else { return }
        if animatable {
            var options: UIView.AnimationOptions = .curveLinear
            switch curve {
            case .easeIn: options = .curveEaseIn
            case .easeOut: options = .curveEaseOut
            case .easeInOut: options = .curveEaseInOut
            default: break
            }
            var bounds = tableHeaderContainerView.bounds
            bounds.size.height = CGFloat(delegate.tableHeaderViewHeight(in: self))
            UIView.animate(withDuration: duration, delay: 0, options: options, animations: {
                self.tableHeaderContainerView.frame = bounds
                self.mainTableView.tableHeaderView = self.tableHeaderContainerView
                self.mainTableView.setNeedsLayout()
                self.mainTableView.layoutIfNeeded()
            }, completion: nil)
        }else {
            var bounds = tableHeaderContainerView.bounds
            bounds.size.height = CGFloat(delegate.tableHeaderViewHeight(in: self))
            tableHeaderContainerView.frame = bounds
            mainTableView.tableHeaderView = tableHeaderContainerView
        }
    }

    open func preferredProcessListViewDidScroll(scrollView: UIScrollView) {
        guard let currentScrollingListView = currentScrollingListView, let currentList = currentList else { return }
        if (mainTableView.contentOffset.y < mainTableViewMaxContentOffsetY()) {
            //mainTableView的header还没有消失，让listScrollView一直为0
            currentList.listScrollViewWillResetContentOffset?()
            setListScrollViewToMinContentOffsetY(currentScrollingListView)
            if automaticallyDisplayListVerticalScrollIndicator {
                currentScrollingListView.showsVerticalScrollIndicator = false
            }
        } else {
            //mainTableView的header刚好消失，固定mainTableView的位置，显示listScrollView的滚动条
            setMainTableViewToMaxContentOffsetY()
            if automaticallyDisplayListVerticalScrollIndicator {
                currentScrollingListView.showsVerticalScrollIndicator = true
            }
        }
    }

    open func preferredProcessMainTableViewDidScroll(_ scrollView: UIScrollView) {
        guard let currentScrollingListView = currentScrollingListView else { return }
        if (currentScrollingListView.contentOffset.y > minContentOffsetYInListScrollView(currentScrollingListView)) {
            //mainTableView的header已经滚动不见，开始滚动某一个listView，那么固定mainTableView的contentOffset，让其不动
            setMainTableViewToMaxContentOffsetY()
        }

        if (mainTableView.contentOffset.y < mainTableViewMaxContentOffsetY()) {
            //mainTableView已经显示了header，listView的contentOffset需要重置
            for list in validListDict.values {
                list.listScrollViewWillResetContentOffset?()
                setListScrollViewToMinContentOffsetY(list.listScrollView())
            }
        }

        if scrollView.contentOffset.y > mainTableViewMaxContentOffsetY() && currentScrollingListView.contentOffset.y == minContentOffsetYInListScrollView(currentScrollingListView) {
            //当往上滚动mainTableView的headerView时，滚动到底时，修复listView往上小幅度滚动
            setMainTableViewToMaxContentOffsetY()
        }
    }

    //MARK: - Private

    func refreshTableHeaderView() {
        guard let delegate = delegate else { return }
        let tableHeaderView = delegate.tableHeaderView(in: self)
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat(delegate.tableHeaderViewHeight(in: self))))
        containerView.addSubview(tableHeaderView)
        tableHeaderView.translatesAutoresizingMaskIntoConstraints = false
        let top = NSLayoutConstraint(item: tableHeaderView, attribute: .top, relatedBy: .equal, toItem: containerView, attribute: .top, multiplier: 1, constant: 0)
        let leading = NSLayoutConstraint(item: tableHeaderView, attribute: .leading, relatedBy: .equal, toItem: containerView, attribute: .leading, multiplier: 1, constant: 0)
        let bottom = NSLayoutConstraint(item: tableHeaderView, attribute: .bottom, relatedBy: .equal, toItem: containerView, attribute: .bottom, multiplier: 1, constant: 0)
        let trailing = NSLayoutConstraint(item: tableHeaderView, attribute: .trailing, relatedBy: .equal, toItem: containerView, attribute: .trailing, multiplier: 1, constant: 0)
        containerView.addConstraints([top, leading, bottom, trailing])
        tableHeaderContainerView = containerView
        mainTableView.tableHeaderView = containerView
    }

    func adjustMainScrollViewToTargetContentInsetIfNeeded(inset: UIEdgeInsets) {
        if mainTableView.contentInset != inset {
            //防止循环调用
            mainTableView.delegate = nil
            mainTableView.contentInset = inset
            mainTableView.delegate = self
        }
    }

    //仅用于处理设置了pinSectionHeaderVerticalOffset，又添加了MJRefresh的下拉刷新。这种情况会导致FWPagingView和MJRefresh来回设置contentInset值。针对这种及其特殊的情况，就内部特殊处理了。通过下面的判断条件，来判定当前是否处于下拉刷新中。请勿让pinSectionHeaderVerticalOffset和下拉刷新设置的contentInset.top值相同。
    //具体原因参考：https://github.com/pujiaxin33/FWPagingView/issues/203
    func isSetMainScrollViewContentInsetToZeroEnabled(scrollView: UIScrollView) -> Bool {
        return !(scrollView.contentInset.top != 0 && scrollView.contentInset.top != CGFloat(pinSectionHeaderVerticalOffset))
    }

    func mainTableViewMaxContentOffsetY() -> CGFloat {
        guard let delegate = delegate else { return 0 }
        return CGFloat(delegate.tableHeaderViewHeight(in: self)) - CGFloat(pinSectionHeaderVerticalOffset)
    }

    public func setMainTableViewToMaxContentOffsetY() {
        mainTableView.contentOffset = CGPoint(x: 0, y: mainTableViewMaxContentOffsetY())
    }

    func minContentOffsetYInListScrollView(_ scrollView: UIScrollView) -> CGFloat {
        if #available(iOS 11.0, *) {
            return -scrollView.adjustedContentInset.top
        }
        return -scrollView.contentInset.top
    }

    func setListScrollViewToMinContentOffsetY(_ scrollView: UIScrollView) {
        scrollView.contentOffset = CGPoint(x: scrollView.contentOffset.x, y: minContentOffsetYInListScrollView(scrollView))
    }

    func pinSectionHeaderHeight() -> CGFloat {
        guard let delegate = delegate else { return 0 }
        return CGFloat(delegate.heightForPinSectionHeader(in: self))
    }

    /// 外部传入的listView，当其内部的scrollView滚动时，需要调用该方法
    func listViewDidScroll(scrollView: UIScrollView) {
        currentScrollingListView = scrollView
        preferredProcessListViewDidScroll(scrollView: scrollView)
    }
    
    public func scrollToIndex(_ index: Int, animated: Bool = true) {
        listContainerView.contentScrollView().setContentOffset(CGPoint(x: listContainerView.contentScrollView().bounds.size.width * CGFloat(index), y: 0), animated: animated)
        listContainerView.didClickSelectedItem(at: index)
    }
}

//MARK: - UITableViewDataSource, UITableViewDelegate
@objc
extension FWPagingView: UITableViewDataSource, UITableViewDelegate {
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return max(bounds.height - pinSectionHeaderHeight() - CGFloat(pinSectionHeaderVerticalOffset), 0)
    }

    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        cell.selectionStyle = .none
        cell.backgroundColor = UIColor.clear
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        listContainerView.frame = cell.bounds
        cell.contentView.addSubview(listContainerView)
        return cell
    }

    open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return pinSectionHeaderHeight()
    }

    open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let delegate = delegate else { return nil }
        return delegate.viewForPinSectionHeader(in: self)
    }

    //加上footer之后，下滑滚动就变得丝般顺滑了
    open func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }

    open func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView(frame: CGRect.zero)
        footerView.backgroundColor = UIColor.clear
        return footerView
    }

    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if pinSectionHeaderVerticalOffset != 0 {
            if !(currentScrollingListView != nil && currentScrollingListView!.contentOffset.y > minContentOffsetYInListScrollView(currentScrollingListView!)) {
                //没有处于滚动某一个listView的状态
                if scrollView.contentOffset.y >= CGFloat(pinSectionHeaderVerticalOffset) {
                    //固定的位置就是contentInset.top
                   adjustMainScrollViewToTargetContentInsetIfNeeded(inset: UIEdgeInsets(top: CGFloat(pinSectionHeaderVerticalOffset), left: 0, bottom: 0, right: 0))
                }else {
                    if isSetMainScrollViewContentInsetToZeroEnabled(scrollView: scrollView) {
                        adjustMainScrollViewToTargetContentInsetIfNeeded(inset: UIEdgeInsets.zero)
                    }
                }
            }
        }
        preferredProcessMainTableViewDidScroll(scrollView)
        delegate?.pagingView?(self, mainTableViewDidScroll: scrollView)
    }

    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        //用户正在上下滚动的时候，就不允许左右滚动
        listContainerView.scrollView.isScrollEnabled = false
        delegate?.pagingView?(self, mainTableViewWillBeginDragging: scrollView)
    }

    open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if isListHorizontalScrollEnabled && !decelerate {
            listContainerView.scrollView.isScrollEnabled = true
        }
        delegate?.pagingView?(self, mainTableViewDidEndDragging: scrollView, willDecelerate: decelerate)
    }

    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if isListHorizontalScrollEnabled {
            listContainerView.scrollView.isScrollEnabled = true
        }
        if isSetMainScrollViewContentInsetToZeroEnabled(scrollView: scrollView) {
            if mainTableView.contentInset.top != 0 && pinSectionHeaderVerticalOffset != 0 {
                adjustMainScrollViewToTargetContentInsetIfNeeded(inset: UIEdgeInsets.zero)
            }
        }
        delegate?.pagingView?(self, mainTableViewDidEndDecelerating: scrollView)
    }

    open func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if isListHorizontalScrollEnabled {
            listContainerView.scrollView.isScrollEnabled = true
        }
        delegate?.pagingView?(self, mainTableViewDidEndScrollingAnimation: scrollView)
    }
}

@objc
extension FWPagingView: FWPagingListContainerViewDataSource {
    public func numberOfLists(in listContainerView: FWPagingListContainerView) -> Int {
        guard let delegate = delegate else { return 0 }
        return delegate.numberOfLists(in: self)
    }

    public func listContainerView(_ listContainerView: FWPagingListContainerView, initListAt index: Int) -> FWPagingViewListViewDelegate {
        guard let delegate = delegate else { fatalError("FWPaingView.delegate must not be nil") }
        var list = validListDict[index]
        if list == nil {
            list = delegate.pagingView(self, initListAtIndex: index)
            list?.listViewDidScrollCallback {[weak self, weak list] (scrollView) in
                self?.currentList = list
                self?.listViewDidScroll(scrollView: scrollView)
            }
            validListDict[index] = list!
        }
        return list!
    }

    public func scrollViewClass(in listContainerView: FWPagingListContainerView) -> AnyClass {
        if let any = delegate?.scrollViewClassInListContainerView?(in: self) {
            return any
        }
        return UIView.self
    }
}

@objc
extension FWPagingView: FWPagingListContainerViewDelegate {
    public func listContainerViewWillBeginDragging(_ listContainerView: FWPagingListContainerView) {
        mainTableView.isScrollEnabled = false
    }

    public func listContainerViewDidEndScrolling(_ listContainerView: FWPagingListContainerView) {
        mainTableView.isScrollEnabled = true
    }

    public func listContainerView(_ listContainerView: FWPagingListContainerView, listDidAppearAt index: Int) {
        currentScrollingListView = validListDict[index]?.listScrollView()
        for listItem in validListDict.values {
            if listItem === validListDict[index] {
                listItem.listScrollView().scrollsToTop = true
            }else {
                listItem.listScrollView().scrollsToTop = false
            }
        }
        delegate?.pagingView?(self, didScrollToIndex: index)
    }
}

// MARK: - FWPagingListRefreshView

@objcMembers
open class FWPagingListRefreshView: FWPagingView {
    private var lastScrollingListViewContentOffsetY: CGFloat = 0

    public override init(delegate: FWPagingViewDelegate, listContainerType: FWPagingListContainerType = .collectionView) {
        super.init(delegate: delegate, listContainerType: listContainerType)

        mainTableView.bounces = false
    }

    override open func preferredProcessMainTableViewDidScroll(_ scrollView: UIScrollView) {
        if pinSectionHeaderVerticalOffset != 0 {
            if !(currentScrollingListView != nil && currentScrollingListView!.contentOffset.y > minContentOffsetYInListScrollView(currentScrollingListView!)) {
                //没有处于滚动某一个listView的状态
                if scrollView.contentOffset.y <= 0 {
                    mainTableView.bounces = false
                    mainTableView.contentOffset = CGPoint.zero
                    return
                }else {
                    mainTableView.bounces = true
                }
            }
        }
        guard let currentScrollingListView = currentScrollingListView else { return }
        if (currentScrollingListView.contentOffset.y > minContentOffsetYInListScrollView(currentScrollingListView)) {
            //mainTableView的header已经滚动不见，开始滚动某一个listView，那么固定mainTableView的contentOffset，让其不动
            setMainTableViewToMaxContentOffsetY()
        }

        if (mainTableView.contentOffset.y < mainTableViewMaxContentOffsetY()) {
            //mainTableView已经显示了header，listView的contentOffset需要重置
            for list in validListDict.values {
                //正在下拉刷新时，不需要重置
                if list.listScrollView().contentOffset.y > minContentOffsetYInListScrollView(list.listScrollView()) {
                    setListScrollViewToMinContentOffsetY(list.listScrollView())
                }
            }
        }

        if scrollView.contentOffset.y > mainTableViewMaxContentOffsetY() && currentScrollingListView.contentOffset.y == minContentOffsetYInListScrollView(currentScrollingListView) {
            //当往上滚动mainTableView的headerView时，滚动到底时，修复listView往上小幅度滚动
            setMainTableViewToMaxContentOffsetY()
        }
    }
    
    override open func preferredProcessListViewDidScroll(scrollView: UIScrollView) {
        guard let currentScrollingListView = currentScrollingListView else { return }
        var shouldProcess = true
        if currentScrollingListView.contentOffset.y > lastScrollingListViewContentOffsetY {
            //往上滚动
        }else {
            //往下滚动
            if mainTableView.contentOffset.y == 0 {
                shouldProcess = false
            }else {
                if (mainTableView.contentOffset.y < mainTableViewMaxContentOffsetY()) {
                    //mainTableView的header还没有消失，让listScrollView一直为0
                    setListScrollViewToMinContentOffsetY(currentScrollingListView)
                    currentScrollingListView.showsVerticalScrollIndicator = false;
                }
            }
        }
        if shouldProcess {
            if (mainTableView.contentOffset.y < mainTableViewMaxContentOffsetY()) {
                //处于下拉刷新的状态，scrollView.contentOffset.y为负数，就重置为0
                if currentScrollingListView.contentOffset.y > minContentOffsetYInListScrollView(currentScrollingListView) {
                    //mainTableView的header还没有消失，让listScrollView一直为0
                    setListScrollViewToMinContentOffsetY(currentScrollingListView)
                    currentScrollingListView.showsVerticalScrollIndicator = false;
                }
            } else {
                //mainTableView的header刚好消失，固定mainTableView的位置，显示listScrollView的滚动条
                setMainTableViewToMaxContentOffsetY()
                currentScrollingListView.showsVerticalScrollIndicator = true;
            }
        }
        lastScrollingListViewContentOffsetY = currentScrollingListView.contentOffset.y;
    }

}

// MARK: - FWPagingSmoothView

@objc public protocol FWPagingSmoothViewListViewDelegate {
    /// 返回listView。如果是vc包裹的就是vc.view；如果是自定义view包裹的，就是自定义view自己。
    func listView() -> UIView
    /// 返回FWPagerSmoothViewListViewDelegate内部持有的UIScrollView或UITableView或UICollectionView
    func listScrollView() -> UIScrollView
    @objc optional func listDidAppear()
    @objc optional func listDidDisappear()
}

@objc
public protocol FWPagingSmoothViewDataSource {
    /// 返回页面header的高度
    func heightForPagingHeader(in pagingView: FWPagingSmoothView) -> CGFloat
    /// 返回页面header视图
    func viewForPagingHeader(in pagingView: FWPagingSmoothView) -> UIView
    /// 返回悬浮视图的高度
    func heightForPinHeader(in pagingView: FWPagingSmoothView) -> CGFloat
    /// 返回悬浮视图
    func viewForPinHeader(in pagingView: FWPagingSmoothView) -> UIView
    /// 返回列表的数量
    func numberOfLists(in pagingView: FWPagingSmoothView) -> Int
    /// 根据index初始化一个对应列表实例，需要是遵从`FWPagingSmoothViewListViewDelegate`协议的对象。
    /// 如果列表是用自定义UIView封装的，就让自定义UIView遵从`FWPagingSmoothViewListViewDelegate`协议，该方法返回自定义UIView即可。
    /// 如果列表是用自定义UIViewController封装的，就让自定义UIViewController遵从`FWPagingSmoothViewListViewDelegate`协议，该方法返回自定义UIViewController即可。
    func pagingView(_ pagingView: FWPagingSmoothView, initListAtIndex index: Int) -> FWPagingSmoothViewListViewDelegate
}

@objc
public protocol FWPagingSmoothViewDelegate {
    @objc optional func pagingSmoothViewDidScroll(_ scrollView: UIScrollView)
}

@objcMembers
open class FWPagingSmoothView: UIView {
    public private(set) var listDict = [Int : FWPagingSmoothViewListViewDelegate]()
    public let listCollectionView: FWPagingSmoothCollectionView
    public var defaultSelectedIndex: Int = 0
    public weak var delegate: FWPagingSmoothViewDelegate?

    weak var dataSource: FWPagingSmoothViewDataSource?
    var listHeaderDict = [Int : UIView]()
    var isSyncListContentOffsetEnabled: Bool = false
    let pagingHeaderContainerView: UIView
    var currentPagingHeaderContainerViewY: CGFloat = 0
    var currentIndex: Int = 0
    var currentListScrollView: UIScrollView?
    var heightForPagingHeader: CGFloat = 0
    var heightForPinHeader: CGFloat = 0
    var heightForPagingHeaderContainerView: CGFloat = 0
    let cellIdentifier = "cell"
    var currentListInitializeContentOffsetY: CGFloat = 0
    var singleScrollView: UIScrollView?

    deinit {
        listDict.values.forEach {
            $0.listScrollView().removeObserver(self, forKeyPath: "contentOffset")
            $0.listScrollView().removeObserver(self, forKeyPath: "contentSize")
        }
    }

    public init(dataSource: FWPagingSmoothViewDataSource) {
        self.dataSource = dataSource
        pagingHeaderContainerView = UIView()
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .horizontal
        listCollectionView = FWPagingSmoothCollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        super.init(frame: CGRect.zero)

        listCollectionView.dataSource = self
        listCollectionView.delegate = self
        listCollectionView.isPagingEnabled = true
        listCollectionView.bounces = false
        listCollectionView.showsHorizontalScrollIndicator = false
        listCollectionView.scrollsToTop = false
        listCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: cellIdentifier)
        if #available(iOS 10.0, *) {
            listCollectionView.isPrefetchingEnabled = false
        }
        if #available(iOS 11.0, *) {
            listCollectionView.contentInsetAdjustmentBehavior = .never
        }
        listCollectionView.pagingHeaderContainerView = pagingHeaderContainerView
        addSubview(listCollectionView)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func reloadData() {
        guard let dataSource = dataSource else { return }
        currentListScrollView = nil
        currentIndex = defaultSelectedIndex
        currentPagingHeaderContainerViewY = 0
        isSyncListContentOffsetEnabled = false

        listHeaderDict.removeAll()
        listDict.values.forEach { (list) in
            list.listScrollView().removeObserver(self, forKeyPath: "contentOffset")
            list.listScrollView().removeObserver(self, forKeyPath: "contentSize")
            list.listView().removeFromSuperview()
        }
        listDict.removeAll()

        heightForPagingHeader = dataSource.heightForPagingHeader(in: self)
        heightForPinHeader = dataSource.heightForPinHeader(in: self)
        heightForPagingHeaderContainerView = heightForPagingHeader + heightForPinHeader

        let pagingHeader = dataSource.viewForPagingHeader(in: self)
        let pinHeader = dataSource.viewForPinHeader(in: self)
        pagingHeaderContainerView.addSubview(pagingHeader)
        pagingHeaderContainerView.addSubview(pinHeader)

        pagingHeaderContainerView.frame = CGRect(x: 0, y: 0, width: bounds.size.width, height: heightForPagingHeaderContainerView)
        pagingHeader.frame = CGRect(x: 0, y: 0, width: bounds.size.width, height: heightForPagingHeader)
        pinHeader.frame = CGRect(x: 0, y: heightForPagingHeader, width: bounds.size.width, height: heightForPinHeader)
        listCollectionView.setContentOffset(CGPoint(x: listCollectionView.bounds.size.width*CGFloat(defaultSelectedIndex), y: 0), animated: false)
        listCollectionView.reloadData()

        if dataSource.numberOfLists(in: self) == 0 {
            singleScrollView = UIScrollView()
            addSubview(singleScrollView!)
            singleScrollView?.addSubview(pagingHeader)
            singleScrollView?.contentSize = CGSize(width: bounds.size.width, height: heightForPagingHeader)
        }else if singleScrollView != nil {
            singleScrollView?.removeFromSuperview()
            singleScrollView = nil
        }
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        listCollectionView.frame = bounds
        if pagingHeaderContainerView.frame == CGRect.zero {
            reloadData()
        }
        if singleScrollView != nil {
            singleScrollView?.frame = bounds
        }
    }

    func listDidScroll(scrollView: UIScrollView) {
        if listCollectionView.isDragging || listCollectionView.isDecelerating {
            return
        }
        let index = listIndex(for: scrollView)
        if index != currentIndex {
            return
        }
        currentListScrollView = scrollView
        let contentOffsetY = scrollView.contentOffset.y + heightForPagingHeaderContainerView
        if contentOffsetY < heightForPagingHeader {
            isSyncListContentOffsetEnabled = true
            currentPagingHeaderContainerViewY = -contentOffsetY
            for list in listDict.values {
                if list.listScrollView() != currentListScrollView {
                    list.listScrollView().setContentOffset(scrollView.contentOffset, animated: false)
                }
            }
            let header = listHeader(for: scrollView)
            if pagingHeaderContainerView.superview != header {
                pagingHeaderContainerView.frame.origin.y = 0
                header?.addSubview(pagingHeaderContainerView)
            }
        }else {
            if pagingHeaderContainerView.superview != self {
                pagingHeaderContainerView.frame.origin.y = -heightForPagingHeader
                addSubview(pagingHeaderContainerView)
            }
            if isSyncListContentOffsetEnabled {
                isSyncListContentOffsetEnabled = false
                currentPagingHeaderContainerViewY = -heightForPagingHeader
                for list in listDict.values {
                    if list.listScrollView() != currentListScrollView {
                        list.listScrollView().setContentOffset(CGPoint(x: 0, y: -heightForPinHeader), animated: false)
                    }
                }
            }
        }
    }

    //MARK: - KVO

    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "contentOffset" {
            if let scrollView = object as? UIScrollView {
                listDidScroll(scrollView: scrollView)
            }
        }else if keyPath == "contentSize" {
            if let scrollView = object as? UIScrollView {
                let minContentSizeHeight = bounds.size.height - heightForPinHeader
                if minContentSizeHeight > scrollView.contentSize.height {
                    scrollView.contentSize = CGSize(width: scrollView.contentSize.width, height: minContentSizeHeight)
                    //新的scrollView第一次加载的时候重置contentOffset
                    if currentListScrollView != nil, scrollView != currentListScrollView! {
                        scrollView.contentOffset = CGPoint(x: 0, y: currentListInitializeContentOffsetY)
                    }
                }
            }
        }else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    //MARK: - Private
    func listHeader(for listScrollView: UIScrollView) -> UIView? {
        for (index, list) in listDict {
            if list.listScrollView() == listScrollView {
                return listHeaderDict[index]
            }
        }
        return nil
    }

    func listIndex(for listScrollView: UIScrollView) -> Int {
        for (index, list) in listDict {
            if list.listScrollView() == listScrollView {
                return index
            }
        }
        return 0
    }

    func listDidAppear(at index: Int) {
        guard let dataSource = dataSource else { return }
        let count = dataSource.numberOfLists(in: self)
        if count <= 0 || index >= count {
            return
        }
        listDict[index]?.listDidAppear?()
    }

    func listDidDisappear(at index: Int) {
        guard let dataSource = dataSource else { return }
        let count = dataSource.numberOfLists(in: self)
        if count <= 0 || index >= count {
            return
        }
        listDict[index]?.listDidDisappear?()
    }

    /// 列表左右切换滚动结束之后，需要把pagerHeaderContainerView添加到当前index的列表上面
    func horizontalScrollDidEnd(at index: Int) {
        currentIndex = index
        guard let listHeader = listHeaderDict[index], let listScrollView = listDict[index]?.listScrollView() else {
            return
        }
        listDict.values.forEach { $0.listScrollView().scrollsToTop = ($0.listScrollView() === listScrollView) }
        if listScrollView.contentOffset.y <= -heightForPinHeader {
            pagingHeaderContainerView.frame.origin.y = 0
            listHeader.addSubview(pagingHeaderContainerView)
        }
    }
}

@objc
extension FWPagingSmoothView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return bounds.size
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let dataSource = dataSource else { return 0 }
        return dataSource.numberOfLists(in: self)
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let dataSource = dataSource else { return UICollectionViewCell(frame: CGRect.zero) }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath)
        var list = listDict[indexPath.item]
        if list == nil {
            list = dataSource.pagingView(self, initListAtIndex: indexPath.item)
            listDict[indexPath.item] = list!
            list?.listView().setNeedsLayout()
            list?.listView().layoutIfNeeded()
            if list?.listScrollView().isKind(of: UITableView.self) == true {
                (list?.listScrollView() as? UITableView)?.estimatedRowHeight = 0
                (list?.listScrollView() as? UITableView)?.estimatedSectionHeaderHeight = 0
                (list?.listScrollView() as? UITableView)?.estimatedSectionFooterHeight = 0
            }
            if #available(iOS 11.0, *) {
                list?.listScrollView().contentInsetAdjustmentBehavior = .never
            }
            list?.listScrollView().contentInset = UIEdgeInsets(top: heightForPagingHeaderContainerView, left: 0, bottom: 0, right: 0)
            currentListInitializeContentOffsetY = -heightForPagingHeaderContainerView + min(-currentPagingHeaderContainerViewY, heightForPagingHeader)
            list?.listScrollView().contentOffset = CGPoint(x: 0, y: currentListInitializeContentOffsetY)
            let listHeader = UIView(frame: CGRect(x: 0, y: -heightForPagingHeaderContainerView, width: bounds.size.width, height: heightForPagingHeaderContainerView))
            list?.listScrollView().addSubview(listHeader)
            if pagingHeaderContainerView.superview == nil {
                listHeader.addSubview(pagingHeaderContainerView)
            }
            listHeaderDict[indexPath.item] = listHeader
            list?.listScrollView().addObserver(self, forKeyPath: "contentOffset", options: .new, context: nil)
            list?.listScrollView().addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        }
        listDict.values.forEach { $0.listScrollView().scrollsToTop = ($0 === list) }
        if let listView = list?.listView(), listView.superview != cell.contentView {
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }
            listView.frame = cell.contentView.bounds
            cell.contentView.addSubview(listView)
        }
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        listDidAppear(at: indexPath.item)
    }

    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        listDidDisappear(at: indexPath.item)
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.pagingSmoothViewDidScroll?(scrollView)
        let index = Int(scrollView.contentOffset.x/scrollView.bounds.size.width)
        let listScrollView = listDict[index]?.listScrollView()
        if index != currentIndex && !(scrollView.isDragging || scrollView.isDecelerating) && listScrollView?.contentOffset.y ?? 0 <= -heightForPinHeader {
            horizontalScrollDidEnd(at: index)
        }else {
            //左右滚动的时候，就把listHeaderContainerView添加到self，达到悬浮在顶部的效果
            if pagingHeaderContainerView.superview != self {
                pagingHeaderContainerView.frame.origin.y = currentPagingHeaderContainerViewY
                addSubview(pagingHeaderContainerView)
            }
        }
        if index != currentIndex {
            currentIndex = index
        }
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            let index = Int(scrollView.contentOffset.x/scrollView.bounds.size.width)
            horizontalScrollDidEnd(at: index)
        }
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let index = Int(scrollView.contentOffset.x/scrollView.bounds.size.width)
        horizontalScrollDidEnd(at: index)
    }
}

@objcMembers
public class FWPagingSmoothCollectionView: UICollectionView, UIGestureRecognizerDelegate {
    var pagingHeaderContainerView: UIView?
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let point = touch.location(in: pagingHeaderContainerView)
        if pagingHeaderContainerView?.bounds.contains(point) == true {
            return false
        }
        return true
    }
}
