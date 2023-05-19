//
//  BannerView.swift
//  FWFramework
//
//  Created by wuyong on 2023/5/19.
//

import UIKit

/// BannerView分页控件对齐方式枚举
public enum BannerViewPageControlAlignment: Int {
    /// 右对齐
    case right
    /// 居中对齐
    case center
}

/// BannerView分页控件样式枚举
public enum BannerViewPageControlStyle: Int {
    /// 系统样式
    case system
    /// 自定义样式，可设置图片等
    case custom
    /// 不显示
    case none
}

/// Banner视图事件代理
@objc public protocol BannerViewDelegate {
    
    /// 选中指定index
    @objc optional func bannerView(_ bannerView: BannerView, didSelectItemAt index: Int)
    /// 监听bannerView滚动，快速滚动时也会回调
    @objc optional func bannerView(_ bannerView: BannerView, didScrollToItemAt index: Int)
    /// 如果你需要自定义UICollectionViewCell样式，请实现此代理方法，默认的BannerViewCell也会调用
    @objc optional func bannerView(_ bannerView: BannerView, customCell: UICollectionViewCell, for index: Int)
    /// 如果你需要自定义UICollectionViewCell样式，请实现此代理方法返回你的自定义UICollectionViewCell的class
    @objc optional func customCellClass(bannerView: BannerView) -> UICollectionViewCell.Type?
    /// 如果你需要自定义UICollectionViewCell样式，请实现此代理方法返回你的自定义UICollectionViewCell的Nib
    @objc optional func customCellNib(bannerView: BannerView) -> UINib?
    
}

/// Banner视图
///
/// [SDCycleScrollView](https://github.com/gsdios/SDCycleScrollView)
open class BannerView: UIView {
    
    /// 图片数组，支持String|URL|UIImage
    open var imagesGroup: [Any]?
    
    /// 每张图片对应要显示的文字数组
    open var titlesGroup: [String]?
    
    /// 自动滚动间隔时间,默认2s
    open var autoScrollTimeInterval: TimeInterval = 2.0
    
    /// 是否无限循环，默认true
    open var infiniteLoop: Bool = true
    
    /// 是否自动滚动，默认true
    open var autoScroll: Bool = true
    
    /// 图片滚动方向，默认为水平滚动
    open var scrollDirection: UICollectionView.ScrollDirection = .horizontal
    
    /// 是否启用根据item分页滚动，默认false，根据frame大小滚动
    open var itemPagingEnabled: Bool = false
    
    /// 整体布局尺寸，默认0占满视图，itemPagingEnabled启用后生效
    open var itemSize: CGSize = .zero
    
    /// 整体布局间隔，默认0，itemPagingEnabled启用后生效
    open var itemSpacing: CGFloat = .zero
    
    /// 是否设置item分页停留位置居中，默认false，停留左侧，itemPagingEnabled启用后生效
    open var itemPagingCenter: Bool = false
    
    /// 事件代理
    open weak var delegate: BannerViewDelegate?
    
    /// 句柄方式监听点击，参数为index
    open var didSelectItemBlock: ((Int) -> Void)?
    
    /// 句柄方式监听滚动，快速滚动时也会回调，参数为index
    open var didScrollToItemBlock: ((Int) -> Void)?
    
    /// 自定义cell句柄，参数为cell和index
    open var customCellBlock: ((UICollectionViewCell, Int) -> Void)?
    
    /// 轮播图片的ContentMode，默认为scaleAspectFill
    open var imageViewContentMode: UIView.ContentMode = .scaleAspectFill
    
    /// 占位图，用于网络未加载到图片时
    open var placeholderImage: UIImage?
    
    /// 是否显示分页控件
    open var showsPageControl: Bool = true
    
    /// 自定义pageControl控件，初始化后调用
    open var customPageControl: ((UIControl) -> Void)?
    
    /// 是否在只有一张图时隐藏pagecontrol，默认为true
    open var hidesForSinglePage: Bool = true
    
    /// 只展示文字轮播
    open var onlyDisplayText: Bool = false
    
    /// pageControl 样式，默认为系统样式
    open var pageControlStyle: BannerViewPageControlStyle = .system
    
    /// 分页控件位置
    open var pageControlAlignment: BannerViewPageControlAlignment = .center
    
    /// 分页控件距离轮播图的底部间距（在默认间距基础上）的偏移量
    open var pageControlBottomOffset: CGFloat = .zero
    
    /// 分页控件距离轮播图的右边间距（在默认间距基础上）的偏移量
    open var pageControlRightOffset: CGFloat = .zero
    
    /// 分页控件小圆标大小
    open var pageControlDotSize: CGSize = CGSize(width: 10, height: 10)
    
    /// 分页控件小圆标间隔
    open var pageControlDotSpacing: CGFloat = -1
    
    /// 当前分页控件小圆标颜色
    open var currentPageDotColor: UIColor? = .white
    
    /// 其他分页控件小圆标颜色
    open var pageDotColor: UIColor? = .white.withAlphaComponent(0.5)
    
    /// 当前分页控件小圆标图片
    open var currentPageDotImage: UIImage?
    
    /// 其他分页控件小圆标图片
    open var pageDotImage: UIImage?
    
    /// 分页控件自定义视图类，默认为DotView
    open var pageDotViewClass: (UIView & DotViewProtocol).Type? = DotView.self
    
    /// 轮播文字label字体颜色
    open var titleLabelTextColor: UIColor? = .white
    
    /// 轮播文字label字体
    open var titleLabelTextFont: UIFont? = .systemFont(ofSize: 14)
    
    /// 轮播文字label背景颜色
    open var titleLabelBackgroundColor: UIColor? = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
    
    /// 轮播文字label高度
    open var titleLabelHeight: CGFloat = 30
    
    /// 轮播文字label对齐方式
    open var titleLabelTextAlignment: NSTextAlignment = .left
    
    /// 内容视图间距设置，默认全部0
    open var contentViewInset: UIEdgeInsets = .zero
    
    /// 内容视图圆角设置，默认0
    open var contentViewCornerRadius: CGFloat = .zero
    
    private var pageControlIndex: Int = -1
    
    // MARK: - Lifecycle
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .clear
        setupMainView()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        backgroundColor = .clear
        setupMainView()
    }
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundColor = .clear
        setupMainView()
    }
    
    // MARK: - Public
    /// 手工滚动到指定index，可指定动画
    open func scrollToIndex(_ index: Int, animated: Bool = false) {
        
    }
    
    /// 滚动手势禁用（文字轮播较实用）
    open func disableScrollGesture() {
        
    }
    
    /// 解决viewWillAppear时出现时轮播图卡在一半的问题，在控制器viewWillAppear时调用此方法
    open func adjustWhenViewWillAppear() {
        
    }
    
    // MARK: - Private
    private func setupMainView() {
        
    }
    
}

/// BannerView流式布局
open class BannerViewFlowLayout: UICollectionViewFlowLayout {
    
    /// 是否启用分页，默认false
    open var pagingEnabled: Bool = false
    
    /// 是否分页居中，默认false
    open var pagingCenter: Bool = false
    
    private var lastCollectionViewSize: CGSize = .zero
    private var lastScrollDirection: UICollectionView.ScrollDirection = .horizontal
    private var lastItemSize: CGSize = .zero
    
}

/// Banner视图默认Cell
open class BannerViewCell: UICollectionViewCell {
    
    /// 图片视图
    open weak var imageView: UIImageView?
    
    /// 标题
    open var title: String?
    
    /// 轮播文字label字体颜色
    open var titleLabelTextColor: UIColor? = .white
    
    /// 轮播文字label字体
    open var titleLabelTextFont: UIFont? = .systemFont(ofSize: 14)
    
    /// 轮播文字label背景颜色
    open var titleLabelBackgroundColor: UIColor? = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
    
    /// 轮播文字label高度
    open var titleLabelHeight: CGFloat = 30
    
    /// 轮播文字label对齐方式
    open var titleLabelTextAlignment: NSTextAlignment = .left
    
    /// 内容视图间距设置，默认全部0
    open var contentViewInset: UIEdgeInsets = .zero
    
    /// 内容视图圆角设置，默认0
    open var contentViewCornerRadius: CGFloat = .zero
    
    /// 是否已配置完成
    open var hasConfigured: Bool = false
    
    /// 只展示文字轮播
    open var onlyDisplayText: Bool = false
    
}
