//
//  TestImageController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/15.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework
import SDWebImage

class TestImageController: UIViewController, TableViewControllerProtocol {
    
    var isSDWebImage: Bool = false
    
    func setupTableStyle() -> UITableView.Style {
        .grouped
    }
    
    func setupNavbar() {
        app.setRightBarItem(UIBarButtonItem.SystemItem.action.rawValue) { [weak self] _ in
            self?.app.showSheet(title: nil, message: nil, actions: ["切换图片插件", "切换加载动画", "切换占位图加载动画", "清除图片缓存"], actionBlock: { index in
                guard let self = self else { return }
                
                if index == 0 {
                    self.isSDWebImage = !self.isSDWebImage
                    PluginManager.unloadPlugin(ImagePlugin.self)
                    PluginManager.registerPlugin(ImagePlugin.self, object: self.isSDWebImage ? SDWebImageImpl.self : ImagePluginImpl.self)
                } else if index == 1 {
                    if self.isSDWebImage {
                        SDWebImageImpl.shared.showsIndicator = !SDWebImageImpl.shared.showsIndicator
                        ImagePluginImpl.shared.showsIndicator = SDWebImageImpl.shared.showsIndicator
                    } else {
                        ImagePluginImpl.shared.showsIndicator = !ImagePluginImpl.shared.showsIndicator
                        SDWebImageImpl.shared.showsIndicator = ImagePluginImpl.shared.showsIndicator
                    }
                } else if index == 2 {
                    ImagePluginImpl.shared.hidesPlaceholderIndicator = !ImagePluginImpl.shared.hidesPlaceholderIndicator
                    SDWebImageImpl.shared.hidesPlaceholderIndicator = ImagePluginImpl.shared.hidesPlaceholderIndicator
                } else if index == 3 {
                    ImagePluginImpl.shared.clearImageCaches()
                    SDWebImageImpl.shared.clearImageCaches()
                }
                
                self.tableData.removeAll()
                self.tableView.reloadData()
                self.tableView.layoutIfNeeded()
                self.tableView.setContentOffset(.zero, animated: false)
                self.setupSubviews()
            })
        }
    }
    
    func setupSubviews() {
        self.isSDWebImage = PluginManager.loadPlugin(ImagePlugin.self) is SDWebImageImpl
        navigationItem.title = self.isSDWebImage ? "FWImage - SDWebImage" : "FWImage - FWWebImage"
        SDWebImageImpl.shared.fadeAnimated = true
        ImagePluginImpl.shared.fadeAnimated = true
        
        tableData = [
            "Animation.png",
            "Loading.gif",
            "http://kvm.wuyong.site/images/images/progressive.jpg",
            "http://kvm.wuyong.site/images/images/animation.png",
            "http://kvm.wuyong.site/images/images/test.gif",
            "http://kvm.wuyong.site/images/images/test.webp",
            "http://kvm.wuyong.site/images/images/test.heic",
            "http://kvm.wuyong.site/images/images/test.heif",
            "http://kvm.wuyong.site/images/images/animation.heic",
            "http://assets.sbnation.com/assets/2512203/dogflops.gif",
            "https://raw.githubusercontent.com/liyong03/YLGIFImage/master/YLGIFImageDemo/YLGIFImageDemo/joy.gif",
            "http://apng.onevcat.com/assets/elephant.png",
            "http://www.ioncannon.net/wp-content/uploads/2011/06/test2.webp",
            "http://www.ioncannon.net/wp-content/uploads/2011/06/test9.webp",
            "http://littlesvr.ca/apng/images/SteamEngine.webp",
            "http://littlesvr.ca/apng/images/world-cup-2014-42.webp",
            "https://isparta.github.io/compare-webp/image/gif_webp/webp/2.webp",
            "https://nokiatech.github.io/heif/content/images/ski_jump_1440x960.heic",
            "https://nokiatech.github.io/heif/content/image_sequences/starfield_animation.heic",
            "https://s2.ax1x.com/2019/11/01/KHYIgJ.gif",
            "https://raw.githubusercontent.com/icons8/flat-color-icons/master/pdf/stack_of_photos.pdf",
            "https://nr-platform.s3.amazonaws.com/uploads/platform/published_extension/branding_icon/275/AmazonS3.png",
            "https://upload.wikimedia.org/wikipedia/commons/1/14/Mahuri.svg",
            "https://simpleicons.org/icons/github.svg",
            "http://via.placeholder.com/200x200.jpg",
        ]
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        150
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = TestImageCell.app.cell(tableView: tableView, style: .default, reuseIdentifier: self.isSDWebImage ? "SDWebImage" : "FWWebImage")
        let fileName = tableData[indexPath.row] as? String ?? ""
        cell.nameLabel.text = (fileName as NSString).lastPathComponent.appendingFormat("(%@)", Data.app.mimeType(from: (fileName as NSString).pathExtension))
        if !fileName.app.isValid(.isUrl) {
            DispatchQueue.global().async {
                let image = ModuleBundle.imageNamed(fileName)
                let decodeImage = UIImage.app.image(data: UIImage.app.data(image: image))
                DispatchQueue.main.async {
                    cell.systemView.app.setImage(url: nil, placeholderImage: image)
                    cell.animatedView.app.setImage(url: nil, placeholderImage: decodeImage)
                }
            }
        } else {
            let url = fileName
            let pixelSize = CGSize(width: 100.0 * UIScreen.main.scale, height: 100.0 * UIScreen.main.scale)
            let cachedImage = UIImageView.app.loadImageCache(url: url)
            cell.systemView.app.setBorderColor(AppTheme.borderColor, width: cachedImage != nil ? 1 : 0, cornerRadius: 4)
            cell.systemView.app.setImage(url: url, placeholderImage: cachedImage, options: [], context: [.optionThumbnailPixelSize: NSValue(cgSize: pixelSize)])
            cell.animatedView.app.setBorderColor(AppTheme.borderColor, width: cachedImage != nil ? 1 : 0, cornerRadius: 4)
            cell.animatedView.app.setImage(url: url, placeholderImage: cachedImage, options: [], context: [.optionThumbnailPixelSize: NSValue(cgSize: pixelSize)])
        }
        return cell
    }
    
}

class TestImageCell: UITableViewCell {
    
    lazy var nameLabel: UILabel = {
        let result = UILabel()
        return result
    }()
    
    lazy var systemView: UIImageView = {
        let result = UIImageView()
        return result
    }()
    
    lazy var animatedView: UIImageView = {
        let result = UIImageView.app.animatedImageView()
        return result
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(nameLabel)
        contentView.addSubview(systemView)
        contentView.addSubview(animatedView)
        
        nameLabel.app.layoutChain
            .left(10)
            .top(10)
            .height(20)
        
        systemView.app.layoutChain
            .left(10)
            .top(toViewBottom: nameLabel, offset: 10)
            .bottom(10)
            .width(100)
        
        animatedView.app.layoutChain
            .left(toViewRight: systemView, offset: 60)
            .top(toView: systemView)
            .bottom(toView: systemView)
            .width(toView: systemView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
