//
//  TestBannerController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/29.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestBannerController: UIViewController, ViewControllerProtocol, BannerViewDelegate {
    
    var imageUrls: [Any] = {
        return [
            "http://e.hiphotos.baidu.com/image/h%3D300/sign=0e95c82fa90f4bfb93d09854334e788f/10dfa9ec8a136327ee4765839c8fa0ec09fac7dc.jpg",
            ModuleBundle.imageNamed("Loading.gif") as Any,
            "http://www.ioncannon.net/wp-content/uploads/2011/06/test2.webp",
            "http://littlesvr.ca/apng/images/SteamEngine.webp",
            "not_found.jpg",
            "http://ww2.sinaimg.cn/bmiddle/642beb18gw1ep3629gfm0g206o050b2a.gif"
        ]
    }()
    
    var titlesGroup: [Any] = {
        return ["1", "2", "3", NSAttributedString(string: "4", attributes: [.foregroundColor: UIColor.app.randomColor]), NSAttributedString(string: "5", attributes: [.foregroundColor: UIColor.app.randomColor]), NSAttributedString(string: "6", attributes: [.foregroundColor: UIColor.app.randomColor])]
    }()
    
    private lazy var bannerView1: BannerView = {
        let result = BannerView()
        result.delegate = self
        result.autoScroll = true
        result.autoScrollTimeInterval = 4
        result.placeholderImage = ModuleBundle.imageNamed("Loading.gif")
        result.imagesGroup = imageUrls
        result.titlesGroup = titlesGroup
        return result
    }()
    
    private lazy var bannerView2: BannerView = {
        let result = BannerView()
        result.delegate = self
        result.autoScroll = true
        result.autoScrollTimeInterval = 4
        result.placeholderImage = UIImage.app.appIconImage()
        result.pageControlStyle = .custom
        result.pageControlDotSize = CGSize(width: 10, height: 1)
        result.pageControlDotSpacing = 4
        result.contentViewInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
        result.imagesGroup = imageUrls
        result.titlesGroup = titlesGroup
        return result
    }()
    
    private lazy var bannerView3: BannerView = {
        let result = BannerView()
        result.contentViewInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        result.contentViewCornerRadius = 5
        result.delegate = self
        result.autoScroll = true
        result.autoScrollTimeInterval = 4
        result.imageViewContentMode = .scaleAspectFill
        result.placeholderImage = UIImage.app.appIconImage()
        result.pageControlStyle = .custom
        result.pageControlDotSize = CGSize(width: 3, height: 3)
        result.pageControlCurrentDotSize = CGSize(width: 9, height: 3)
        result.pageControlDotSpacing = 3
        result.imagesGroup = imageUrls
        result.titlesGroup = titlesGroup
        return result
    }()
    
    private lazy var bannerView4: BannerView = {
        let result = BannerView()
        result.contentViewCornerRadius = 5
        result.delegate = self
        result.autoScroll = true
        result.autoScrollTimeInterval = 4
        result.imageViewContentMode = .scaleAspectFill
        result.placeholderImage = UIImage.app.appIconImage()
        result.pageControlStyle = .custom
        result.pageControlDotSize = CGSize(width: 3, height: 3)
        result.pageControlCurrentDotSize = CGSize(width: 3, height: 9)
        result.pageControlDotSpacing = 3
        result.itemPagingEnabled = true
        result.itemSpacing = 10
        result.imagesGroup = imageUrls
        result.titlesGroup = titlesGroup
        return result
    }()
    
    private lazy var bannerView5: BannerView = {
        let result = BannerView()
        result.contentViewCornerRadius = 5
        result.delegate = self
        result.autoScroll = true
        result.autoScrollTimeInterval = 4
        result.imageViewContentMode = .scaleAspectFill
        result.placeholderImage = UIImage.app.appIconImage()
        result.pageControlStyle = .none
        result.itemPagingEnabled = true
        result.itemSpacing = 10
        result.itemSize = CGSize(width: APP.screenWidth - 30, height: 100)
        result.imagesGroup = imageUrls
        result.titlesGroup = titlesGroup
        return result
    }()
    
    private lazy var bannerView6: BannerView = {
        let result = BannerView()
        result.contentViewCornerRadius = 5
        result.delegate = self
        result.autoScroll = true
        result.autoScrollTimeInterval = 4
        result.imageViewContentMode = .scaleAspectFill
        result.placeholderImage = UIImage.app.appIconImage()
        result.pageControlStyle = .none
        result.itemPagingEnabled = true
        result.itemSpacing = 10
        result.itemPagingCenter = true
        result.itemSize = CGSize(width: APP.screenWidth - 40, height: 100)
        result.imagesGroup = imageUrls
        result.titlesGroup = titlesGroup
        return result
    }()
    
    func setupSubviews() {
        view.addSubview(bannerView1)
        view.addSubview(bannerView2)
        view.addSubview(bannerView3)
        view.addSubview(bannerView4)
        view.addSubview(bannerView5)
        view.addSubview(bannerView6)
    }
    
    func setupLayout() {
        bannerView1.app.layoutChain
            .top(toSafeArea: 10)
            .left()
            .width(APP.screenWidth)
            .height(100)
        
        bannerView2.app.layoutChain
            .top(toViewBottom: bannerView1, offset: 10)
            .left()
            .height(100)
            .width(APP.screenWidth + 10)
        
        bannerView3.app.layoutChain
            .top(toViewBottom: bannerView2, offset: 10)
            .left()
            .height(100)
            .width(APP.screenWidth)
        
        bannerView4.app.layoutChain
            .top(toViewBottom: bannerView3, offset: 10)
            .left()
            .height(100)
            .width(APP.screenWidth)
        
        bannerView5.app.layoutChain
            .top(toViewBottom: bannerView4, offset: 10)
            .left()
            .height(100)
            .width(APP.screenWidth)
        
        bannerView6.app.layoutChain
            .top(toViewBottom: bannerView5, offset: 10)
            .left()
            .height(100)
            .width(APP.screenWidth)
    }
    
    func bannerView(_ bannerView: BannerView, didSelectItemAt index: Int) {
        app.showMessage(text: "点击了：\(index)")
    }
    
}
