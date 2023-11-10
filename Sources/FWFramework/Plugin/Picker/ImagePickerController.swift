//
//  ImagePickerController.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

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
            navigationController?.navigationBar.fw_backgroundColor = toolbarBackgroundColor
        }
    }
    /// 工具栏颜色
    open var toolbarTintColor: UIColor? = .white {
        didSet {
            navigationController?.navigationBar.fw_foregroundColor = toolbarTintColor
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
    open private(set) var assetsGroup: AssetGroup? {
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
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: AppBundle.navCloseImage, style: .plain, target: self, action: #selector(handleCancelButtonClick(_:)))
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(image: UIImage(), style: .plain, target: nil, action: nil)
        navigationController?.navigationBar.fw_backImage = AppBundle.navBackImage
        if title == nil { title = AppBundle.pickerAlbumTitle }
        
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
        
        guard let navigationController = navigationController else { return }
        if navigationController.isNavigationBarHidden != false {
            navigationController.setNavigationBarHidden(false, animated: animated)
        }
        navigationController.navigationBar.fw_isTranslucent = false
        navigationController.navigationBar.fw_shadowColor = nil
        navigationController.navigationBar.fw_backgroundColor = toolbarBackgroundColor
        navigationController.navigationBar.fw_foregroundColor = toolbarTintColor
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        backgroundView.frame = view.bounds
        let contentInset = UIEdgeInsets(top: UIScreen.fw_topBarHeight, left: tableView.safeAreaInsets.left, bottom: tableView.safeAreaInsets.bottom, right: tableView.safeAreaInsets.right)
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
            tableFrame.size.height = tableViewHeight + UIScreen.fw_topBarHeight
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
                fw_showEmptyView(text: AppBundle.pickerEmptyTitle)
            }
        }
        
        albumsArrayLoaded?()
    }
    
    private func showDeniedView() {
        if maximumTableViewHeight > 0 {
            var tableFrame = tableView.frame
            tableFrame.size.height = tableViewHeight + UIScreen.fw_topBarHeight
            tableView.frame = tableFrame
        }
        
        if albumControllerDelegate?.albumControllerWillShowDenied?(self) != nil {
        } else {
            let appName = UIApplication.fw_appDisplayName
            let tipText = String(format: AppBundle.pickerDeniedTitle, appName)
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
            pickerController.refresh(withAssetsGroup: assetsGroup)
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
                pickerController.navigationItem.rightBarButtonItem = UIBarButtonItem(title: AppBundle.cancelButton, style: .plain, target: pickerController, action: #selector(ImagePickerController.handleCancelButtonClick(_:)))
            }
            // 此处需要强引用imagePickerController，防止weak属性释放imagePickerController
            fw_setProperty(pickerController, forName: "imagePickerController")
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
            self.imagePickerController?.selectedImageAssetArray?.removeAllObjects()
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
    
    open var toolbarBackgroundColor: UIColor? = UIColor(red: 27.0 / 255.0, green: 27.0 / 255.0, blue: 27.0 / 255.0, alpha: 1.0)
    open var toolbarTintColor: UIColor? = .white
    open var toolbarPaddingHorizontal: CGFloat = 16
    /// 自定义底部工具栏高度，默认同系统
    open var bottomToolbarHeight: CGFloat {
        get { return _bottomToolbarHeight > 0 ? _bottomToolbarHeight : UIScreen.fw_toolBarHeight }
        set { _bottomToolbarHeight = newValue }
    }
    private var _bottomToolbarHeight: CGFloat = 0
    
    open var checkboxImage: UIImage? = AppBundle.pickerCheckImage
    open var checkboxCheckedImage: UIImage? = AppBundle.pickerCheckedImage
    
    open var originImageCheckboxImage: UIImage? = {
        return AppBundle.pickerCheckImage?.fw_image(scaleSize: CGSize(width: 18, height: 18))
    }()
    open var originImageCheckboxCheckedImage: UIImage? = {
        return AppBundle.pickerCheckedImage?.fw_image(scaleSize: CGSize(width: 18, height: 18))
    }()
    /// 是否使用原图，不显示原图按钮时默认YES，显示原图按钮时默认NO
    open var shouldUseOriginImage: Bool = true
    /// 是否显示原图按钮，默认NO，设置后会修改shouldUseOriginImage
    open var showsOriginImageCheckboxButton: Bool = false
    /// 是否显示编辑按钮，默认YES
    open var showsEditButton: Bool = true
    
    /// 是否显示编辑collectionView，默认YES，仅多选生效
    open var showsEditCollectionView: Bool = true
    /// 编辑collectionView总高度，默认80
    open var editCollectionViewHeight: CGFloat = 80
    /// 编辑collectionCell大小，默认(60, 60)
    open var editCollectionCellSize: CGSize = CGSizeMake(60, 60)
    
    /// 是否显示默认loading，优先级低于delegate，默认YES
    open var showsDefaultLoading: Bool = true
    
    /// 由于组件需要通过本地图片的 Asset 对象读取图片的详细信息，因此这里的需要传入的是包含一个或多个 Asset 对象的数组
    open var imagesAssetArray: [Asset]?
    open var selectedImageAssetArray: [Asset]?
    
    open var downloadStatus: AssetDownloadStatus = .succeed
    
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
        result.setImage(AppBundle.navBackImage, for: .normal)
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
        result.addSubview(editButton)
        result.addSubview(sendButton)
        result.addSubview(originImageCheckboxButton)
        return result
    }()
    
    open lazy var sendButton: UIButton = {
        let result = UIButton()
        result.fw_touchInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        result.setTitle(AppBundle.doneButton, for: .normal)
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
        result.setTitle(AppBundle.editButton, for: .normal)
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
        result.setTitle(AppBundle.originalButton, for: .normal)
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
            return imagesAssetArray ?? []
        } else {
            return selectedImageAssetArray ?? []
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
    
    /// 更新数据并刷新 UI，手工调用
    /// - Parameters:
    ///   - imageAssetArray: 包含所有需要展示的图片的数组
    ///   - selectedImageAssetArray: 包含所有需要展示的图片中已经被选中的图片的数组
    ///   - currentImageIndex: 当前展示的图片在 imageAssetArray 的索引
    ///   - singleCheckMode: 是否为单选模式，如果是单选模式，则不显示 checkbox
    ///   - previewMode: 是否是预览模式，如果是预览模式，图片取消选中时editCollectionView会置灰而不是隐藏
    open func updateImagePickerPreviewView(
        imageAssetArray: [Asset]?,
        selectedImageAssetArray: [Asset]?,
        currentImageIndex: Int,
        singleCheckMode: Bool,
        previewMode: Bool
    ) {
        
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
        cell.disabled = !(selectedImageAssetArray?.contains(imageAsset) ?? false)
        
        if delegate?.imagePickerPreviewController?(self, customCell: cell, at: indexPath) != nil {
        } else {
            customCellBlock?(cell, indexPath)
        }
        return cell
    }
    
    open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let imageAsset = editImageAssetArray[indexPath.item]
        let imageIndex = imagesAssetArray?.firstIndex(of: imageAsset)
        if let imageIndex = imageIndex, imagePreviewView.currentImageIndex != imageIndex {
            imagePreviewView.currentImageIndex = imageIndex
            updateOriginImageCheckboxButton(index: imageIndex)
        }
        
        updateCollectionViewCheckedIndex(indexPath.item)
    }
    
    // MARK: - Private
    @objc private func handleCancelButtonClick(_ sender: UIButton) {
        
    }
    
    @objc private func handleCheckButtonClick(_ sender: UIButton) {
        
    }
    
    @objc private func handleEditButtonClick(_ sender: UIButton) {
        
    }
    
    @objc private func handleSendButtonClick(_ sender: UIButton) {
        
    }
    
    @objc private func handleOriginImageCheckboxButtonClick(_ sender: UIButton) {
        
    }
    
    private func updateOriginImageCheckboxButton(index: Int) {
        
    }
    
    private func updateCollectionViewCheckedIndex(_ index: Int) {
        
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
            let value = fw_property(forName: "pickerCroppedRect") as? NSValue
            return value?.cgRectValue ?? .zero
        }
        set {
            fw_setProperty(NSValue(cgRect: newValue), forName: "pickerCroppedRect")
        }
    }
    
    var pickerCroppedAngle: Int {
        get {
            return fw_propertyInt(forName: "pickerCroppedAngle")
        }
        set {
            fw_setPropertyInt(newValue, forName: "pickerCroppedAngle")
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

/// 图片选择空间里的九宫格 cell，支持显示 checkbox、饼状进度条及重试按钮（iCloud 图片需要）
open class ImagePickerCollectionCell: UICollectionViewCell {
    
    /// checkbox 未被选中时显示的图片
    open var checkboxImage: UIImage? = AppBundle.pickerCheckImage {
        didSet {
            checkboxButton.setImage(checkboxImage, for: .normal)
            checkboxButton.sizeToFit()
            setNeedsLayout()
        }
    }
    
    /// checkbox 被选中时显示的图片
    open var checkboxCheckedImage: UIImage? = AppBundle.pickerCheckedImage {
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
