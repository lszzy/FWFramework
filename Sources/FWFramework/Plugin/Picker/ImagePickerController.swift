//
//  ImagePickerController.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

// MARK: - ImageAlbumController
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
