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
