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
        fw.setRightBarItem("Change") { [weak self] _ in
            guard let self = self else { return }
            self.isSDWebImage = !self.isSDWebImage
            PluginManager.unloadPlugin(ImagePlugin.self)
            PluginManager.registerPlugin(ImagePlugin.self, object: self.isSDWebImage ? SDWebImageImpl.self : ImagePluginImpl.self)
            if self.isSDWebImage {
                SDImageCache.shared.clear(with: .all)
            }
            
            self.tableData.removeAllObjects()
            self.tableView.reloadData()
            self.tableView.layoutIfNeeded()
            self.tableView.setContentOffset(.zero, animated: false)
            self.setupSubviews()
        }
    }
    
    func setupSubviews() {
        self.isSDWebImage = PluginManager.loadPlugin(ImagePlugin.self) is SDWebImageImpl
        navigationItem.title = self.isSDWebImage ? "FWImage - SDWebImage" : "FWImage - FWWebImage"
        SDWebImageImpl.shared.fadeAnimated = true
        ImagePluginImpl.shared.fadeAnimated = true
        
        tableData.setArray([
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
        ])
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        150
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = TestImageCell.fw.cell(tableView: tableView, style: .default, reuseIdentifier: self.isSDWebImage ? "SDWebImage" : "FWWebImage")
        let fileName = tableData.object(at: indexPath.row) as? String ?? ""
        cell.nameLabel.text = (fileName as NSString).lastPathComponent.appendingFormat("(%@)", Data.fw.mimeType(from: (fileName as NSString).pathExtension))
        if !fileName.fw.isFormatUrl {
            cell.fw.tempObject = fileName
            DispatchQueue.global().async {
                let image = ModuleBundle.imageNamed(fileName)
                let decodeImage = UIImage.fw.image(data: UIImage.fw.data(image: image))
                DispatchQueue.main.async {
                    if let tempObject = cell.fw.tempObject as? String, tempObject == fileName {
                        cell.systemView.fw.setImage(url: nil, placeholderImage: image)
                        cell.animatedView.fw.setImage(url: nil, placeholderImage: decodeImage)
                    }
                }
            }
        } else {
            cell.fw.tempObject = nil
            var url = fileName
            if url.hasPrefix("http://kvm.wuyong.site") {
                url = url.appending("?t=\(Date.fw.currentTime)")
            }
            cell.systemView.fw.setImage(url: url)
            cell.animatedView.fw.setImage(url: url, placeholderImage: UIImage.fw.appIconImage())
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
        let result = UIImageView.fw.animatedImageView()
        return result
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(nameLabel)
        contentView.addSubview(systemView)
        contentView.addSubview(animatedView)
        
        nameLabel.fw.layoutChain
            .left(10)
            .top(10)
            .height(20)
        
        systemView.fw.layoutChain
            .left(10)
            .top(toViewBottom: nameLabel, offset: 10)
            .bottom(10)
            .width(100)
        
        animatedView.fw.layoutChain
            .left(toViewRight: systemView, offset: 60)
            .top(toView: systemView)
            .bottom(toView: systemView)
            .width(toView: systemView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
