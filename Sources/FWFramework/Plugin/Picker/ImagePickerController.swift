//
//  ImagePickerController.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
import Photos

// MARK: - ImageAlbumController
/// 相册列表事件代理
@objc public protocol ImageAlbumControllerDelegate {
    
    /// 需提供 ImagePickerController 用于展示九宫格图片列表
    @objc optional func imagePickerController(for albumController: ImageAlbumController) -> ImagePickerController
    
    /// 点击相簿里某一行时被调用，未实现时默认打开imagePickerController
    @objc optional func albumController(_ albumController: ImageAlbumController, didSelect assetsGroup: AssetGroup)
    
    /// 自定义相册列表cell展示，cellForRow自动调用
    @objc optional func albumController(_ albumController: ImageAlbumController, customCell cell: ImageAlbumTableCell, at indexPath: IndexPath)
    
    /// 取消查看相册列表后被调用，未实现时自动转发给当前imagePickerController
    @objc optional func albumControllerDidCancel(_ albumController: ImageAlbumController)
    
    /// 即将需要显示 Loading 时调用，可自定义Loading效果
    @objc optional func albumControllerWillStartLoading(_ albumController: ImageAlbumController)
    
    /// 需要隐藏 Loading 时调用，可自定义Loading效果
    @objc optional func albumControllerDidFinishLoading(_ albumController: ImageAlbumController)
    
    /// 相册列表未授权时调用，可自定义空界面等
    @objc optional func albumControllerWillShowDenied(_ albumController: ImageAlbumController)
    
    /// 相册列表为空时调用，可自定义空界面等
    @objc optional func albumControllerWillShowEmpty(_ albumController: ImageAlbumController)
    
}

/// 当前设备照片里的相簿列表
///
/// 使用方式：
/// 1. 使用 init 初始化。
/// 2. 指定一个 albumControllerDelegate，并实现 @required 方法。
///
/// 注意，iOS 访问相册需要得到授权，建议先询问用户授权([AssetsManager requestAuthorization:])，通过了再进行 ImageAlbumController 的初始化工作。
open class ImageAlbumController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    /// 工具栏背景色
    open var toolbarBackgroundColor: UIColor? = UIColor(red: 27.0 / 255.0, green: 27.0 / 255.0, blue: 27.0 / 255.0, alpha: 1.0) {
        didSet {
            navigationController?.navigationBar.fw.backgroundColor = toolbarBackgroundColor
        }
    }
    /// 工具栏颜色
    open var toolbarTintColor: UIColor? = .white {
        didSet {
            navigationController?.navigationBar.fw.foregroundColor = toolbarTintColor
        }
    }
    
    /// 相册列表 cell 的高度，同时也是相册预览图的宽高，默认76
    open var albumTableViewCellHeight: CGFloat = 76
    /// 相册列表视图最大高度，默认0不限制
    open var maximumTableViewHeight: CGFloat = 0
    /// 相册列表附加显示高度，当内容高度小于最大高度时生效，默认0
    open var additionalTableViewHeight: CGFloat = 0
    /// 当前相册列表实际显示高度，只读
    open var tableViewHeight: CGFloat {
        if maximumTableViewHeight <= 0 {
            return view.bounds.size.height
        }
        
        let albumsHeight = CGFloat(albumsArray.count) * albumTableViewCellHeight
        return min(maximumTableViewHeight, albumsHeight + additionalTableViewHeight)
    }
    
    /// 当前相册列表，异步加载
    open private(set) var albumsArray: [AssetGroup] = []
    
    /// 相册列表事件代理
    open weak var albumControllerDelegate: ImageAlbumControllerDelegate?
    
    /// 自定义pickerController句柄，优先级低于delegate
    open var pickerControllerBlock: (() -> ImagePickerController)?
    
    /// 自定义cell展示句柄，cellForRow自动调用，优先级低于delegate
    open var customCellBlock: ((ImageAlbumTableCell, IndexPath) -> Void)?
    
    /// 相册列表默认封面图，默认nil
    open var defaultPosterImage: UIImage?
    
    /// 相册展示内容的类型，可以控制只展示照片、视频或音频的其中一种，也可以同时展示所有类型的资源，默认展示所有类型的资源。
    open var contentType: AlbumContentType = .all
    
    /// 当前选中相册，默认nil
    open internal(set) var assetsGroup: AssetGroup? {
        didSet {
            if let oldGroup = oldValue, let index = albumsArray.firstIndex(of: oldGroup) {
                let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? ImageAlbumTableCell
                cell?.checked = false
            }
            if let assetsGroup = assetsGroup, let index = albumsArray.firstIndex(of: assetsGroup) {
                let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? ImageAlbumTableCell
                cell?.checked = true
            }
        }
    }
    
    /// 是否显示默认loading，优先级低于delegate，默认YES
    open var showsDefaultLoading: Bool = true
    
    /// 是否直接进入第一个相册列表，默认NO
    open var pickDefaultAlbumGroup: Bool = false
    
    /// 背景视图，可设置背景色，添加点击手势等
    open lazy var backgroundView: UIView = {
        let result = UIView()
        return result
    }()
    
    /// 相册只读列表视图
    open lazy var tableView: UITableView = {
        let result = UITableView(frame: isViewLoaded ? view.bounds : .zero, style: .plain)
        result.separatorStyle = .none
        result.showsVerticalScrollIndicator = false
        result.showsHorizontalScrollIndicator = false
        result.dataSource = self
        result.delegate = self
        result.backgroundColor = .black
        result.contentInsetAdjustmentBehavior = .never
        if #available(iOS 15.0, *) {
            result.sectionHeaderTopPadding = 0
        }
        return result
    }()
    
    weak var imagePickerController: ImagePickerController?
    var assetsGroupSelected: ((AssetGroup) -> Void)?
    var albumsArrayLoaded: (() -> Void)?
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        didInitialize()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        didInitialize()
    }
    
    private func didInitialize() {
        extendedLayoutIncludesOpaqueBars = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: FrameworkBundle.navCloseImage, style: .plain, target: self, action: #selector(handleCancelButtonClick(_:)))
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(image: UIImage(), style: .plain, target: nil, action: nil)
        navigationController?.navigationBar.fw.backImage = FrameworkBundle.navBackImage
        if title == nil { title = FrameworkBundle.pickerAlbumTitle }
        
        view.addSubview(backgroundView)
        view.addSubview(tableView)
        
        let authorizationStatus = AssetManager.authorizationStatus
        if authorizationStatus == .notDetermined {
            AssetManager.requestAuthorization { [weak self] status in
                DispatchQueue.main.async {
                    if status == .notAuthorized {
                        self?.showDeniedView()
                    } else {
                        self?.loadAlbumArray()
                    }
                }
            }
        } else if authorizationStatus == .notAuthorized {
            showDeniedView()
        } else {
            loadAlbumArray()
        }
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navigationController = navigationController {
            if navigationController.isNavigationBarHidden != false {
                navigationController.setNavigationBarHidden(false, animated: animated)
            }
            navigationController.navigationBar.fw.isTranslucent = false
            navigationController.navigationBar.fw.shadowColor = nil
            navigationController.navigationBar.fw.backgroundColor = toolbarBackgroundColor
            navigationController.navigationBar.fw.foregroundColor = toolbarTintColor
        }
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        backgroundView.frame = view.bounds
        let contentInset = UIEdgeInsets(top: UIScreen.fw.topBarHeight, left: tableView.safeAreaInsets.left, bottom: tableView.safeAreaInsets.bottom, right: tableView.safeAreaInsets.right)
        if tableView.contentInset != contentInset {
            tableView.contentInset = contentInset
        }
    }
    
    open override var prefersStatusBarHidden: Bool {
        return false
    }
    
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: - UITableView
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return albumsArray.count
    }
    
    open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return albumTableViewCellHeight
    }
    
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ImageAlbumTableCell
        if let reuseCell = tableView.dequeueReusableCell(withIdentifier: "cell") as? ImageAlbumTableCell {
            cell = reuseCell
        } else {
            cell = ImageAlbumTableCell(style: .subtitle, reuseIdentifier: "cell")
        }
        let assetsGroup = albumsArray[indexPath.row]
        cell.imageView?.image = assetsGroup.posterImage(size: CGSize(width: cell.albumImageSize, height: cell.albumImageSize)) ?? defaultPosterImage
        cell.textLabel?.font = cell.albumNameFont
        cell.textLabel?.text = assetsGroup.name
        cell.detailTextLabel?.font = cell.albumAssetsNumberFont
        cell.detailTextLabel?.text = String(format: "· %@", "\(assetsGroup.numberOfAssets)")
        cell.checked = assetsGroup == self.assetsGroup
        
        if albumControllerDelegate?.albumController?(self, customCell: cell, at: indexPath) != nil {
        } else {
            customCellBlock?(cell, indexPath)
        }
        return cell
    }
    
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        pickAlbumsGroup(albumsArray[indexPath.row], animated: true)
    }
    
    // MARK: - Private
    private func loadAlbumArray() {
        if albumControllerDelegate?.albumControllerWillStartLoading?(self) != nil {
        } else if showsDefaultLoading {
            fw_showLoading()
        }
        
        DispatchQueue.global(qos: .default).async { [weak self] in
            AssetManager.shared.enumerateAllAlbums(albumContentType: self?.contentType ?? .all) { resultAssetsGroup in
                if let resultAssetsGroup = resultAssetsGroup {
                    self?.albumsArray.append(resultAssetsGroup)
                } else {
                    // 意味着遍历完所有的相簿了
                    self?.sortAlbumArray()
                    DispatchQueue.main.async {
                        self?.refreshAlbumGroups()
                    }
                }
            }
        }
    }
    
    private func sortAlbumArray() {
        // 把隐藏相册排序强制放到最后
        var hiddenGroup: AssetGroup?
        for album in albumsArray {
            if album.phAssetCollection.assetCollectionSubtype == .smartAlbumAllHidden {
                hiddenGroup = album
                break
            }
        }
        
        if let hiddenGroup = hiddenGroup {
            albumsArray.removeAll(where: { $0 == hiddenGroup })
            albumsArray.append(hiddenGroup)
        }
    }
    
    private func refreshAlbumGroups() {
        if albumControllerDelegate?.albumControllerDidFinishLoading?(self) != nil {
        } else if showsDefaultLoading {
            fw_hideLoading()
        }
        
        if maximumTableViewHeight > 0 {
            var tableFrame = tableView.frame
            tableFrame.size.height = tableViewHeight + UIScreen.fw.topBarHeight
            tableView.frame = tableFrame
        }
        
        if albumsArray.count > 0 {
            if pickDefaultAlbumGroup {
                pickAlbumsGroup(albumsArray.first, animated: false)
            }
            tableView.reloadData()
        } else {
            if albumControllerDelegate?.albumControllerWillShowEmpty?(self) != nil {
            } else {
                fw_showEmptyView(text: FrameworkBundle.pickerEmptyTitle)
            }
        }
        
        albumsArrayLoaded?()
    }
    
    private func showDeniedView() {
        if maximumTableViewHeight > 0 {
            var tableFrame = tableView.frame
            tableFrame.size.height = tableViewHeight + UIScreen.fw.topBarHeight
            tableView.frame = tableFrame
        }
        
        if albumControllerDelegate?.albumControllerWillShowDenied?(self) != nil {
        } else {
            let appName = UIApplication.fw_appDisplayName
            let tipText = String(format: FrameworkBundle.pickerDeniedTitle, appName)
            fw_showEmptyView(text: tipText)
        }
        
        albumsArrayLoaded?()
    }
    
    private func pickAlbumsGroup(_ assetsGroup: AssetGroup?, animated: Bool) {
        guard let assetsGroup = assetsGroup else { return }
        self.assetsGroup = assetsGroup
        
        initImagePickerControllerIfNeeded()
        if assetsGroupSelected != nil {
            assetsGroupSelected?(assetsGroup)
        } else if albumControllerDelegate?.albumController?(self, didSelect: assetsGroup) != nil {
        } else if let pickerController = imagePickerController {
            pickerController.title = assetsGroup.name
            pickerController.refresh(assetsGroup: assetsGroup)
            navigationController?.pushViewController(pickerController, animated: animated)
        }
    }
    
    private func initImagePickerControllerIfNeeded() {
        guard imagePickerController == nil else { return }
        
        var pickerController: ImagePickerController?
        if let controller = albumControllerDelegate?.imagePickerController?(for: self) {
            pickerController = controller
        } else if let block = pickerControllerBlock {
            pickerController = block()
        }
        if let pickerController = pickerController {
            // 清空imagePickerController导航栏左侧按钮并添加默认按钮
            if pickerController.navigationItem.leftBarButtonItem != nil {
                pickerController.navigationItem.leftBarButtonItem = nil
                pickerController.navigationItem.rightBarButtonItem = UIBarButtonItem(title: FrameworkBundle.cancelButton, style: .plain, target: pickerController, action: #selector(ImagePickerController.handleCancelButtonClick(_:)))
            }
            // 此处需要强引用imagePickerController，防止weak属性释放imagePickerController
            fw.setProperty(pickerController, forName: "imagePickerController")
            self.imagePickerController = pickerController
        }
    }
    
    @objc private func handleCancelButtonClick(_ sender: Any) {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            
            if self.albumControllerDelegate?.albumControllerDidCancel?(self) != nil {
            } else {
                self.initImagePickerControllerIfNeeded()
                if let pickerController = self.imagePickerController {
                    if pickerController.imagePickerControllerDelegate?.imagePickerControllerDidCancel?(pickerController) != nil {
                    } else {
                        pickerController.didCancelPicking?()
                    }
                }
            }
            self.imagePickerController?.selectedImageAssetArray.removeAll()
        }
    }
    
}

/// 相册列表默认Cell
open class ImageAlbumTableCell: UITableViewCell {
    
    /// 相册缩略图的大小，默认60
    open var albumImageSize: CGFloat = 60
    /// 相册缩略图的 left，-1 表示自动保持与上下 margin 相等，默认16
    open var albumImageMarginLeft: CGFloat = 16
    /// 相册名称的上下左右间距
    open var albumNameInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 4)
    /// 相册名的字体
    open var albumNameFont: UIFont? = UIFont.systemFont(ofSize: 17) {
        didSet { textLabel?.font = albumNameFont }
    }
    /// 相册名的颜色
    open var albumNameColor: UIColor? = UIColor.white {
        didSet { textLabel?.textColor = albumNameColor }
    }
    /// 相册资源数量的字体
    open var albumAssetsNumberFont: UIFont? = UIFont.systemFont(ofSize: 17) {
        didSet { detailTextLabel?.font = albumAssetsNumberFont }
    }
    /// 相册资源数量的颜色
    open var albumAssetsNumberColor: UIColor? = UIColor.white {
        didSet { detailTextLabel?.textColor = albumAssetsNumberColor }
    }
    /// 选中时蒙层颜色
    open var checkedMaskColor: UIColor? {
        didSet { coverView.backgroundColor = checked ? checkedMaskColor : nil }
    }
    /// 当前是否选中
    open var checked: Bool = false {
        didSet { coverView.backgroundColor = checked ? checkedMaskColor : nil }
    }
    
    /// 蒙层视图
    open lazy var coverView: UIView = {
        let result = UIView()
        return result
    }()
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        didInitialize()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        didInitialize()
    }
    
    private func didInitialize() {
        selectionStyle = .none
        backgroundColor = .clear
        imageView?.contentMode = .scaleAspectFill
        imageView?.clipsToBounds = true
        imageView?.layer.borderWidth = 1.0 / UIScreen.main.scale
        imageView?.layer.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.1).cgColor
        textLabel?.font = albumNameFont
        textLabel?.textColor = albumNameColor
        detailTextLabel?.font = albumAssetsNumberFont
        detailTextLabel?.textColor = albumAssetsNumberColor
        
        contentView.addSubview(coverView)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        coverView.frame = CGRect(x: 0, y: 0, width: max(contentView.bounds.width, bounds.width), height: contentView.bounds.height)
        let imageEdgeTop = (contentView.bounds.height - albumImageSize) / 2.0
        let imageEdgeLeft = albumImageMarginLeft == -1 ? imageEdgeTop : albumImageMarginLeft
        imageView?.frame = CGRect(x: imageEdgeLeft, y: imageEdgeTop, width: albumImageSize, height: albumImageSize)
        
        if let textLabel = textLabel {
            var textLabelFrame = textLabel.frame
            textLabelFrame.origin = CGPoint(x: (imageView?.frame.maxX ?? 0) + albumNameInsets.left, y: ((textLabel.superview?.bounds.height ?? 0) - textLabel.frame.height) / 2.0)
            textLabel.frame = textLabelFrame
            
            let textLabelMaxWidth = contentView.bounds.width - textLabel.frame.minX - (detailTextLabel?.bounds.width ?? 0) - albumNameInsets.right
            if textLabel.bounds.width > textLabelMaxWidth {
                var textLabelFrame = textLabel.frame
                textLabelFrame.size.width = textLabelMaxWidth
                textLabel.frame = textLabelFrame
            }
        }
        
        if let detailTextLabel = detailTextLabel {
            var detailTextLabelFrame = detailTextLabel.frame
            detailTextLabelFrame.origin = CGPoint(x: (textLabel?.frame.maxX ?? 0) + albumNameInsets.right, y: ((detailTextLabel.superview?.bounds.height ?? 0) - detailTextLabel.frame.height) / 2.0)
            detailTextLabel.frame = detailTextLabelFrame
        }
    }
    
}

// MARK: - ImagePickerPreviewController
@objc public protocol ImagePickerPreviewControllerDelegate {
    
    /// 完成选中图片回调，未实现时自动转发给当前imagePickerController
    @objc optional func imagePickerPreviewController(_ imagePickerPreviewController: ImagePickerPreviewController, didFinishPickingImage imagesAssetArray: [Asset])
    
    /// 即将选中图片
    @objc optional func imagePickerPreviewController(_ imagePickerPreviewController: ImagePickerPreviewController, willCheckImageAt index: Int)
    
    /// 已经选中图片
    @objc optional func imagePickerPreviewController(_ imagePickerPreviewController: ImagePickerPreviewController, didCheckImageAt index: Int)
    
    /// 即将取消选中图片
    @objc optional func imagePickerPreviewController(_ imagePickerPreviewController: ImagePickerPreviewController, willUncheckImageAt index: Int)
    
    /// 已经取消选中图片
    @objc optional func imagePickerPreviewController(_ imagePickerPreviewController: ImagePickerPreviewController, didUncheckImageAt index: Int)
    
    /// 选中数量变化时调用，仅多选有效
    @objc optional func imagePickerPreviewController(_ imagePickerPreviewController: ImagePickerPreviewController, willChangeCheckedCount checkedCount: Int)
    
    /// 即将需要显示 Loading 时调用
    @objc optional func imagePickerPreviewControllerWillStartLoading(_ imagePickerPreviewController: ImagePickerPreviewController)
    
    /// 即将需要隐藏 Loading 时调用
    @objc optional func imagePickerPreviewControllerDidFinishLoading(_ imagePickerPreviewController: ImagePickerPreviewController)
    
    /// 已经选中数量超过最大选择数量时被调用，默认弹窗提示
    @objc optional func imagePickerPreviewControllerWillShowExceed(_ imagePickerPreviewController: ImagePickerPreviewController)
    
    /// 图片预览界面关闭返回时被调用
    @objc optional func imagePickerPreviewControllerDidCancel(_ imagePickerPreviewController: ImagePickerPreviewController)
    
    /// 自定义编辑按钮点击事件，启用编辑时生效，未实现时使用图片裁剪控制器
    @objc optional func imagePickerPreviewController(_ imagePickerPreviewController: ImagePickerPreviewController, willEditImageAt index: Int)
    
    /// 自定义图片裁剪控制器，启用编辑时生效，未实现时使用默认配置
    @objc optional func imageCropController(for imagePickerPreviewController: ImagePickerPreviewController, image: UIImage) -> ImageCropController
    
    /// 自定义编辑cell展示，cellForRow自动调用
    @objc optional func imagePickerPreviewController(_ imagePickerPreviewController: ImagePickerPreviewController, customCell cell: ImagePickerPreviewCollectionCell, at indexPath: IndexPath)
    
}

open class ImagePickerPreviewController: ImagePreviewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, ImagePreviewViewDelegate {
    
    open weak var delegate: ImagePickerPreviewControllerDelegate?
    /// 自定义裁剪控制器句柄，优先级低于delegate
    open var cropControllerBlock: ((UIImage) -> ImageCropController)?
    /// 自定义cell展示句柄，cellForItem自动调用，优先级低于delegate
    open var customCellBlock: ((_ cell: ImagePickerPreviewCollectionCell, _ indexPath: IndexPath) -> Void)?
    
    open var toolbarBackgroundColor: UIColor? = UIColor(red: 27.0 / 255.0, green: 27.0 / 255.0, blue: 27.0 / 255.0, alpha: 1.0) {
        didSet {
            topToolbarView.backgroundColor = toolbarBackgroundColor
            bottomToolbarView.backgroundColor = toolbarBackgroundColor
        }
    }
    open var toolbarTintColor: UIColor? = .white {
        didSet {
            topToolbarView.tintColor = toolbarTintColor
            bottomToolbarView.tintColor = toolbarTintColor
        }
    }
    open var toolbarPaddingHorizontal: CGFloat = 16
    /// 自定义底部工具栏高度，默认同系统
    open var bottomToolbarHeight: CGFloat {
        get { return _bottomToolbarHeight > 0 ? _bottomToolbarHeight : UIScreen.fw.toolBarHeight }
        set { _bottomToolbarHeight = newValue }
    }
    private var _bottomToolbarHeight: CGFloat = 0
    
    open var checkboxImage: UIImage? = FrameworkBundle.pickerCheckImage
    open var checkboxCheckedImage: UIImage? = FrameworkBundle.pickerCheckedImage
    
    open var originImageCheckboxImage: UIImage? = {
        return FrameworkBundle.pickerCheckImage?.fw_image(scaleSize: CGSize(width: 18, height: 18))
    }()
    open var originImageCheckboxCheckedImage: UIImage? = {
        return FrameworkBundle.pickerCheckedImage?.fw_image(scaleSize: CGSize(width: 18, height: 18))
    }()
    /// 是否使用原图，默认NO
    open var shouldUseOriginImage: Bool = false
    /// 是否显示原图按钮，默认NO
    open var showsOriginImageCheckboxButton: Bool = false {
        didSet {
            originImageCheckboxButton.isHidden = !showsOriginImageCheckboxButton
        }
    }
    /// 是否显示编辑按钮，默认YES
    open var showsEditButton: Bool = true {
        didSet {
            editButton.isHidden = !showsEditButton
        }
    }
    
    /// 是否显示编辑collectionView，默认YES，仅多选生效
    open var showsEditCollectionView: Bool = true
    /// 编辑collectionView总高度，默认80
    open var editCollectionViewHeight: CGFloat = 80
    /// 编辑collectionCell大小，默认(60, 60)
    open var editCollectionCellSize: CGSize = CGSizeMake(60, 60)
    
    /// 是否显示默认loading，优先级低于delegate，默认YES
    open var showsDefaultLoading: Bool = true
    
    /// 由于组件需要通过本地图片的 Asset 对象读取图片的详细信息，因此这里的需要传入的是包含一个或多个 Asset 对象的数组
    open var imagesAssetArray: [Asset] = []
    open var selectedImageAssetArray: [Asset] = []
    
    open var downloadStatus: AssetDownloadStatus = .succeed {
        didSet {
            if !singleCheckMode {
                checkboxButton.isHidden = false
            }
        }
    }
    
    /// 最多可以选择的图片数，默认为9
    open var maximumSelectImageCount: UInt = 9
    /// 最少需要选择的图片数，默认为 0
    open var minimumSelectImageCount: UInt = 0
    
    open lazy var topToolbarView: UIView = {
        let result = UIView()
        result.backgroundColor = toolbarBackgroundColor
        result.tintColor = toolbarTintColor
        result.addSubview(backButton)
        result.addSubview(checkboxButton)
        return result
    }()
    
    open lazy var backButton: UIButton = {
        let result = UIButton()
        result.setImage(FrameworkBundle.navBackImage, for: .normal)
        result.sizeToFit()
        result.addTarget(self, action: #selector(handleCancelButtonClick(_:)), for: .touchUpInside)
        result.fw_touchInsets = UIEdgeInsets(top: 30, left: 20, bottom: 50, right: 80)
        result.fw_disabledAlpha = UIButton.fw_disabledAlpha
        result.fw_highlightedAlpha = UIButton.fw_highlightedAlpha
        return result
    }()
    
    open lazy var checkboxButton: UIButton = {
        let result = UIButton()
        result.setImage(checkboxImage, for: .normal)
        result.setImage(checkboxCheckedImage, for: .selected)
        result.setImage(checkboxCheckedImage, for: .highlighted)
        result.sizeToFit()
        result.addTarget(self, action: #selector(handleCheckButtonClick(_:)), for: .touchUpInside)
        result.fw_touchInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        result.fw_disabledAlpha = UIButton.fw_disabledAlpha
        result.fw_highlightedAlpha = UIButton.fw_highlightedAlpha
        return result
    }()
    
    open lazy var bottomToolbarView: UIView = {
        let result = UIView()
        result.backgroundColor = toolbarBackgroundColor
        result.tintColor = toolbarTintColor
        result.addSubview(editButton)
        result.addSubview(sendButton)
        result.addSubview(originImageCheckboxButton)
        return result
    }()
    
    open lazy var sendButton: UIButton = {
        let result = UIButton()
        result.fw_touchInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        result.setTitle(FrameworkBundle.doneButton, for: .normal)
        result.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        result.sizeToFit()
        result.fw_disabledAlpha = UIButton.fw_disabledAlpha
        result.fw_highlightedAlpha = UIButton.fw_highlightedAlpha
        result.addTarget(self, action: #selector(handleSendButtonClick(_:)), for: .touchUpInside)
        return result
    }()
    
    open lazy var editButton: UIButton = {
        let result = UIButton()
        result.isHidden = !showsEditButton
        result.fw_touchInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        result.setTitle(FrameworkBundle.editButton, for: .normal)
        result.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        result.sizeToFit()
        result.fw_disabledAlpha = UIButton.fw_disabledAlpha
        result.fw_highlightedAlpha = UIButton.fw_highlightedAlpha
        result.addTarget(self, action: #selector(handleEditButtonClick(_:)), for: .touchUpInside)
        return result
    }()
    
    open lazy var originImageCheckboxButton: UIButton = {
        let result = UIButton()
        result.isHidden = !showsOriginImageCheckboxButton
        result.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        result.setImage(originImageCheckboxImage, for: .normal)
        result.setImage(originImageCheckboxCheckedImage, for: .selected)
        result.setImage(originImageCheckboxCheckedImage, for: .highlighted)
        result.setTitle(FrameworkBundle.originalButton, for: .normal)
        result.imageEdgeInsets = UIEdgeInsets(top: 0, left: -5, bottom: 0, right: 5)
        result.contentEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 0)
        result.sizeToFit()
        result.fw_touchInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        result.fw_disabledAlpha = UIButton.fw_disabledAlpha
        result.fw_highlightedAlpha = UIButton.fw_highlightedAlpha
        result.addTarget(self, action: #selector(handleOriginImageCheckboxButtonClick(_:)), for: .touchUpInside)
        return result
    }()
    
    open lazy var editCollectionViewLayout: UICollectionViewFlowLayout = {
        let result = UICollectionViewFlowLayout()
        result.scrollDirection = .horizontal
        result.sectionInset = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        result.minimumLineSpacing = result.sectionInset.bottom
        result.minimumInteritemSpacing = result.sectionInset.left
        return result
    }()
    
    open lazy var editCollectionView: UICollectionView = {
        let result = UICollectionView(frame: isViewLoaded ? view.bounds : .zero, collectionViewLayout: editCollectionViewLayout)
        result.backgroundColor = toolbarBackgroundColor
        result.isHidden = true
        result.delegate = self
        result.dataSource = self
        result.showsHorizontalScrollIndicator = false
        result.showsVerticalScrollIndicator = false
        result.alwaysBounceHorizontal = true
        result.register(ImagePickerPreviewCollectionCell.self, forCellWithReuseIdentifier: "cell")
        result.contentInsetAdjustmentBehavior = .never
        return result
    }()
    
    weak var imagePickerController: ImagePickerController?
    private var editCheckedIndex: Int?
    private var shouldResetPreviewView = false
    private var singleCheckMode = false
    private var previewMode = false
    private var editImageAssetArray: [Asset] {
        if previewMode {
            return imagesAssetArray
        } else {
            return selectedImageAssetArray
        }
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        didInitialize()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        didInitialize()
    }
    
    private func didInitialize() {
        extendedLayoutIncludesOpaqueBars = true
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePreviewView.delegate = self
        view.addSubview(topToolbarView)
        view.addSubview(bottomToolbarView)
        view.addSubview(editCollectionView)
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navigationController = navigationController,
           navigationController.isNavigationBarHidden != true {
            navigationController.setNavigationBarHidden(true, animated: animated)
        }
        
        if !singleCheckMode {
            let imageAsset = imagesAssetArray[imagePreviewView.currentImageIndex]
            checkboxButton.isSelected = selectedImageAssetArray.contains(imageAsset)
        }
        updateOriginImageCheckboxButton(index: imagePreviewView.currentImageIndex)
        updateImageCountAndCollectionView(false)
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        topToolbarView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: UIScreen.fw.topBarHeight)
        let topToolbarContentHeight = UIScreen.fw.navigationBarHeight
        let topToolbarPaddingTop = topToolbarView.bounds.height - topToolbarContentHeight
        var backButtonFrame = backButton.frame
        backButtonFrame.origin = CGPoint(x: toolbarPaddingHorizontal + view.safeAreaInsets.left, y: topToolbarPaddingTop + (topToolbarContentHeight - backButton.frame.height) / 2.0)
        backButton.frame = backButtonFrame
        if !checkboxButton.isHidden {
            var checkboxButtonFrame = checkboxButton.frame
            checkboxButtonFrame.origin = CGPoint(x: topToolbarView.frame.width - toolbarPaddingHorizontal - view.safeAreaInsets.right - checkboxButton.frame.width, y: topToolbarPaddingTop + (topToolbarContentHeight - checkboxButton.frame.height) / 2.0)
            checkboxButton.frame = checkboxButtonFrame
        }
        
        let bottomToolbarHeight = self.bottomToolbarHeight
        let bottomToolbarContentHeight = bottomToolbarHeight - view.safeAreaInsets.bottom
        bottomToolbarView.frame = CGRect(x: 0, y: view.bounds.height - bottomToolbarHeight, width: view.bounds.width, height: bottomToolbarHeight)
        updateSendButtonLayout()
        
        var editButtonFrame = editButton.frame
        editButtonFrame.origin = CGPoint(x: toolbarPaddingHorizontal + view.safeAreaInsets.left, y: (bottomToolbarContentHeight - editButton.frame.height) / 2.0)
        editButton.frame = editButtonFrame
        if showsEditButton {
            var originImageCheckboxButtonFrame = originImageCheckboxButton.frame
            originImageCheckboxButtonFrame.origin = CGPoint(x: (bottomToolbarView.frame.width - originImageCheckboxButton.frame.width) / 2.0, y: (bottomToolbarContentHeight - originImageCheckboxButton.frame.height) / 2.0)
            originImageCheckboxButton.frame = originImageCheckboxButtonFrame
        } else {
            var originImageCheckboxButtonFrame = originImageCheckboxButton.frame
            originImageCheckboxButtonFrame.origin = CGPoint(x: toolbarPaddingHorizontal + view.safeAreaInsets.left, y: (bottomToolbarContentHeight - originImageCheckboxButton.frame.height) / 2.0)
            originImageCheckboxButton.frame = originImageCheckboxButtonFrame
        }
        
        editCollectionView.frame = CGRect(x: 0, y: bottomToolbarView.frame.minY - editCollectionViewHeight, width: view.bounds.width, height: editCollectionViewHeight)
        let contentInset = UIEdgeInsets(top: 0, left: editCollectionView.safeAreaInsets.left, bottom: 0, right: editCollectionView.safeAreaInsets.right)
        if editCollectionView.contentInset != contentInset {
            editCollectionView.contentInset = contentInset
        }
    }
    
    open override var prefersStatusBarHidden: Bool {
        return true
    }
    
    /// 更新数据并刷新 UI，手工调用
    /// - Parameters:
    ///   - imageAssetArray: 包含所有需要展示的图片的数组
    ///   - selectedImageAssetArray: 包含所有需要展示的图片中已经被选中的图片的数组
    ///   - currentImageIndex: 当前展示的图片在 imageAssetArray 的索引
    ///   - singleCheckMode: 是否为单选模式，如果是单选模式，则不显示 checkbox
    ///   - previewMode: 是否是预览模式，如果是预览模式，图片取消选中时editCollectionView会置灰而不是隐藏
    open func updateImagePickerPreviewView(
        imageAssetArray: [Asset],
        selectedImageAssetArray: [Asset],
        currentImageIndex: Int,
        singleCheckMode: Bool,
        previewMode: Bool
    ) {
        self.imagesAssetArray = imageAssetArray
        self.selectedImageAssetArray = selectedImageAssetArray
        imagePreviewView.currentImageIndex = currentImageIndex
        shouldResetPreviewView = true
        self.singleCheckMode = singleCheckMode
        self.previewMode = previewMode
        if singleCheckMode {
            checkboxButton.isHidden = true
        }
    }
    
    // MARK: - UICollectionView
    open func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return editImageAssetArray.count
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return editCollectionCellSize
    }
    
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let imageAsset = editImageAssetArray[indexPath.item]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ImagePickerPreviewCollectionCell
        let referenceSize = CGSize(width: editCollectionCellSize.width - cell.imageViewInsets.left - cell.imageViewInsets.right, height: editCollectionCellSize.height - cell.imageViewInsets.top - cell.imageViewInsets.bottom)
        cell.render(asset: imageAsset, referenceSize: referenceSize)
        cell.checked = indexPath.item == editCheckedIndex
        cell.disabled = !selectedImageAssetArray.contains(imageAsset)
        
        if delegate?.imagePickerPreviewController?(self, customCell: cell, at: indexPath) != nil {
        } else {
            customCellBlock?(cell, indexPath)
        }
        return cell
    }
    
    open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let imageAsset = editImageAssetArray[indexPath.item]
        let imageIndex = imagesAssetArray.firstIndex(of: imageAsset)
        if let imageIndex = imageIndex, imagePreviewView.currentImageIndex != imageIndex {
            imagePreviewView.currentImageIndex = imageIndex
            updateOriginImageCheckboxButton(index: imageIndex)
        }
        
        updateCollectionViewCheckedIndex(indexPath.item)
    }
    
    // MARK: - ImagePreviewViewDelegate
    open func numberOfImages(in imagePreviewView: ImagePreviewView) -> Int {
        return imagesAssetArray.count
    }
    
    open func imagePreviewView(_ imagePreviewView: ImagePreviewView, assetTypeAt index: Int) -> ImagePreviewMediaType {
        let imageAsset = imagesAssetArray[index]
        if imageAsset.assetType == .image {
            if imageAsset.assetSubType == .livePhoto, let pickerController = imagePickerController {
                let checkLivePhoto = pickerController.filterType.contains(.livePhoto) || pickerController.filterType.rawValue < 1
                if checkLivePhoto { return .livePhoto }
            }
            return .image
        } else if imageAsset.assetType == .video {
            return .video
        } else {
            return .others
        }
    }
    
    open func imagePreviewView(_ imagePreviewView: ImagePreviewView, shouldResetZoomImageView zoomImageView: ZoomImageView, at index: Int) -> Bool {
        if shouldResetPreviewView {
            // 刷新数据源时需重置zoomImageView，清空当前显示内容
            shouldResetPreviewView = false
            return true
        } else {
            // 为了防止切换图片时产生闪烁，快速切换时只重置videoPlayerItem，加载失败时需清空显示
            zoomImageView.videoPlayerItem = nil
            return false
        }
    }
    
    open func imagePreviewView(_ imagePreviewView: ImagePreviewView, renderZoomImageView zoomImageView: ZoomImageView, at index: Int) {
        requestImage(for: zoomImageView, at: index)
        
        var insets = zoomImageView.videoToolbarMargins
        insets.bottom = zoomImageView.videoToolbarMargins.bottom + bottomToolbarView.frame.height - imagePreviewView.safeAreaInsets.bottom
        zoomImageView.videoToolbarMargins = insets
    }
    
    open func imagePreviewView(_ imagePreviewView: ImagePreviewView, willScrollHalfTo index: Int) {
        let imageAsset = imagesAssetArray[index]
        if !singleCheckMode {
            checkboxButton.isSelected = selectedImageAssetArray.contains(imageAsset)
        }
        
        updateOriginImageCheckboxButton(index: index)
        let editIndex = editImageAssetArray.firstIndex(of: imageAsset)
        updateCollectionViewCheckedIndex(editIndex)
    }
    
    private func requestImage(for zoomImageView: ZoomImageView, at index: Int) {
        // 如果是走 PhotoKit 的逻辑，那么这个 block 会被多次调用，并且第一次调用时返回的图片是一张小图，
        // 拉取图片的过程中可能会多次返回结果，且图片尺寸越来越大，因此这里 contentMode为ScaleAspectFit 以防止图片大小跳动
        let imageAsset = imagesAssetArray[index]
        if imageAsset.editedImage != nil {
            zoomImageView.image = imageAsset.editedImage
            return
        }
        
        // 获取资源图片的预览图，这是一张适合当前设备屏幕大小的图片，最终展示时把图片交给组件控制最终展示出来的大小。
        // 系统相册本质上也是这么处理的，因此无论是系统相册，还是这个系列组件，由始至终都没有显示照片原图，
        // 这也是系统相册能加载这么快的原因。
        // 另外这里采用异步请求获取图片，避免获取图片时 UI 卡顿
        let progressHandler: PHAssetImageProgressHandler = { [weak self] progress, error, _, _ in
            imageAsset.downloadProgress = progress
            DispatchQueue.main.async {
                if self?.downloadStatus != .downloading {
                    self?.downloadStatus = .downloading
                    zoomImageView.progress = 0
                }
                // 拉取资源的初期，会有一段时间没有进度，猜测是发出网络请求以及与 iCloud 建立连接的耗时，这时预先给个 0.02 的进度值，看上去好看些
                let targetProgress = max(0.02, progress)
                if targetProgress < zoomImageView.progress {
                    zoomImageView.progress = targetProgress
                } else {
                    zoomImageView.progress = max(0.02, progress)
                }
                if error != nil {
                    self?.downloadStatus = .failed
                    zoomImageView.progress = 0
                }
            }
        }
        
        if imageAsset.assetType == .video {
            zoomImageView.tag = -1
            imageAsset.requestID = imageAsset.requestPlayerItem(completion: { playerItem, info in
                // 这里可能因为 imageView 复用，导致前面的请求得到的结果显示到别的 imageView 上，
                // 因此判断如果是新请求（无复用问题）或者是当前的请求才把获得的图片结果展示出来
                DispatchQueue.main.async {
                    let isCurrentRequest = (zoomImageView.tag == -1 && imageAsset.requestID == 0) || zoomImageView.tag == imageAsset.requestID
                    let loadICloudImageFault = playerItem == nil || info?[PHImageErrorKey] != nil
                    if isCurrentRequest && !loadICloudImageFault {
                        zoomImageView.videoPlayerItem = playerItem
                    } else if isCurrentRequest {
                        zoomImageView.image = nil
                        zoomImageView.livePhoto = nil
                    }
                }
            }, progressHandler: progressHandler)
            zoomImageView.tag = imageAsset.requestID
        } else {
            if imageAsset.assetType != .image { return }
            
            var isLivePhoto = false
            var checkLivePhoto = false
            if let pickerController = imagePickerController {
                checkLivePhoto = pickerController.filterType.contains(.livePhoto) || pickerController.filterType.rawValue < 1
            }
            if imageAsset.assetSubType == .livePhoto && checkLivePhoto {
                isLivePhoto = true
                zoomImageView.tag = -1
                imageAsset.requestID = imageAsset.requestLivePhoto(completion: { [weak self] livePhoto, info, finished in
                    // 这里可能因为 imageView 复用，导致前面的请求得到的结果显示到别的 imageView 上，
                    // 因此判断如果是新请求（无复用问题）或者是当前的请求才把获得的图片结果展示出来
                    DispatchQueue.main.async {
                        let isCurrentRequest = (zoomImageView.tag == -1 && imageAsset.requestID == 0) || zoomImageView.tag == imageAsset.requestID
                        let loadICloudImageFault = livePhoto == nil || info?[PHImageErrorKey] != nil
                        if isCurrentRequest && !loadICloudImageFault {
                            // 如果是走 PhotoKit 的逻辑，那么这个 block 会被多次调用，并且第一次调用时返回的图片是一张小图，
                            // 这时需要把图片放大到跟屏幕一样大，避免后面加载大图后图片的显示会有跳动
                            zoomImageView.livePhoto = livePhoto
                        } else if isCurrentRequest {
                            zoomImageView.image = nil
                            zoomImageView.livePhoto = nil
                        }
                        if finished && livePhoto != nil {
                            imageAsset.updateDownloadStatus(downloadResult: true)
                            self?.downloadStatus = .succeed
                            zoomImageView.progress = 1
                        } else if finished {
                            imageAsset.updateDownloadStatus(downloadResult: false)
                            self?.downloadStatus = .failed
                            zoomImageView.progress = 0
                        }
                    }
                }, progressHandler: progressHandler)
                zoomImageView.tag = imageAsset.requestID
            }
            
            if isLivePhoto {
            } else if imageAsset.assetSubType == .gif {
                imageAsset.requestImageData { imageData, info, isGIF, isHEIC in
                    DispatchQueue.global(qos: .default).async {
                        let resultImage = UIImage.fw_image(data: imageData, scale: 1)
                        DispatchQueue.main.async {
                            if resultImage != nil {
                                zoomImageView.image = resultImage
                            } else {
                                zoomImageView.image = nil
                                zoomImageView.livePhoto = nil
                            }
                        }
                    }
                }
            } else {
                zoomImageView.tag = -1
                imageAsset.requestID = imageAsset.requestOriginImage(completion: { [weak self] result, info, finished in
                    // 这里可能因为 imageView 复用，导致前面的请求得到的结果显示到别的 imageView 上，
                    // 因此判断如果是新请求（无复用问题）或者是当前的请求才把获得的图片结果展示出来
                    DispatchQueue.main.async {
                        let isCurrentRequest = (zoomImageView.tag == -1 && imageAsset.requestID == 0) || zoomImageView.tag == imageAsset.requestID
                        let loadICloudImageFault = result == nil || info?[PHImageErrorKey] != nil
                        if isCurrentRequest && !loadICloudImageFault {
                            zoomImageView.image = result
                        } else if isCurrentRequest {
                            zoomImageView.image = nil
                            zoomImageView.livePhoto = nil
                        }
                        if finished && result != nil {
                            imageAsset.updateDownloadStatus(downloadResult: true)
                            self?.downloadStatus = .succeed
                            zoomImageView.progress = 1
                        } else if finished {
                            imageAsset.updateDownloadStatus(downloadResult: false)
                            self?.downloadStatus = .failed
                            zoomImageView.progress = 0
                        }
                    }
                }, progressHandler: progressHandler)
                zoomImageView.tag = imageAsset.requestID
            }
        }
    }
    
    open func singleTouch(in zoomImageView: ZoomImageView, location: CGPoint) {
        topToolbarView.isHidden = !topToolbarView.isHidden
        bottomToolbarView.isHidden = !bottomToolbarView.isHidden
        if !singleCheckMode && showsEditCollectionView {
            editCollectionView.isHidden = !editCollectionView.isHidden || editImageAssetArray.count < 1
        }
    }
    
    open func zoomImageView(_ zoomImageView: ZoomImageView, didHideVideoToolbar didHide: Bool) {
        topToolbarView.isHidden = didHide
        bottomToolbarView.isHidden = didHide
        if !singleCheckMode && showsEditCollectionView {
            editCollectionView.isHidden = didHide || editImageAssetArray.count < 1
        }
    }
    
    // MARK: - Private
    @objc private func handleCancelButtonClick(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
        delegate?.imagePickerPreviewControllerDidCancel?(self)
    }
    
    @objc private func handleCheckButtonClick(_ button: UIButton) {
        if button.isSelected {
            delegate?.imagePickerPreviewController?(self, willUncheckImageAt: imagePreviewView.currentImageIndex)
            
            button.isSelected = false
            let imageAsset = imagesAssetArray[imagePreviewView.currentImageIndex]
            selectedImageAssetArray.removeAll(where: { $0 == imageAsset })
            updateImageCountAndCollectionView(true)
            
            delegate?.imagePickerPreviewController?(self, didUncheckImageAt: imagePreviewView.currentImageIndex)
        } else {
            if selectedImageAssetArray.count >= maximumSelectImageCount {
                if delegate?.imagePickerPreviewControllerWillShowExceed?(self) != nil {
                } else {
                    fw_showAlert(title: nil, message: String(format: FrameworkBundle.pickerExceedTitle, "\(maximumSelectImageCount)"), cancel: FrameworkBundle.closeButton)
                }
                return
            }
            
            delegate?.imagePickerPreviewController?(self, willCheckImageAt: imagePreviewView.currentImageIndex)
            
            button.isSelected = true
            let imageAsset = imagesAssetArray[imagePreviewView.currentImageIndex]
            selectedImageAssetArray.append(imageAsset)
            updateImageCountAndCollectionView(true)
            
            delegate?.imagePickerPreviewController?(self, didCheckImageAt: imagePreviewView.currentImageIndex)
        }
    }
    
    @objc private func handleEditButtonClick(_ sender: UIButton) {
        if delegate?.imagePickerPreviewController?(self, willEditImageAt: imagePreviewView.currentImageIndex) != nil {
            return
        }
        
        let zoomImageView = imagePreviewView.currentZoomImageView
        let imageAsset = imagesAssetArray[imagePreviewView.currentImageIndex]
        imageAsset.requestOriginImage { [weak self] result, info, finished in
            DispatchQueue.main.async {
                if finished, let result = result {
                    imageAsset.updateDownloadStatus(downloadResult: true)
                    self?.downloadStatus = .succeed
                    zoomImageView?.progress = 1
                    
                    self?.beginEditImageAsset(imageAsset, image: result)
                } else if finished {
                    imageAsset.updateDownloadStatus(downloadResult: false)
                    self?.downloadStatus = .failed
                    zoomImageView?.progress = 0
                }
            }
        } progressHandler: { [weak self] progress, error, _, _ in
            imageAsset.downloadProgress = progress
            DispatchQueue.main.async {
                if self?.downloadStatus != .downloading {
                    self?.downloadStatus = .downloading
                    zoomImageView?.progress = 0
                }
                // 拉取资源的初期，会有一段时间没有进度，猜测是发出网络请求以及与 iCloud 建立连接的耗时，这时预先给个 0.02 的进度值，看上去好看些
                let targetProgress = max(0.02, progress)
                if targetProgress < (zoomImageView?.progress ?? 0) {
                    zoomImageView?.progress = targetProgress
                } else {
                    zoomImageView?.progress = max(0.02, progress)
                }
                if error != nil {
                    self?.downloadStatus = .failed
                    zoomImageView?.progress = 0
                }
            }
        }
    }
    
    @objc private func handleSendButtonClick(_ sender: UIButton) {
        sender.isUserInteractionEnabled = false
        if selectedImageAssetArray.count == 0 {
            // 如果没选中任何一张，则点击发送按钮直接发送当前这张大图
            let currentAsset = imagesAssetArray[imagePreviewView.currentImageIndex]
            selectedImageAssetArray.append(currentAsset)
        }
        
        if imagePickerController?.shouldRequestImage ?? false {
            if delegate?.imagePickerPreviewControllerWillStartLoading?(self) != nil {
            } else if showsDefaultLoading {
                fw_showLoading()
            }
            ImagePickerController.requestImagesAssetArray(selectedImageAssetArray, filterType: imagePickerController?.filterType ?? [], useOriginImage: shouldUseOriginImage, videoExportPreset: imagePickerController?.videoExportPreset, videoExportAVAsset: imagePickerController?.videoExportAVAsset ?? false) { [weak self] in
                guard let self = self else { return }
                if self.delegate?.imagePickerPreviewControllerDidFinishLoading?(self) != nil {
                } else if self.showsDefaultLoading {
                    self.fw_hideLoading()
                }
                
                self.dismiss(animated: true) { [weak self] in
                    guard let self = self else { return }
                    if self.delegate?.imagePickerPreviewController?(self, didFinishPickingImage: self.selectedImageAssetArray) != nil {
                    } else if let pickerController = self.imagePickerController {
                        if pickerController.imagePickerControllerDelegate?.imagePickerController?(pickerController, didFinishPickingImage: self.selectedImageAssetArray) != nil {
                        } else {
                            pickerController.didFinishPicking?(self.selectedImageAssetArray)
                        }
                    }
                    self.imagePickerController?.selectedImageAssetArray.removeAll()
                }
            }
        } else {
            dismiss(animated: true) { [weak self] in
                guard let self = self else { return }
                if self.delegate?.imagePickerPreviewController?(self, didFinishPickingImage: self.selectedImageAssetArray) != nil {
                } else if let pickerController = self.imagePickerController {
                    if pickerController.imagePickerControllerDelegate?.imagePickerController?(pickerController, didFinishPickingImage: self.selectedImageAssetArray) != nil {
                    } else {
                        pickerController.didFinishPicking?(self.selectedImageAssetArray)
                    }
                }
                self.imagePickerController?.selectedImageAssetArray.removeAll()
            }
        }
    }
    
    @objc private func handleOriginImageCheckboxButtonClick(_ button: UIButton) {
        if button.isSelected {
            button.isSelected = false
            button.setTitle(FrameworkBundle.originalButton, for: .normal)
            button.sizeToFit()
            bottomToolbarView.setNeedsLayout()
        } else {
            button.isSelected = true
            updateOriginImageCheckboxButton(index: imagePreviewView.currentImageIndex)
            if !checkboxButton.isSelected {
                checkboxButton.sendActions(for: .touchUpInside)
            }
        }
        shouldUseOriginImage = button.isSelected
    }
    
    private func updateOriginImageCheckboxButton(index: Int) {
        let asset = imagesAssetArray[index]
        if asset.assetType == .audio || asset.assetType == .video {
            originImageCheckboxButton.isHidden = true
            if showsEditButton {
                editButton.isHidden = true
            }
        } else {
            if showsOriginImageCheckboxButton {
                originImageCheckboxButton.isHidden = false
            }
            if showsEditButton {
                editButton.isHidden = false
            }
        }
    }
    
    private func beginEditImageAsset(_ imageAsset: Asset, image: UIImage) {
        let cropController: ImageCropController
        if let controller = delegate?.imageCropController?(for: self, image: image) {
            cropController = controller
        } else if let controller = cropControllerBlock?(image) {
            cropController = controller
        } else {
            cropController = ImageCropController(image: image)
        }
        if imageAsset.editedImage != nil {
            cropController.imageCropFrame = imageAsset.pickerCroppedRect
            cropController.angle = imageAsset.pickerCroppedAngle
        }
        cropController.onDidCropToImage = { [weak self] editedImage, cropRect, angle in
            imageAsset.editedImage = editedImage != image ? editedImage : nil
            imageAsset.pickerCroppedRect = cropRect
            imageAsset.pickerCroppedAngle = angle
            self?.presentedViewController?.dismiss(animated: false)
        }
        cropController.onDidFinishCancelled = { [weak self] _ in
            self?.presentedViewController?.dismiss(animated: false)
        }
        present(cropController, animated: false)
    }
    
    private func updateSendButtonLayout() {
        let bottomToolbarContentHeight = bottomToolbarHeight - view.safeAreaInsets.bottom
        sendButton.sizeToFit()
        var sendButtonFrame = sendButton.frame
        sendButtonFrame.origin = CGPoint(x: bottomToolbarView.frame.width - toolbarPaddingHorizontal - sendButton.frame.width - view.safeAreaInsets.right, y: (bottomToolbarContentHeight - sendButton.frame.height) / 2.0)
        sendButton.frame = sendButtonFrame
    }
    
    private func updateImageCountAndCollectionView(_ animated: Bool) {
        if !singleCheckMode {
            let selectedCount = selectedImageAssetArray.count
            if selectedCount > 0 {
                sendButton.isEnabled = selectedCount >= minimumSelectImageCount
                sendButton.setTitle("\(FrameworkBundle.doneButton)(\(selectedCount))", for: .normal)
            } else {
                sendButton.isEnabled = minimumSelectImageCount <= 1
                sendButton.setTitle(FrameworkBundle.doneButton, for: .normal)
            }
            delegate?.imagePickerPreviewController?(self, willChangeCheckedCount: selectedCount)
            updateSendButtonLayout()
        }
        
        if !singleCheckMode && showsEditCollectionView {
            let currentAsset = imagesAssetArray[imagePreviewView.currentImageIndex]
            editCheckedIndex = editImageAssetArray.firstIndex(of: currentAsset)
            editCollectionView.isHidden = editImageAssetArray.count < 1
            editCollectionView.reloadData()
            if let editCheckedIndex = editCheckedIndex {
                editCollectionView.performBatchUpdates {} completion: { [weak self] _ in
                    if (self?.editCollectionView.numberOfItems(inSection: 0) ?? 0) > editCheckedIndex {
                        self?.editCollectionView.scrollToItem(at: IndexPath(item: editCheckedIndex, section: 0), at: .centeredHorizontally, animated: true)
                    }
                }
            }
        } else {
            editCollectionView.isHidden = true
        }
    }
    
    private func updateCollectionViewCheckedIndex(_ index: Int?) {
        if let editCheckedIndex = editCheckedIndex {
            let cell = editCollectionView.cellForItem(at: IndexPath(item: editCheckedIndex, section: 0)) as? ImagePickerPreviewCollectionCell
            cell?.checked = false
        }
        
        editCheckedIndex = index
        if let editCheckedIndex = editCheckedIndex {
            let indexPath = IndexPath(item: editCheckedIndex, section: 0)
            let cell = editCollectionView.cellForItem(at: indexPath) as? ImagePickerPreviewCollectionCell
            cell?.checked = true
            if editCollectionView.numberOfItems(inSection: 0) > editCheckedIndex {
                editCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            }
        }
    }
    
}

/// 图片选择器预览集合Cell
open class ImagePickerPreviewCollectionCell: UICollectionViewCell {
    
    /// imageView内边距，默认zero占满
    open var imageViewInsets: UIEdgeInsets = .zero
    /// 选中边框颜色，默认白色
    open var checkedBorderColor: UIColor? = UIColor(red: 7.0 / 255.0, green: 193.0 / 255.0, blue: 96.0 / 255.0, alpha: 1.0) {
        didSet {
            coverView.layer.borderColor = checked ? checkedBorderColor?.cgColor : nil
        }
    }
    /// 选中边框宽度，默认3
    open var checkedBorderWidth: CGFloat = 3 {
        didSet {
            coverView.layer.borderWidth = checked ? checkedBorderWidth : 0
        }
    }
    /// 禁用时蒙层颜色
    open var disabledMaskColor: UIColor? = UIColor(red: 0, green: 0, blue: 0, alpha: 0.8) {
        didSet {
            coverView.backgroundColor = disabled ? disabledMaskColor : nil
        }
    }
    /// 当前是否选中
    open var checked: Bool = false {
        didSet {
            coverView.layer.borderWidth = checked ? checkedBorderWidth : 0
            coverView.layer.borderColor = checked ? checkedBorderColor?.cgColor : nil
        }
    }
    /// 当前是否禁用，默认NO
    open var disabled: Bool = false {
        didSet {
            coverView.backgroundColor = disabled ? disabledMaskColor : nil
        }
    }
    
    /// 是否显示videoDurationLabel，默认YES
    open var showsVideoDurationLabel: Bool = true {
        didSet {
            videoDurationLabel.isHidden = !showsVideoDurationLabel || !showsVideoIcon
        }
    }
    /// videoDurationLabel 的字号
    open var videoDurationLabelFont: UIFont? = UIFont.systemFont(ofSize: 12) {
        didSet {
            videoDurationLabel.font = videoDurationLabelFont
        }
    }
    /// videoDurationLabel 的字体颜色
    open var videoDurationLabelTextColor: UIColor? = UIColor.white {
        didSet {
            videoDurationLabel.textColor = videoDurationLabelTextColor
        }
    }
    /// 视频时长文字的间距，相对于 cell 右下角而言，也即如果 right 越大则越往左，bottom 越大则越往上，另外 top 会影响底部遮罩的高度
    open var videoDurationLabelMargins = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 7)
    
    /// 已编辑图标
    open var editedIconImage: UIImage? {
        didSet {
            updateIconImageView()
        }
    }
    /// 视频图标
    open var videoIconImage: UIImage? {
        didSet {
            updateIconImageView()
        }
    }
    /// 图标视图边距
    open var iconImageViewMargins = UIEdgeInsets(top: 5, left: 7, bottom: 5, right: 5)
    
    /// 当前这个 cell 正在展示的 Asset 的 identifier
    open var assetIdentifier: String?
    
    /// 缩略图视图
    open lazy var imageView: UIImageView = {
        let result = UIImageView()
        result.contentMode = .scaleAspectFill
        result.clipsToBounds = true
        return result
    }()
    
    /// 蒙层视图
    open lazy var coverView: UIView = {
        let result = UIView()
        return result
    }()
    
    /// 左下角图标视图，默认判断显示editedIconImage和videoIconImage
    open lazy var iconImageView: UIImageView = {
        let result = UIImageView()
        result.isHidden = true
        return result
    }()
    
    /// 视频时长标签
    open lazy var videoDurationLabel: UILabel = {
        let result = UILabel()
        result.font = videoDurationLabelFont
        result.textColor = videoDurationLabelTextColor
        return result
    }()
    
    private var showsEditedIcon = false
    private var showsVideoIcon = false
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        didInitialize()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        didInitialize()
    }
    
    private func didInitialize() {
        contentView.addSubview(imageView)
        contentView.addSubview(iconImageView)
        contentView.addSubview(coverView)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        imageView.frame = CGRect(x: imageViewInsets.left, y: imageViewInsets.top, width: contentView.bounds.width - imageViewInsets.left - imageViewInsets.right, height: contentView.bounds.height - imageViewInsets.top - imageViewInsets.bottom)
        coverView.frame = contentView.bounds
        
        if !videoDurationLabel.isHidden {
            videoDurationLabel.sizeToFit()
            var videoDurationLabelFrame = videoDurationLabel.frame
            videoDurationLabelFrame.origin = CGPoint(x: contentView.bounds.width - videoDurationLabelMargins.right - videoDurationLabel.frame.width, y: contentView.bounds.height - videoDurationLabelMargins.bottom - videoDurationLabel.frame.height)
            videoDurationLabel.frame = videoDurationLabelFrame
        }
        
        if !iconImageView.isHidden {
            iconImageView.sizeToFit()
            var iconImageViewFrame = iconImageView.frame
            iconImageViewFrame.origin = CGPoint(x: iconImageViewMargins.left, y: contentView.bounds.height - iconImageViewMargins.bottom - iconImageView.frame.height)
            iconImageView.frame = iconImageViewFrame
        }
    }
    
    /// 渲染Asset
    open func render(asset: Asset, referenceSize: CGSize) {
        assetIdentifier = asset.identifier
        if asset.editedImage != nil {
            imageView.image = asset.editedImage
        } else {
            asset.requestThumbnailImage(size: referenceSize) { [weak self] result, info, finished in
                if self?.assetIdentifier == asset.identifier {
                    self?.imageView.image = result
                }
            }
        }
        
        if asset.assetType == .video && showsVideoDurationLabel {
            if videoDurationLabel.superview == nil {
                contentView.insertSubview(videoDurationLabel, belowSubview: coverView)
                setNeedsLayout()
            }
            
            let min: UInt = UInt(floor(asset.duration / 60))
            let sec: UInt = UInt(floor(asset.duration - Double(min * 60)))
            videoDurationLabel.text = String(format: "%02ld:%02ld", min, sec)
            videoDurationLabel.isHidden = false
        } else {
            videoDurationLabel.isHidden = true
        }
        
        showsEditedIcon = asset.editedImage != nil
        showsVideoIcon = asset.assetType == .video
        updateIconImageView()
    }
    
    private func updateIconImageView() {
        var iconImage: UIImage?
        if showsEditedIcon && editedIconImage != nil {
            iconImage = editedIconImage
        } else if showsVideoIcon && videoIconImage != nil {
            iconImage = videoIconImage
        }
        iconImageView.image = iconImage
        iconImageView.isHidden = iconImage == nil
        setNeedsLayout()
    }
    
}

fileprivate extension Asset {
    
    var pickerCroppedRect: CGRect {
        get {
            let value = fw.property(forName: "pickerCroppedRect") as? NSValue
            return value?.cgRectValue ?? .zero
        }
        set {
            fw.setProperty(NSValue(cgRect: newValue), forName: "pickerCroppedRect")
        }
    }
    
    var pickerCroppedAngle: Int {
        get {
            return fw.propertyInt(forName: "pickerCroppedAngle")
        }
        set {
            fw.setPropertyInt(newValue, forName: "pickerCroppedAngle")
        }
    }
    
}

// MARK: - ImagePickerController
@objc public protocol ImagePickerControllerDelegate {
    
    /// 创建一个 ImagePickerPreviewViewController 用于预览图片
    @objc optional func imagePickerPreviewController(for imagePickerController: ImagePickerController) -> ImagePickerPreviewController
    
    /// 控制照片的排序，若不实现，默认为 AlbumSortTypePositive
    ///
    /// 注意返回值会决定第一次进来相片列表时列表默认的滚动位置，如果为 AlbumSortTypePositive，则列表默认滚动到底部，如果为 AlbumSortTypeReverse，则列表默认滚动到顶部。
    @objc optional func albumSortType(for imagePickerController: ImagePickerController) -> AlbumSortType
    
    /// 选择图片完毕后被调用（点击 sendButton 后被调用），如果previewController没有实现完成回调方法，也会走到这个方法
    /// - Parameters:
    ///   - imagePickerController: 对应的 ImagePickerController
    ///   - imagesAssetArray: 包含被选择的图片的 Asset 对象的数组。
    @objc optional func imagePickerController(_ imagePickerController: ImagePickerController, didFinishPickingImage imagesAssetArray: [Asset])
    
    /// 取消选择图片后被调用，如果albumController没有实现取消回调方法，也会走到这个方法
    @objc optional func imagePickerControllerDidCancel(_ imagePickerController: ImagePickerController)
    
    /// cell 被点击时调用（先调用这个接口，然后才去走预览大图的逻辑），注意这并非指选中 checkbox 事件
    /// - Parameters:
    ///   - imagePickerController: 对应的 ImagePickerController
    ///   - imageAsset: 被选中的图片的 Asset 对象
    ///   - imagePickerPreviewController: 选中图片后进行图片预览的 viewController
    @objc optional func imagePickerController(_ imagePickerController: ImagePickerController, didSelectImage imageAsset: Asset, afterPreviewControllerUpdate imagePickerPreviewController: ImagePickerPreviewController)
    
    /// 是否能够选中 checkbox
    @objc optional func imagePickerController(_ imagePickerController: ImagePickerController, shouldCheckImageAt index: Int) -> Bool
    
    /// 即将选中 checkbox 时调用
    @objc optional func imagePickerController(_ imagePickerController: ImagePickerController, willCheckImageAt index: Int)
    
    /// 选中了 checkbox 之后调用
    @objc optional func imagePickerController(_ imagePickerController: ImagePickerController, didCheckImageAt index: Int)
    
    /// 即将取消选中 checkbox 时调用
    @objc optional func imagePickerController(_ imagePickerController: ImagePickerController, willUncheckImageAt index: Int)
    
    /// 取消了 checkbox 选中之后调用
    @objc optional func imagePickerController(_ imagePickerController: ImagePickerController, didUncheckImageAt index: Int)
    
    /// 选中数量变化时调用，仅多选有效
    @objc optional func imagePickerController(_ imagePickerController: ImagePickerController, willChangeCheckedCount checkedCount: Int)
    
    /// 自定义图片九宫格cell展示，cellForRow自动调用
    @objc optional func imagePickerController(_ imagePickerController: ImagePickerController, customCell cell: ImagePickerCollectionCell, at indexPath: IndexPath)
    
    /// 标题视图被点击时调用，返回弹出的相册列表控制器
    @objc optional func albumController(for imagePickerController: ImagePickerController) -> ImageAlbumController
    
    /// 即将显示弹出相册列表控制器时调用
    @objc optional func imagePickerController(_ imagePickerController: ImagePickerController, willShowAlbumController albumController: ImageAlbumController)
    
    /// 即将隐藏弹出相册列表控制器时调用
    @objc optional func imagePickerController(_ imagePickerController: ImagePickerController, willHideAlbumController albumController: ImageAlbumController)
    
    /// 即将需要显示 Loading 时调用
    @objc optional func imagePickerControllerWillStartLoading(_ imagePickerController: ImagePickerController)
    
    /// 即将需要隐藏 Loading 时调用
    @objc optional func imagePickerControllerDidFinishLoading(_ imagePickerController: ImagePickerController)
    
    /// 图片未授权时调用，可自定义空界面等
    @objc optional func imagePickerControllerWillShowDenied(_ imagePickerController: ImagePickerController)
    
    /// 图片为空时调用，可自定义空界面等
    @objc optional func imagePickerControllerWillShowEmpty(_ imagePickerController: ImagePickerController)
    
    /// 已经选中数量超过最大选择数量时被调用，默认弹窗提示
    @objc optional func imagePickerControllerWillShowExceed(_ imagePickerController: ImagePickerController)
    
}

open class ImagePickerController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, ImagePickerPreviewControllerDelegate, ImagePickerTitleViewDelegate {
    
    open weak var imagePickerControllerDelegate: ImagePickerControllerDelegate?
    /// 自定义预览控制器句柄，优先级低于delegate
    open var previewControllerBlock: (() -> ImagePickerPreviewController)?
    /// 自定义相册控制器句柄，优先级低于delegate
    open var albumControllerBlock: (() -> ImageAlbumController)?
    /// 自定义cell展示句柄，cellForItem自动调用，优先级低于delegate
    open var customCellBlock: ((_ cell: ImagePickerCollectionCell, _ indexPath: IndexPath) -> Void)?
    
    /// 图片选取完成回调句柄，优先级低于delegate
    open var didFinishPicking: (([Asset]) -> Void)?
    /// 图片选取取消回调句柄，优先级低于delegate
    open var didCancelPicking: (() -> Void)?
    
    open var toolbarBackgroundColor: UIColor? = UIColor(red: 27.0 / 255.0, green: 27.0 / 255.0, blue: 27.0 / 255.0, alpha: 1.0) {
        didSet {
            navigationController?.navigationBar.fw.backgroundColor = toolbarBackgroundColor
        }
    }
    open var toolbarTintColor: UIColor? = .white {
        didSet {
            navigationController?.navigationBar.fw.foregroundColor = toolbarTintColor
        }
    }
    
    /// 标题视图accessoryImage，默认nil，contentType方式会自动设置
    open var titleAccessoryImage: UIImage?
    
    /// 图片的最小尺寸，布局时如果有剩余空间，会将空间分配给图片大小，所以最终显示出来的大小不一定等于minimumImageWidth。默认是75。
    /// collectionViewLayout 和 collectionView 可能有设置 sectionInsets 和 contentInsets，所以设置几行不可以简单的通过 screenWdith / columnCount 来获得
    open var minimumImageWidth: CGFloat = 75 {
        didSet {
            referenceImageSize()
            collectionView.collectionViewLayout.invalidateLayout()
        }
    }
    /// 图片显示列数，默认0使用minimumImageWidth自动计算，指定后固定列数
    open var imageColumnCount: Int = 0 {
        didSet {
            referenceImageSize()
            collectionView.collectionViewLayout.invalidateLayout()
        }
    }
    
    open var toolbarPaddingHorizontal: CGFloat = 16
    /// 自定义工具栏高度，默认同系统
    open var operationToolbarHeight: CGFloat {
        get {
            guard allowsMultipleSelection else { return 0 }
            return _operationToolbarHeight > 0 ? _operationToolbarHeight : UIScreen.fw.toolBarHeight
        }
        set {
            _operationToolbarHeight = newValue
        }
    }
    private var _operationToolbarHeight: CGFloat = 0
    
    open private(set) var imagesAssetArray: [Asset] = []
    open private(set) var assetsGroup: AssetGroup?
    
    /// 图片过滤类型，默认0不过滤，影响requestImage结果和previewController预览效果
    open var filterType: ImagePickerFilterType = []
    
    /// 自定义视频导出质量，默认nil时为AVAssetExportPresetMediumQuality
    open var videoExportPreset: String?
    
    /// 是否视频导出为AVAsset，默认false
    open var videoExportAVAsset = false
    
    /// 当前被选择的图片对应的 Asset 对象数组
    open internal(set) var selectedImageAssetArray: [Asset] = []
    
    /// 是否允许图片多选，默认为 YES。如果为 NO，则不显示 checkbox 和底部工具栏
    open var allowsMultipleSelection: Bool = true {
        didSet {
            if isViewLoaded {
                if allowsMultipleSelection {
                    view.addSubview(operationToolbarView)
                } else {
                    operationToolbarView.removeFromSuperview()
                }
            }
        }
    }
    
    /// 是否禁用预览时左右滚动，默认NO。如果为YES，单选时不能左右滚动切换图片
    open var previewScrollDisabled: Bool = false
    
    /// 最多可以选择的图片数，默认为9
    open var maximumSelectImageCount: UInt = 9
    
    /// 最少需要选择的图片数，默认为 0
    open var minimumSelectImageCount: UInt = 0
    
    /// 是否显示默认loading，优先级低于delegate，默认YES
    open var showsDefaultLoading: Bool = true
    
    /// 是否需要请求图片资源，默认NO，开启后会先requestImagesAssetArray再回调didFinishPicking
    open var shouldRequestImage: Bool = false
    
    /// 当前titleView，默认不可点击，contentType方式会自动切换点击状态
    open lazy var titleView: ImagePickerTitleView = {
        let result = ImagePickerTitleView()
        result.delegate = self
        return result
    }()
    
    open lazy var collectionView: UICollectionView = {
        let result = UICollectionView(frame: isViewLoaded ? view.bounds : .zero, collectionViewLayout: collectionViewLayout)
        result.dataSource = self
        result.delegate = self
        result.showsHorizontalScrollIndicator = false
        result.showsVerticalScrollIndicator = false
        result.alwaysBounceVertical = true
        result.contentInsetAdjustmentBehavior = .never
        result.backgroundColor = .black
        result.register(ImagePickerCollectionCell.self, forCellWithReuseIdentifier: kVideoCellIdentifier)
        result.register(ImagePickerCollectionCell.self, forCellWithReuseIdentifier: kImageOrUnknownCellIdentifier)
        return result
    }()
    
    open lazy var collectionViewLayout: UICollectionViewFlowLayout = {
        let result = UICollectionViewFlowLayout()
        let inset = 2.0 / UIScreen.main.scale
        result.sectionInset = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
        result.minimumLineSpacing = result.sectionInset.bottom
        result.minimumInteritemSpacing = result.sectionInset.left
        return result
    }()
    
    open lazy var operationToolbarView: UIView = {
        let result = UIView()
        result.backgroundColor = toolbarBackgroundColor
        result.addSubview(sendButton)
        result.addSubview(previewButton)
        return result
    }()
    
    open lazy var sendButton: UIButton = {
        let result = UIButton()
        result.isEnabled = false
        result.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        result.contentHorizontalAlignment = .right
        result.setTitleColor(toolbarTintColor, for: .normal)
        result.setTitle(FrameworkBundle.doneButton, for: .normal)
        result.fw_touchInsets = UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20)
        result.fw_disabledAlpha = UIButton.fw_disabledAlpha
        result.fw_highlightedAlpha = UIButton.fw_highlightedAlpha
        result.sizeToFit()
        result.addTarget(self, action: #selector(handleSendButtonClick(_:)), for: .touchUpInside)
        return result
    }()
    
    open lazy var previewButton: UIButton = {
        let result = UIButton()
        result.isEnabled = false
        result.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        result.setTitleColor(toolbarTintColor, for: .normal)
        result.setTitle(FrameworkBundle.previewButton, for: .normal)
        result.fw_touchInsets = UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20)
        result.fw_disabledAlpha = UIButton.fw_disabledAlpha
        result.fw_highlightedAlpha = UIButton.fw_highlightedAlpha
        result.sizeToFit()
        result.addTarget(self, action: #selector(handlePreviewButtonClick(_:)), for: .touchUpInside)
        return result
    }()
    
    private var imagePickerPreviewController: ImagePickerPreviewController?
    private weak var albumController: ImageAlbumController?
    private var isImagesAssetLoaded = false
    private var isImagesAssetLoading = false
    private var hasScrollToInitialPosition = false
    
    private let kVideoCellIdentifier = "video"
    private let kImageOrUnknownCellIdentifier = "imageorunknown"
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        didInitialize()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        didInitialize()
    }
    
    private func didInitialize() {
        extendedLayoutIncludesOpaqueBars = true
        navigationItem.titleView = titleView
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: FrameworkBundle.navCloseImage, style: .plain, target: self, action: #selector(handleCancelButtonClick(_:)))
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = collectionView.backgroundColor
        view.addSubview(collectionView)
        if allowsMultipleSelection {
            view.addSubview(operationToolbarView)
        }
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navigationController = navigationController {
            if navigationController.isNavigationBarHidden != false {
                navigationController.setNavigationBarHidden(false, animated: animated)
            }
            navigationController.navigationBar.fw.isTranslucent = false
            navigationController.navigationBar.fw.shadowColor = nil
            navigationController.navigationBar.fw.backgroundColor = toolbarBackgroundColor
            navigationController.navigationBar.fw.foregroundColor = toolbarTintColor
        }
        
        // 由于被选中的图片 selectedImageAssetArray 可以由外部改变，因此检查一下图片被选中的情况，并刷新 collectionView
        if allowsMultipleSelection {
            updateImageCountAndCheckLimited(true)
        } else {
            collectionView.reloadData()
        }
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        var operationToolbarViewHeight: CGFloat = 0
        if allowsMultipleSelection {
            operationToolbarViewHeight = operationToolbarHeight
            operationToolbarView.frame = CGRect(x: 0, y: view.bounds.height - operationToolbarViewHeight, width: view.bounds.width, height: operationToolbarViewHeight)
            var previewButtonFrame = previewButton.frame
            previewButtonFrame.origin = CGPoint(x: toolbarPaddingHorizontal + view.safeAreaInsets.left, y: (operationToolbarView.bounds.height - view.safeAreaInsets.bottom - previewButton.frame.height) / 2.0)
            previewButton.frame = previewButtonFrame
            updateSendButtonLayout()
            operationToolbarViewHeight = operationToolbarView.frame.height
        }
        
        if collectionView.frame.size != view.bounds.size {
            collectionView.frame = view.bounds
        }
        let contentInset = UIEdgeInsets(top: UIScreen.fw.topBarHeight, left: collectionView.safeAreaInsets.left, bottom: max(operationToolbarViewHeight, collectionView.safeAreaInsets.bottom), right: collectionView.safeAreaInsets.right)
        if collectionView.contentInset != contentInset {
            collectionView.contentInset = contentInset
            // 放在这里是因为有时候会先走完 refreshWithAssetsGroup 里的 completion 再走到这里，此时前者不会导致 scollToInitialPosition 的滚动，所以在这里再调用一次保证一定会滚
            scrollToInitialPositionIfNeeded()
        }
    }
    
    open override var prefersStatusBarHidden: Bool {
        return false
    }
    
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    /// 图片过滤类型转换为相册内容类型
    open class func albumContentType(filterType: ImagePickerFilterType) -> AlbumContentType {
        var contentType: AlbumContentType = filterType.rawValue < 1 ? .all : .onlyPhoto
        if filterType.contains(.video) {
            if filterType.contains(.image) || filterType.contains(.livePhoto) {
                contentType = .all
            } else {
                contentType = .onlyVideo
            }
        } else if filterType.contains(.livePhoto) && !filterType.contains(.image) {
            contentType = .onlyLivePhoto
        }
        return contentType
    }
    
    /// 检查并下载一组资源，如果资源仍未从 iCloud 中成功下载，则会发出请求从 iCloud 加载资源，下载完成后，主线程回调。
    /// 图片资源对象和结果信息保存在Asset.requestObject，自动根据过滤类型返回UIImage|PHLivePhoto|NSURL
    open class func requestImagesAssetArray(
        _ imagesAssetArray: [Asset],
        filterType: ImagePickerFilterType,
        useOriginImage: Bool,
        videoExportPreset: String? = nil,
        videoExportAVAsset: Bool = false,
        completion: (() -> Void)?
    ) {
        if imagesAssetArray.count < 1 {
            completion?()
            return
        }
        
        let totalCount = imagesAssetArray.count
        var finishCount: Int = 0
        let completionHandler: (Asset, Any?, [AnyHashable: Any]?) -> Void = { asset, object, info in
            DispatchQueue.main.async {
                asset.requestObject = object
                asset.requestInfo = info
                
                finishCount += 1
                if finishCount == totalCount {
                    completion?()
                }
            }
        }
        
        let checkLivePhoto = filterType.contains(.livePhoto) || filterType.rawValue < 1
        let checkVideo = filterType.contains(.video) || filterType.rawValue < 1
        for asset in imagesAssetArray {
            if checkVideo && asset.assetType == .video {
                if videoExportAVAsset {
                    asset.requestAVAsset { avAsset, audioMix, info in
                        completionHandler(asset, avAsset, info)
                    }
                } else {
                    var filePath = AssetManager.imagePickerPath
                    try? FileManager.default.createDirectory(atPath: filePath, withIntermediateDirectories: true)
                    filePath = (filePath as NSString).appendingPathComponent((asset.identifier + UUID().uuidString).fw.md5Encode)
                    filePath = (filePath as NSString).appendingPathExtension("mp4") ?? ""
                    let fileURL = URL(fileURLWithPath: filePath)
                    asset.requestVideoURL(outputURL: fileURL, exportPreset: videoExportPreset ?? AVAssetExportPresetMediumQuality) { videoURL, info in
                        completionHandler(asset, videoURL, info)
                    }
                }
            } else if asset.assetType == .image {
                if asset.editedImage != nil {
                    completionHandler(asset, asset.editedImage, nil)
                } else if checkLivePhoto && asset.assetSubType == .livePhoto {
                    asset.requestLivePhoto { livePhoto, info, finished in
                        if finished {
                            completionHandler(asset, livePhoto, info)
                        }
                    }
                } else if asset.assetSubType == .gif {
                    asset.requestImageData { imageData, info, isGIF, isHEIC in
                        DispatchQueue.global(qos: .default).async {
                            let resultImage = UIImage.fw_image(data: imageData, scale: 1)
                            completionHandler(asset, resultImage, info)
                        }
                    }
                } else if useOriginImage {
                    asset.requestOriginImage { result, info, finished in
                        if finished {
                            completionHandler(asset, result, info)
                        }
                    }
                } else {
                    asset.requestPreviewImage { result, info, finished in
                        if finished {
                            completionHandler(asset, result, info)
                        }
                    }
                }
            }
        }
    }
    
    /// 也可以直接传入 AssetGroup，然后读取其中的 Asset 并储存到 imagesAssetArray 中，传入后会赋值到 AssetGroup，并自动刷新 UI 展示
    open func refresh(assetsGroup: AssetGroup?) {
        self.assetsGroup = assetsGroup
        imagesAssetArray.removeAll()
        // 通过 AssetGroup 获取该相册所有的图片 Asset，并且储存到数组中
        var albumSortType: AlbumSortType = .positive
        // 从 delegate 中获取相册内容的排序方式，如果没有实现这个 delegate，则使用 AlbumSortType 的默认值，即最新的内容排在最后面
        if let sortType = imagePickerControllerDelegate?.albumSortType?(for: self) {
            albumSortType = sortType
        }
        // 遍历相册内的资源较为耗时，交给子线程去处理，因此这里需要显示 Loading
        if !isImagesAssetLoading {
            isImagesAssetLoading = true
            if imagePickerControllerDelegate?.imagePickerControllerWillStartLoading?(self) != nil {
            } else if showsDefaultLoading {
                fw_showLoading()
            }
        }
        if assetsGroup == nil {
            refreshCollectionView()
            return
        }
        
        DispatchQueue.global(qos: .default).async { [weak self] in
            assetsGroup?.enumerateAssets(options: albumSortType, using: { resultAsset in
                DispatchQueue.main.async {
                    if let resultAsset = resultAsset {
                        self?.isImagesAssetLoaded = false
                        self?.imagesAssetArray.append(resultAsset)
                    } else {
                        self?.refreshCollectionView()
                    }
                }
            })
        }
    }
    
    /// 根据filterType刷新，自动选取第一个符合条件的相册，自动初始化并使用albumController
    open func refresh(filterType: ImagePickerFilterType) {
        self.filterType = filterType
        if imagePickerControllerDelegate?.imagePickerControllerWillStartLoading?(self) != nil {
        } else if showsDefaultLoading {
            fw_showLoading()
        }
        isImagesAssetLoading = true
        initAlbumControllerIfNeeded()
    }
    
    // MARK: - UICollectionView
    open func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imagesAssetArray.count
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return referenceImageSize()
    }
    
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let imageAsset = imagesAssetArray[indexPath.item]
        let identifier = imageAsset.assetType == .video ? kVideoCellIdentifier : kImageOrUnknownCellIdentifier
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! ImagePickerCollectionCell
        cell.render(asset: imageAsset, referenceSize: referenceImageSize())
        
        cell.checkboxButton.tag = indexPath.item
        cell.checkboxButton.addTarget(self, action: #selector(handleCheckBoxButtonClick(_:)), for: .touchUpInside)
        cell.selectable = allowsMultipleSelection
        if cell.selectable {
            // 如果该图片的 Asset 被包含在已选择图片的数组中，则控制该图片被选中
            cell.checked = selectedImageAssetArray.contains(imageAsset)
            cell.checkedIndex = selectedImageAssetArray.firstIndex(of: imageAsset)
            cell.disabled = !cell.checked && selectedImageAssetArray.count >= maximumSelectImageCount
        }
        
        if imagePickerControllerDelegate?.imagePickerController?(self, customCell: cell, at: indexPath) != nil {
        } else {
            customCellBlock?(cell, indexPath)
        }
        return cell
    }
    
    open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let imageAsset = imagesAssetArray[indexPath.item]
        if !selectedImageAssetArray.contains(imageAsset) && selectedImageAssetArray.count >= maximumSelectImageCount {
            if imagePickerControllerDelegate?.imagePickerControllerWillShowExceed?(self) != nil {
            } else {
                fw_showAlert(title: nil, message: String(format: FrameworkBundle.pickerExceedTitle, "\(maximumSelectImageCount)"), cancel: FrameworkBundle.closeButton)
            }
            return
        }
        
        initPreviewViewControllerIfNeeded()
        guard let imagePickerPreviewController = imagePickerPreviewController else { return }
        imagePickerControllerDelegate?.imagePickerController?(self, didSelectImage: imageAsset, afterPreviewControllerUpdate: imagePickerPreviewController)
        
        if !allowsMultipleSelection {
            // 单选的情况下
            imagePickerPreviewController.updateImagePickerPreviewView(imageAssetArray: previewScrollDisabled ? [imageAsset] : imagesAssetArray, selectedImageAssetArray: selectedImageAssetArray, currentImageIndex: previewScrollDisabled ? 0 : indexPath.item, singleCheckMode: true, previewMode: false)
        } else {
            // cell 处于编辑状态，即图片允许多选
            imagePickerPreviewController.updateImagePickerPreviewView(imageAssetArray: imagesAssetArray, selectedImageAssetArray: selectedImageAssetArray, currentImageIndex: indexPath.item, singleCheckMode: false, previewMode: false)
        }
        navigationController?.pushViewController(imagePickerPreviewController, animated: true)
    }
    
    // MARK: - ImagePickerTitleViewDelegate
    open func didTouchTitleView(_ titleView: ImagePickerTitleView, isActive: Bool) {
        if isActive {
            showAlbumControllerAnimated(true)
        } else {
            hideAlbumControllerAnimated(true)
        }
    }
    
    open func didChangedActive(_ active: Bool, for titleView: ImagePickerTitleView) {}
    
    // MARK: - Private
    private func refreshCollectionView() {
        isImagesAssetLoaded = true
        if imagePickerControllerDelegate?.imagePickerControllerDidFinishLoading?(self) != nil {
        } else if showsDefaultLoading {
            fw_hideLoading()
        }
        isImagesAssetLoading = false
        if imagesAssetArray.count > 0 {
            collectionView.isHidden = true
            collectionView.reloadData()
            hasScrollToInitialPosition = false
            collectionView.performBatchUpdates { [weak self] in
                self?.scrollToInitialPositionIfNeeded()
            } completion: { [weak self] _ in
                self?.collectionView.isHidden = false
            }
        } else {
            collectionView.reloadData()
            if AssetManager.authorizationStatus == .notAuthorized {
                if imagePickerControllerDelegate?.imagePickerControllerWillShowDenied?(self) != nil {
                } else {
                    let appName = UIApplication.fw_appDisplayName
                    let tipText = String(format: FrameworkBundle.pickerDeniedTitle, appName)
                    fw_showEmptyView(text: tipText)
                }
            } else {
                if imagePickerControllerDelegate?.imagePickerControllerWillShowEmpty?(self) != nil {
                } else {
                    fw_showEmptyView(text: FrameworkBundle.pickerEmptyTitle)
                }
            }
        }
    }
    
    private func initPreviewViewControllerIfNeeded() {
        guard imagePickerPreviewController == nil else { return }
        
        if let controller = imagePickerControllerDelegate?.imagePickerPreviewController?(for: self) {
            imagePickerPreviewController = controller
        } else if previewControllerBlock != nil {
            imagePickerPreviewController = previewControllerBlock?()
        } else {
            imagePickerPreviewController = ImagePickerPreviewController()
        }
        imagePickerPreviewController?.imagePickerController = self
        imagePickerPreviewController?.maximumSelectImageCount = maximumSelectImageCount
        imagePickerPreviewController?.minimumSelectImageCount = minimumSelectImageCount
    }
    
    @discardableResult
    private func referenceImageSize() -> CGSize {
        let collectionViewWidth = collectionView.bounds.width
        let collectionViewContentSpacing = collectionViewWidth - (collectionView.contentInset.left + collectionView.contentInset.right) - (collectionViewLayout.sectionInset.left + collectionViewLayout.sectionInset.right)
        var referenceImageWidth = minimumImageWidth
        var columnCount = imageColumnCount
        if columnCount < 1 {
            columnCount = Int(floor(collectionViewContentSpacing / minimumImageWidth))
            let isSpacingEnoughWhenDisplayInMinImageSize = (minimumImageWidth + collectionViewLayout.minimumInteritemSpacing) * CGFloat(columnCount) - collectionViewLayout.minimumInteritemSpacing <= collectionViewContentSpacing
            if !isSpacingEnoughWhenDisplayInMinImageSize {
                // 算上图片之间的间隙后发现其实还是放不下啦，所以得把列数减少，然后放大图片以撑满剩余空间
                columnCount -= 1
            }
        }
        referenceImageWidth = floor((collectionViewContentSpacing - collectionViewLayout.minimumInteritemSpacing * CGFloat(columnCount - 1)) / CGFloat(columnCount))
        return CGSize(width: referenceImageWidth, height: referenceImageWidth)
    }
    
    private func scrollToInitialPositionIfNeeded() {
        if isImagesAssetLoaded && !hasScrollToInitialPosition {
            let itemsCount = collectionView.numberOfItems(inSection: 0)
            if imagePickerControllerDelegate?.albumSortType?(for: self) == .reverse {
                if itemsCount > 0 {
                    collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: false)
                }
            } else {
                if itemsCount > 0 {
                    collectionView.scrollToItem(at: IndexPath(item: itemsCount - 1, section: 0), at: .bottom, animated: false)
                }
            }
            hasScrollToInitialPosition = true
        }
    }
    
    private func showAlbumControllerAnimated(_ animated: Bool) {
        initAlbumControllerIfNeeded()
        guard let albumController = albumController else { return }
        imagePickerControllerDelegate?.imagePickerController?(self, willShowAlbumController: albumController)
        
        albumController.view.frame = view.bounds
        albumController.view.isHidden = false
        albumController.view.alpha = 0
        let toFrame = CGRect(x: 0, y: 0, width: view.bounds.size.width, height: albumController.tableViewHeight + UIScreen.fw.topBarHeight)
        var fromFrame = toFrame
        fromFrame.origin.y = -toFrame.size.height
        albumController.tableView.frame = fromFrame
        UIView.animate(withDuration: animated ? 0.25 : 0) {
            albumController.view.alpha = 1
            albumController.tableView.frame = toFrame
        }
    }
    
    private func hideAlbumControllerAnimated(_ animated: Bool) {
        guard let albumController = albumController else { return }
        imagePickerControllerDelegate?.imagePickerController?(self, willHideAlbumController: albumController)
        
        titleView.setActive(false, animated: animated)
        var toFrame = albumController.tableView.frame
        toFrame.origin.y = -toFrame.size.height
        UIView.animate(withDuration: animated ? 0.25 : 0) {
            albumController.view.alpha = 0
            albumController.tableView.frame = toFrame
        } completion: { _ in
            albumController.view.isHidden = true
            albumController.view.alpha = 1
        }
    }
    
    private func initAlbumControllerIfNeeded() {
        guard albumController == nil else { return }
        let albumController: ImageAlbumController
        if let controller = imagePickerControllerDelegate?.albumController?(for: self) {
            albumController = controller
        } else if let block = albumControllerBlock {
            albumController = block()
        } else {
            albumController = ImageAlbumController()
        }
        self.albumController = albumController
        
        albumController.imagePickerController = self
        albumController.contentType = ImagePickerController.albumContentType(filterType: filterType)
        albumController.albumsArrayLoaded = { [weak self] in
            if albumController.albumsArray.count > 0 {
                let assetsGroup = albumController.albumsArray.first
                albumController.assetsGroup = assetsGroup
                self?.titleView.isUserInteractionEnabled = true
                if self?.titleAccessoryImage != nil {
                    self?.titleView.accessoryImage = self?.titleAccessoryImage
                }
                self?.title = assetsGroup?.name
                self?.refresh(assetsGroup: assetsGroup)
            } else {
                self?.refresh(assetsGroup: nil)
            }
        }
        albumController.assetsGroupSelected = { [weak self] assetsGroup in
            self?.title = assetsGroup.name
            self?.refresh(assetsGroup: assetsGroup)
            self?.hideAlbumControllerAnimated(true)
        }
        
        addChild(albumController)
        albumController.view.isHidden = true
        view.addSubview(albumController.view)
        albumController.didMove(toParent: self)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleAlbumButtonClick(_:)))
        albumController.backgroundView.addGestureRecognizer(tapGesture)
        if albumController.backgroundView.backgroundColor == nil {
            albumController.backgroundView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        }
        if albumController.maximumTableViewHeight <= 0 {
            albumController.maximumTableViewHeight = albumController.albumTableViewCellHeight * ceil(UIScreen.main.bounds.height / albumController.albumTableViewCellHeight / 2.0) + albumController.additionalTableViewHeight
        }
    }
    
    private func requestImage(indexPath: IndexPath) {
        // 发出请求获取大图，如果图片在 iCloud，则会发出网络请求下载图片。这里同时保存请求 id，供取消请求使用
        let imageAsset = imagesAssetArray[indexPath.item]
        let cell = collectionView.cellForItem(at: indexPath) as? ImagePickerCollectionCell
        imageAsset.requestID = imageAsset.requestOriginImage(completion: { result, info, finished in
            if finished && result != nil {
                imageAsset.updateDownloadStatus(downloadResult: true)
                cell?.downloadStatus = .succeed
            } else if finished {
                imageAsset.updateDownloadStatus(downloadResult: false)
                cell?.downloadStatus = .failed
            }
        }, progressHandler: { [weak self] progress, error, _, _ in
            imageAsset.downloadProgress = progress
            DispatchQueue.main.async {
                let visibleIndexPaths = self?.collectionView.indexPathsForVisibleItems ?? []
                var itemVisible = false
                for visibleIndexPath in visibleIndexPaths {
                    if indexPath == visibleIndexPath {
                        itemVisible = true
                        break
                    }
                }
                
                if itemVisible {
                    if cell?.downloadStatus != .downloading {
                        cell?.downloadStatus = .downloading
                        // 预先设置预览界面的下载状态
                        self?.imagePickerPreviewController?.downloadStatus = .downloading
                    }
                    if error != nil {
                        cell?.downloadStatus = .failed
                    }
                }
            }
        })
    }
    
    private func updateSendButtonLayout() {
        guard allowsMultipleSelection else { return }
        
        sendButton.sizeToFit()
        sendButton.frame = CGRect(
            x: operationToolbarView.bounds.width - toolbarPaddingHorizontal - sendButton.frame.width - view.safeAreaInsets.right,
            y: (operationToolbarView.frame.height - view.safeAreaInsets.bottom - sendButton.frame.height) / 2.0,
            width: sendButton.frame.width,
            height: sendButton.frame.height
        )
    }
    
    private func updateImageCountAndCheckLimited(_ reloadData: Bool) {
        if allowsMultipleSelection {
            let selectedCount = selectedImageAssetArray.count
            if selectedCount > 0 {
                previewButton.isEnabled = selectedCount >= minimumSelectImageCount
                sendButton.isEnabled = selectedCount >= minimumSelectImageCount
                sendButton.setTitle("\(FrameworkBundle.doneButton)(\(selectedCount))", for: .normal)
            } else {
                previewButton.isEnabled = false
                sendButton.isEnabled = false
                sendButton.setTitle(FrameworkBundle.doneButton, for: .normal)
            }
            imagePickerControllerDelegate?.imagePickerController?(self, willChangeCheckedCount: selectedCount)
            updateSendButtonLayout()
        }
        
        if reloadData {
            collectionView.reloadData()
        } else {
            selectedImageAssetArray.forEach { imageAsset in
                guard let imageIndex = self.imagesAssetArray.firstIndex(of: imageAsset),
                      let cell = self.collectionView.cellForItem(at: IndexPath(item: imageIndex, section: 0)) as? ImagePickerCollectionCell else { return }
                
                if cell.selectable {
                    cell.checked = true
                    cell.checkedIndex = self.selectedImageAssetArray.firstIndex(of: imageAsset)
                    cell.disabled = !cell.checked && self.selectedImageAssetArray.count >= self.maximumSelectImageCount
                }
            }
        }
    }
    
    @objc private func handleSendButtonClick(_ sender: UIButton) {
        sender.isUserInteractionEnabled = false
        if shouldRequestImage {
            if imagePickerControllerDelegate?.imagePickerControllerWillStartLoading?(self) != nil {
            } else if showsDefaultLoading {
                fw_showLoading()
            }
            
            initPreviewViewControllerIfNeeded()
            ImagePickerController.requestImagesAssetArray(selectedImageAssetArray, filterType: filterType, useOriginImage: imagePickerPreviewController?.shouldUseOriginImage ?? false, videoExportPreset: videoExportPreset, videoExportAVAsset: videoExportAVAsset) { [weak self] in
                guard let self = self else { return }
                if self.imagePickerControllerDelegate?.imagePickerControllerDidFinishLoading?(self) != nil {
                } else if self.showsDefaultLoading {
                    self.fw_hideLoading()
                }
                
                self.dismiss(animated: true) { [weak self] in
                    guard let self = self else { return }
                    if self.imagePickerControllerDelegate?.imagePickerController?(self, didFinishPickingImage: self.selectedImageAssetArray) != nil {
                    } else {
                        self.didFinishPicking?(self.selectedImageAssetArray)
                    }
                    self.selectedImageAssetArray.removeAll()
                }
            }
        } else {
            dismiss(animated: true) { [weak self] in
                guard let self = self else { return }
                if self.imagePickerControllerDelegate?.imagePickerController?(self, didFinishPickingImage: self.selectedImageAssetArray) != nil {
                } else {
                    self.didFinishPicking?(self.selectedImageAssetArray)
                }
                self.selectedImageAssetArray.removeAll()
            }
        }
    }
    
    @objc private func handlePreviewButtonClick(_ sender: Any) {
        initPreviewViewControllerIfNeeded()
        // 手工更新图片预览界面
        imagePickerPreviewController?.updateImagePickerPreviewView(imageAssetArray: selectedImageAssetArray, selectedImageAssetArray: selectedImageAssetArray, currentImageIndex: 0, singleCheckMode: false, previewMode: true)
        if let previewController = imagePickerPreviewController {
            navigationController?.pushViewController(previewController, animated: true)
        }
    }
    
    @objc private func handleCheckBoxButtonClick(_ checkboxButton: UIButton) {
        let indexPath = IndexPath(item: checkboxButton.tag, section: 0)
        if let shouldCheck = imagePickerControllerDelegate?.imagePickerController?(self, shouldCheckImageAt: indexPath.item), !shouldCheck {
            return
        }
        
        let cell = collectionView.cellForItem(at: indexPath) as! ImagePickerCollectionCell
        let imageAsset = imagesAssetArray[indexPath.item]
        if cell.checked {
            imagePickerControllerDelegate?.imagePickerController?(self, willUncheckImageAt: indexPath.item)
            
            selectedImageAssetArray.removeAll(where: { $0 == imageAsset })
            // 根据选择图片数控制预览和发送按钮的 enable，以及修改已选中的图片数
            if selectedImageAssetArray.count >= maximumSelectImageCount - 1 {
                updateImageCountAndCheckLimited(true)
            } else {
                cell.checked = false
                cell.checkedIndex = nil
                cell.disabled = !cell.checked && selectedImageAssetArray.count >= maximumSelectImageCount
                updateImageCountAndCheckLimited(false)
            }
            
            imagePickerControllerDelegate?.imagePickerController?(self, didUncheckImageAt: indexPath.item)
        } else {
            if selectedImageAssetArray.count >= maximumSelectImageCount {
                if imagePickerControllerDelegate?.imagePickerControllerWillShowExceed?(self) != nil {
                } else {
                    fw_showAlert(title: nil, message: String(format: FrameworkBundle.pickerExceedTitle, "\(maximumSelectImageCount)"), cancel: FrameworkBundle.closeButton)
                }
                return
            }
            
            imagePickerControllerDelegate?.imagePickerController?(self, willCheckImageAt: indexPath.item)
            
            selectedImageAssetArray.append(imageAsset)
            // 根据选择图片数控制预览和发送按钮的 enable，以及修改已选中的图片数
            if selectedImageAssetArray.count >= maximumSelectImageCount {
                updateImageCountAndCheckLimited(true)
            } else {
                cell.checked = true
                cell.checkedIndex = selectedImageAssetArray.firstIndex(of: imageAsset)
                cell.disabled = !cell.checked && selectedImageAssetArray.count >= maximumSelectImageCount
                updateImageCountAndCheckLimited(false)
            }
            
            imagePickerControllerDelegate?.imagePickerController?(self, didCheckImageAt: indexPath.item)
            
            // 发出请求获取大图，如果图片在 iCloud，则会发出网络请求下载图片。这里同时保存请求 id，供取消请求使用
            requestImage(indexPath: indexPath)
        }
    }
    
    @objc private func handleAlbumButtonClick(_ sender: Any) {
        hideAlbumControllerAnimated(true)
    }
    
    @objc func handleCancelButtonClick(_ sender: Any) {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            if self.imagePickerControllerDelegate?.imagePickerControllerDidCancel?(self) != nil {
            } else {
                self.didCancelPicking?()
            }
            self.selectedImageAssetArray.removeAll()
        }
    }
    
}

/// 图片选择空间里的九宫格 cell，支持显示 checkbox、饼状进度条及重试按钮（iCloud 图片需要）
open class ImagePickerCollectionCell: UICollectionViewCell {
    
    /// checkbox 未被选中时显示的图片
    open var checkboxImage: UIImage? = FrameworkBundle.pickerCheckImage {
        didSet {
            checkboxButton.setImage(checkboxImage, for: .normal)
            checkboxButton.sizeToFit()
            setNeedsLayout()
        }
    }
    
    /// checkbox 被选中时显示的图片
    open var checkboxCheckedImage: UIImage? = FrameworkBundle.pickerCheckedImage {
        didSet {
            checkboxButton.setImage(checkboxCheckedImage, for: .selected)
            checkboxButton.setImage(checkboxCheckedImage, for: .highlighted)
            checkboxButton.sizeToFit()
            setNeedsLayout()
        }
    }
    
    /// checkbox 的 margin，定位从每个 cell（即每张图片）的最右边开始计算
    open var checkboxButtonMargins = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6) {
        didSet {
            setNeedsLayout()
        }
    }
    
    /// 禁用时蒙层颜色
    open var disabledMaskColor: UIColor? = UIColor(red: 0, green: 0, blue: 0, alpha: 0.8) {
        didSet {
            if selectable {
                updateMaskView()
            }
        }
    }
    
    /// 选中时蒙层颜色
    open var checkedMaskColor: UIColor? = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3) {
        didSet {
            if selectable {
                updateMaskView()
            }
        }
    }
    
    /// videoDurationLabel 的字号
    open var videoDurationLabelFont: UIFont? = UIFont.systemFont(ofSize: 12) {
        didSet {
            videoDurationLabel.font = videoDurationLabelFont
            videoDurationLabel.text = "测"
            videoDurationLabel.sizeToFit()
            videoDurationLabel.text = nil
            setNeedsLayout()
        }
    }
    
    /// videoDurationLabel 的字体颜色
    open var videoDurationLabelTextColor: UIColor? = .white {
        didSet {
            videoDurationLabel.textColor = videoDurationLabelTextColor
        }
    }
    
    /// 视频时长文字的间距，相对于 cell 右下角而言，也即如果 right 越大则越往左，bottom 越大则越往上，另外 top 会影响底部遮罩的高度
    open var videoDurationLabelMargins = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 7) {
        didSet {
            setNeedsLayout()
        }
    }
    
    open var editedIconImage: UIImage? {
        didSet {
            updateIconImageView()
        }
    }
    
    open var videoIconImage: UIImage? {
        didSet {
            updateIconImageView()
        }
    }
    
    open var iconImageViewMargins = UIEdgeInsets(top: 5, left: 7, bottom: 5, right: 5) {
        didSet {
            setNeedsLayout()
        }
    }
    
    /// checkedIndexLabel 的字号
    open var checkedIndexLabelFont: UIFont? = UIFont.boldSystemFont(ofSize: 13) {
        didSet {
            checkedIndexLabel.font = checkedIndexLabelFont
        }
    }
    
    /// checkedIndexLabel 的字体颜色
    open var checkedIndexLabelTextColor: UIColor? = .white {
        didSet {
            checkedIndexLabel.textColor = checkedIndexLabelTextColor
        }
    }
    
    /// checkedIndexLabel 的尺寸
    open var checkedIndexLabelSize: CGSize = CGSize(width: 20, height: 20) {
        didSet {
            setNeedsLayout()
        }
    }
    
    /// checkedIndexLabel 的 margin，定位从每个 cell（即每张图片）的最右边开始计算
    open var checkedIndexLabelMargins = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6) {
        didSet {
            setNeedsLayout()
        }
    }
    
    /// checkedIndexLabel 的背景色
    open var checkedIndexLabelBackgroundColor: UIColor? = UIColor(red: 7.0 / 255.0, green: 193.0 / 255.0, blue: 96.0 / 255.0, alpha: 1.0) {
        didSet {
            checkedIndexLabel.backgroundColor = checkedIndexLabelBackgroundColor
        }
    }
    
    /// 是否显示checkedIndexLabel，大小和checkboxButton保持一致
    open var showsCheckedIndexLabel: Bool = false {
        didSet {
            if showsCheckedIndexLabel {
                if checkedIndexLabel.superview == nil {
                    contentView.addSubview(checkedIndexLabel)
                    setNeedsLayout()
                }
            } else {
                checkedIndexLabel.isHidden = true
            }
        }
    }
    
    /// 是否显示videoDurationLabel，默认YES
    open var showsVideoDurationLabel: Bool = true {
        didSet {
            videoDurationLabel.isHidden = !showsVideoDurationLabel || !showsVideoIcon
        }
    }
    
    open var selectable: Bool = true {
        didSet {
            if downloadStatus == .succeed {
                checkboxButton.isHidden = !selectable
                updateCheckedIndexLabel()
            }
        }
    }
    
    open var checked: Bool = false {
        didSet {
            if selectable {
                checkboxButton.isSelected = checked
                updateMaskView()
                updateCheckedIndexLabel()
            }
        }
    }
    
    open var disabled: Bool = false {
        didSet {
            if selectable {
                if disabled {
                    contentView.bringSubviewToFront(coverView)
                } else {
                    contentView.insertSubview(coverView, aboveSubview: contentImageView)
                }
                updateMaskView()
            }
        }
    }
    
    open var checkedIndex: Int? {
        didSet {
            if selectable {
                if let checkedIndex = checkedIndex, checkedIndex >= 0 {
                    checkedIndexLabel.text = "\(checkedIndex + 1)"
                } else {
                    checkedIndexLabel.text = nil
                }
                updateCheckedIndexLabel()
            }
        }
    }
    
    /// Cell 中对应资源的下载状态，这个值的变动会相应地调整 UI 表现
    open var downloadStatus: AssetDownloadStatus = .succeed {
        didSet {
            if selectable {
                checkboxButton.isHidden = !selectable
                updateCheckedIndexLabel()
            }
        }
    }
    
    /// 当前这个 cell 正在展示的 Asset 的 identifier
    open var assetIdentifier: String?
    
    /// 蒙层视图
    open lazy var coverView: UIView = {
        let result = UIView()
        return result
    }()
    
    /// 左下角图标视图，默认判断显示editedIconImage和videoIconImage
    open lazy var iconImageView: UIImageView = {
        let result = UIImageView()
        result.isHidden = true
        return result
    }()
    
    open lazy var contentImageView: UIImageView = {
        let result = UIImageView()
        result.contentMode = .scaleAspectFill
        result.clipsToBounds = true
        return result
    }()
    
    open lazy var checkboxButton: UIButton = {
        let result = UIButton()
        result.fw_touchInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        result.setImage(checkboxImage, for: .normal)
        result.setImage(checkboxCheckedImage, for: .selected)
        result.setImage(checkboxCheckedImage, for: .highlighted)
        result.sizeToFit()
        result.isHidden = true
        return result
    }()
    
    open lazy var videoDurationLabel: UILabel = {
        let result = UILabel()
        result.font = videoDurationLabelFont
        result.textColor = videoDurationLabelTextColor
        result.text = "测"
        result.sizeToFit()
        result.text = nil
        result.isHidden = true
        return result
    }()
    
    open lazy var checkedIndexLabel: UILabel = {
        let result = UILabel()
        result.textAlignment = .center
        result.font = checkedIndexLabelFont
        result.textColor = checkedIndexLabelTextColor
        result.backgroundColor = checkedIndexLabelBackgroundColor
        result.isHidden = true
        result.clipsToBounds = true
        return result
    }()
    
    private var showsEditedIcon = false
    private var showsVideoIcon = false
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        didInitialize()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        didInitialize()
    }
    
    private func didInitialize() {
        contentView.addSubview(contentImageView)
        contentView.addSubview(coverView)
        contentView.addSubview(iconImageView)
        contentView.addSubview(checkboxButton)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        contentImageView.frame = contentView.bounds
        coverView.frame = contentImageView.frame
        
        if selectable {
            // 经测试checkboxButton图片视图未完全占满UIButton，导致无法对齐，修复之
            var checkboxButtonSize = checkboxButton.imageView?.bounds.size ?? .zero
            if checkboxButtonSize.equalTo(CGSize.zero) {
                checkboxButtonSize = checkboxButton.bounds.size
            }
            checkboxButton.frame = CGRect(x: contentView.bounds.width - checkboxButtonMargins.right - checkboxButtonSize.width, y: checkboxButtonMargins.top, width: checkboxButtonSize.width, height: checkboxButtonSize.height)
        }
        
        if checkedIndexLabel.superview != nil {
            checkedIndexLabel.layer.cornerRadius = checkedIndexLabelSize.width / 2.0
            checkedIndexLabel.frame = CGRect(x: contentView.bounds.width - checkedIndexLabelMargins.right - checkedIndexLabelSize.width, y: checkedIndexLabelMargins.top, width: checkedIndexLabelSize.width, height: checkedIndexLabelSize.height)
        }
        
        if !videoDurationLabel.isHidden {
            videoDurationLabel.sizeToFit()
            var videoDurationLabelFrame = videoDurationLabel.frame
            videoDurationLabelFrame.origin = CGPoint(x: contentView.bounds.width - videoDurationLabelMargins.right - videoDurationLabel.frame.width, y: contentView.bounds.height - videoDurationLabelMargins.bottom - videoDurationLabel.frame.height)
            videoDurationLabel.frame = videoDurationLabelFrame
        }
        
        if !iconImageView.isHidden {
            iconImageView.sizeToFit()
            var iconImageViewFrame = iconImageView.frame
            iconImageViewFrame.origin = CGPoint(x: iconImageViewMargins.left, y: contentView.bounds.height - iconImageViewMargins.bottom - iconImageView.frame.height)
            iconImageView.frame = iconImageViewFrame
        }
    }
    
    /// 渲染资源
    open func render(asset: Asset, referenceSize: CGSize) {
        assetIdentifier = asset.identifier
        if asset.editedImage != nil {
            contentImageView.image = asset.editedImage
        } else {
            asset.requestThumbnailImage(size: referenceSize) { [weak self] result, info, finished in
                if self?.assetIdentifier == asset.identifier {
                    self?.contentImageView.image = result
                }
            }
        }
        
        if showsCheckedIndexLabel {
            if checkedIndexLabel.superview == nil {
                contentView.addSubview(checkedIndexLabel)
                setNeedsLayout()
            }
        } else {
            checkedIndexLabel.isHidden = true
        }
        
        if asset.assetType == .video && showsVideoDurationLabel {
            if videoDurationLabel.superview == nil {
                contentView.addSubview(videoDurationLabel)
                setNeedsLayout()
            }
            
            let min: UInt = UInt(floor(asset.duration / 60))
            let sec: UInt = UInt(floor(asset.duration - Double(min * 60)))
            videoDurationLabel.text = String(format: "%02ld:%02ld", min, sec)
            videoDurationLabel.isHidden = false
        } else {
            videoDurationLabel.isHidden = true
        }
        
        showsEditedIcon = asset.editedImage != nil
        showsVideoIcon = asset.assetType == .video
        updateIconImageView()
    }
    
    private func updateCheckedIndexLabel() {
        if showsCheckedIndexLabel, selectable, checked, let checkedIndex = checkedIndex, checkedIndex >= 0 {
            checkedIndexLabel.isHidden = false
        } else {
            checkedIndexLabel.isHidden = true
        }
    }
    
    private func updateMaskView() {
        if checked {
            coverView.backgroundColor = checkedMaskColor
        } else if disabled {
            coverView.backgroundColor = disabledMaskColor
        } else {
            coverView.backgroundColor = nil
        }
    }
    
    private func updateIconImageView() {
        var iconImage: UIImage?
        if showsEditedIcon && editedIconImage != nil {
            iconImage = editedIconImage
        } else if showsVideoIcon && videoIconImage != nil {
            iconImage = videoIconImage
        }
        iconImageView.image = iconImage
        iconImageView.isHidden = iconImage == nil
        setNeedsLayout()
    }
    
}

// MARK: - ImagePickerTitleView
public protocol ImagePickerTitleViewDelegate: AnyObject {
    func didTouchTitleView(_ titleView: ImagePickerTitleView, isActive: Bool)
    func didChangedActive(_ active: Bool, for titleView: ImagePickerTitleView)
}

open class ImagePickerTitleView: UIControl, TitleViewProtocol {
    /// 事件代理
    open weak var delegate: ImagePickerTitleViewDelegate?
    
    /// 标题栏是否是激活状态，主要针对accessoryImage生效
    open var isActive: Bool {
        get { return _isActive }
        set { setActive(newValue, animated: false) }
    }
    private var _isActive: Bool = false
    
    /// 标题栏最大显示宽度，默认不限制
    open var maximumWidth: CGFloat = CGFloat.greatestFiniteMagnitude {
        didSet { refreshLayout() }
    }
    
    /// 标题文字
    open var title: String? {
        didSet {
            titleLabel.text = title
            refreshLayout()
        }
    }
    
    /// 是否适应tintColor变化，影响titleLabel，默认YES
    open var adjustsTintColor: Bool = true
    
    /// 水平布局下的标题字体，默认为 加粗17
    open var horizontalTitleFont: UIFont? = UIFont.boldSystemFont(ofSize: 17) {
        didSet {
            titleLabel.font = horizontalTitleFont
            refreshLayout()
        }
    }
    
    /// 标题的上下左右间距，标题不显示时不参与计算大小，默认为 UIEdgeInsets.zero
    open var titleEdgeInsets: UIEdgeInsets = .zero {
        didSet { refreshLayout() }
    }
    
    /// 自定义accessoryView，设置后accessoryImage无效，默认nil
    open var accessoryView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let accessoryView = accessoryView {
                accessoryImage = nil
                accessoryView.sizeToFit()
                contentView.addSubview(accessoryView)
            }
            refreshLayout()
        }
    }
    
    /// 自定义accessoryImage，accessoryView为空时才生效，默认nil
    open var accessoryImage: UIImage? {
        get {
            return _accessoryImage
        }
        set {
            let accessoryImage = accessoryView != nil ? nil : newValue
            _accessoryImage = accessoryImage
            
            if accessoryImage == nil {
                accessoryImageView?.removeFromSuperview()
                accessoryImageView = nil
                refreshLayout()
                return
            }
            
            if accessoryImageView == nil {
                accessoryImageView = UIImageView()
                accessoryImageView?.contentMode = .center
            }
            accessoryImageView?.image = accessoryImage
            accessoryImageView?.sizeToFit()
            if let accessoryImageView = accessoryImageView, accessoryImageView.superview == nil {
                contentView.addSubview(accessoryImageView)
            }
            refreshLayout()
        }
    }
    private var _accessoryImage: UIImage?
    
    /// 指定accessoryView偏移位置，默认(3, 0)
    open var accessoryViewOffset: CGPoint = CGPoint(x: 3, y: 0) {
        didSet { refreshLayout() }
    }
    
    /// 值为YES则title居中，`accessoryView`放在title的左边或右边；如果为NO，`accessoryView`和title整体居中；默认NO
    open var showsAccessoryPlaceholder: Bool = false {
        didSet { refreshLayout() }
    }
    
    /// 标题标签
    open lazy var titleLabel: UILabel = {
        let result = UILabel()
        result.textAlignment = .center
        result.lineBreakMode = .byTruncatingTail
        result.accessibilityTraits = result.accessibilityTraits.union(.header)
        result.font = horizontalTitleFont
        return result
    }()
    
    private lazy var contentView: UIView = {
        let result = UIView()
        result.isUserInteractionEnabled = false
        return result
    }()
    
    private var titleLabelSize: CGSize = .zero
    private var accessoryImageView: UIImageView?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        didInitialize()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        didInitialize()
    }
    
    private func didInitialize() {
        addTarget(self, action: #selector(titleViewTouched), for: .touchUpInside)
        
        addSubview(contentView)
        contentView.addSubview(titleLabel)
        
        isUserInteractionEnabled = false
        contentHorizontalAlignment = .center
    }
    
    open override var contentHorizontalAlignment: UIControl.ContentHorizontalAlignment {
        get {
            super.contentHorizontalAlignment
        }
        set {
            super.contentHorizontalAlignment = newValue
            refreshLayout()
        }
    }
    
    open override var isHighlighted: Bool {
        get {
            super.isHighlighted
        }
        set {
            super.isHighlighted = newValue
            alpha = isHighlighted ? 0.5 : 1.0
        }
    }
    
    open override func setNeedsLayout() {
        updateTitleLabelSize()
        super.setNeedsLayout()
    }
    
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        var resultSize = contentSize
        resultSize.width = min(resultSize.width, maximumWidth)
        return resultSize
    }
    
    open override var intrinsicContentSize: CGSize {
        return sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
    }
    
    open override func tintColorDidChange() {
        super.tintColorDidChange()
        
        if adjustsTintColor {
            titleLabel.textColor = tintColor
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.size.width <= 0 || bounds.size.height <= 0 { return }
        contentView.frame = bounds
        
        let maxSize = bounds.size
        var contentSize = self.contentSize
        contentSize.width = min(maxSize.width, contentSize.width)
        contentSize.height = min(maxSize.height, contentSize.height)
        
        let contentOffsetLeft = (maxSize.width - contentSize.width) / 2.0
        let contentOffsetRight = contentOffsetLeft
        
        let accessoryView = self.accessoryView ?? self.accessoryImageView
        let accessoryViewSpace = accessorySpacingSize.width
        let isTitleLabelShowing = (titleLabel.text?.count ?? 0) > 0
        let titleEdgeInsets = titleEdgeInsetsIfShowingTitleLabel
        
        var minX = contentOffsetLeft + (showsAccessoryPlaceholder ? accessoryViewSpace : 0)
        var maxX = maxSize.width - contentOffsetRight
        
        if let accessoryView = accessoryView {
            var accessoryFrame = accessoryView.frame
            accessoryFrame.origin.x = maxX - accessoryView.bounds.width
            accessoryFrame.origin.y = (maxSize.height - accessoryView.bounds.height) / 2.0 + accessoryViewOffset.y
            accessoryView.frame = accessoryFrame
            maxX = accessoryView.frame.minX - accessoryViewOffset.x
        }
        
        if isTitleLabelShowing {
            minX += titleEdgeInsets.left
            maxX -= titleEdgeInsets.right
            let shouldTitleLabelCenterVertically = titleLabelSize.height + (titleEdgeInsets.top + titleEdgeInsets.bottom) < contentSize.height
            let titleLabelMinY = shouldTitleLabelCenterVertically ? (maxSize.height - titleLabelSize.height) / 2.0 + titleEdgeInsets.top - titleEdgeInsets.bottom : titleEdgeInsets.top
            titleLabel.frame = CGRect(x: minX, y: titleLabelMinY, width: maxX - minX, height: titleLabelSize.height)
        } else {
            titleLabel.frame = CGRect.zero
        }
        
        var offsetY: CGFloat = (maxSize.height - contentSize.height) / 2.0
        if contentVerticalAlignment == .top {
            offsetY = 0
        } else if contentVerticalAlignment == .bottom {
            offsetY = maxSize.height - contentSize.height
        }
        subviews.forEach { obj in
            if !CGRectIsEmpty(obj.frame) {
                var objFrame = obj.frame
                objFrame.origin.y = obj.frame.minY + offsetY
                obj.frame = objFrame
            }
        }
    }
    
    /// 动画方式设置标题栏是否激活，主要针对accessoryImage生效
    open func setActive(_ active: Bool, animated: Bool) {
        guard _isActive != active else { return }
        _isActive = active
        delegate?.didChangedActive(active, for: self)
        if accessoryImage != nil {
            let rotationDegree: CGFloat = active ? -180 : -360
            UIView.animate(withDuration: animated ? 0.25 : 0, delay: 0, options: .init(rawValue: 8<<16)) {
                self.accessoryImageView?.transform = .init(rotationAngle: CGFloat.pi * rotationDegree / 180.0)
            }
        }
    }
    
    private var accessorySpacingSize: CGSize {
        if let view = accessoryView ?? accessoryImageView {
            return CGSize(width: view.bounds.width + accessoryViewOffset.x, height: view.bounds.height)
        }
        return .zero
    }
    
    private var accessorySpacingSizeIfNeedesPlaceholder: CGSize {
        return CGSize(width: accessorySpacingSize.width * (showsAccessoryPlaceholder ? 2 : 1), height: accessorySpacingSize.height)
    }
    
    private var titleEdgeInsetsIfShowingTitleLabel: UIEdgeInsets {
        return (titleLabelSize.width <= 0 || titleLabelSize.height <= 0) ? .zero : titleEdgeInsets
    }
    
    private var firstLineWidthInVerticalStyle: CGFloat {
        var firstLineWidth: CGFloat = titleLabelSize.width + (titleEdgeInsetsIfShowingTitleLabel.left + titleEdgeInsetsIfShowingTitleLabel.right)
        firstLineWidth += accessorySpacingSizeIfNeedesPlaceholder.width
        return firstLineWidth
    }
    
    private var contentSize: CGSize {
        var size = CGSize.zero
        size.width = titleLabelSize.width + (titleEdgeInsetsIfShowingTitleLabel.left + titleEdgeInsetsIfShowingTitleLabel.right)
        size.width += accessorySpacingSizeIfNeedesPlaceholder.width
        size.height = max(titleLabelSize.height + (titleEdgeInsetsIfShowingTitleLabel.top + titleEdgeInsetsIfShowingTitleLabel.bottom), 0)
        size.height = max(size.height, accessorySpacingSizeIfNeedesPlaceholder.height)
        return CGSize(width: UIScreen.fw.flatValue(size.width), height: UIScreen.fw.flatValue(size.height))
    }
    
    private func refreshLayout() {
        let navigationBar = searchNavigationBar(self)
        navigationBar?.setNeedsLayout()
        setNeedsLayout()
        invalidateIntrinsicContentSize()
    }
    
    private func searchNavigationBar(_ child: UIView) -> UINavigationBar? {
        guard let parent = child.superview else { return nil }
        if let navigationBar = parent as? UINavigationBar { return navigationBar }
        return searchNavigationBar(parent)
    }
    
    private func updateTitleLabelSize() {
        if (titleLabel.text?.count ?? 0) > 0 {
            let size = titleLabel.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
            titleLabelSize = CGSize(width: ceil(size.width), height: ceil(size.height))
        } else {
            titleLabelSize = .zero
        }
    }
    
    @objc private func titleViewTouched() {
        let active = !isActive
        delegate?.didTouchTitleView(self, isActive: active)
        setActive(active, animated: true)
        refreshLayout()
    }
    
}
