//
//  TestCompatibleController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/30.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestCompatibleController: UIViewController, ViewControllerProtocol {
    
    enum Mode: Int {
    case `default` = 0
    case relative = 1
    case transform = 2
    }
    
    var mode: Mode = .default {
        didSet {
            setupSubviews()
        }
    }
    
    var designMargin: CGFloat {
        return designValue(15)
    }
    var designSize: CGFloat {
        return designValue(100)
    }
    func designValue(_ value: CGFloat) -> CGFloat {
        return mode == .relative ? FW.relative(value) : value
    }
    
    private lazy var bannerView: BannerView = {
        let result = BannerView()
        result.autoScroll = true
        result.autoScrollTimeInterval = 4
        result.placeholderImage = ModuleBundle.imageNamed("Loading.gif")
        result.imageURLStringsGroup = [
            "http://e.hiphotos.baidu.com/image/h%3D300/sign=0e95c82fa90f4bfb93d09854334e788f/10dfa9ec8a136327ee4765839c8fa0ec09fac7dc.jpg",
            ModuleBundle.imageNamed("Loading.gif") as Any,
            "http://www.ioncannon.net/wp-content/uploads/2011/06/test2.webp",
            "http://littlesvr.ca/apng/images/SteamEngine.webp",
            "not_found.jpg",
            "http://ww2.sinaimg.cn/bmiddle/642beb18gw1ep3629gfm0g206o050b2a.gif"
        ]
        result.titlesGroup = ["1", "2", "3", "4", "5", "6"]
        return result
    }()
    
    private lazy var imageView: UIImageView = {
        let result = UIImageView()
        result.contentMode = .scaleAspectFill
        result.image = UIImage.fw.appIconImage()
        return result
    }()
    
    private lazy var textLabel: UILabel = {
        let result = UILabel()
        result.numberOfLines = 0
        result.backgroundColor = AppTheme.backgroundColor
        result.textColor = AppTheme.textColor
        result.textAlignment = .center
        result.fw.setBorderColor(AppTheme.borderColor, width: 0.5)
        return result
    }()
    
    private lazy var bottomView: UIView = {
        let result = UIView()
        result.backgroundColor = .brown
        return result
    }()
    
    private lazy var confirmButton: UIButton = {
        let result = AppTheme.largeButton()
        result.setTitle("确定", for: .normal)
        result.fw.addTouch { [weak self] _ in
            self?.fw.showMessage(text: "点击了确定")
        }
        return result
    }()
    
    func setupNavbar() {
        fw.extendedLayoutEdge = .bottom
        fw.setRightBarItem("切换") { [weak self] _ in
            self?.fw.showSheet(title: nil, message: nil, actions: ["默认适配", "等比例适配", "等比例缩放"], actionBlock: { index in
                self?.mode = .init(rawValue: index) ?? .default
            })
        }
    }
    
    func setupSubviews() {
        // 清空并重新添加视图
        view.fw.removeAllSubviews()
        view.addSubview(bannerView)
        view.addSubview(imageView)
        view.addSubview(textLabel)
        view.addSubview(bottomView)
        view.addSubview(confirmButton)
        
        // 等比例缩放(2)时只需设置transform
        if mode == .transform {
            if FW.relativeScale > FW.relativeHeightScale {
                view.transform = .init(scaleX: FW.relativeHeightScale, y: FW.relativeHeightScale)
            } else {
                view.transform = .init(scaleX: FW.relativeScale, y: FW.relativeScale)
            }
        // 其他模式(0,1)无需设置transform
        } else {
            view.transform = .identity
        }
        
        // 等比例适配(1)时字体大小为相对大小
        textLabel.font = FW.font(designValue(16))
        confirmButton.titleLabel?.font = FW.font(designValue(17), .bold)
        textLabel.text = "当前适配模式：\(mode == .default ? "默认适配" : (mode == .relative ? "等比例适配" : "等比例缩放"))\n示例设计图大小为\(UIScreen.fw.referenceSize.width)x\(UIScreen.fw.referenceSize.height)，当前屏幕大小为\(FW.screenWidth)x\(FW.screenHeight)，宽度缩放比例为\(FW.relativeScale)\n示例设计图间距为15，图片大小为100x100，观察不同兼容模式下不同屏幕的显示效果"
        
        // 等比例适配(1)时布局大小为相对大小
        bannerView.fw.layoutChain.remake()
            .top(designMargin)
            .horizontal(designMargin)
            .height(designSize)
        
        imageView.fw.layoutChain.remake()
            .centerX()
            .top(toViewBottom: bannerView, offset: designMargin)
            .size(CGSizeMake(designSize, designSize))
        
        textLabel.fw.layoutChain.remake()
            .horizontal(designMargin)
            .top(toViewBottom: imageView, offset: designMargin)
        
        bottomView.fw.layoutChain.remake()
            .centerX()
            .width(designSize)
            .top(toViewBottom: textLabel, offset: designMargin)
            .height(designValue(250))
        
        confirmButton.fw.layoutChain.remake()
            .horizontal(designMargin)
            .bottom(toSafeArea: designMargin)
            .height(designValue(50))
    }
    
}
