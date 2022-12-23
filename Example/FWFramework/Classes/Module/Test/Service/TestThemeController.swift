//
//  TestThemeController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/15.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestThemeController: UIViewController, ViewControllerProtocol {
    
    static let testImage = FW.iconImage("zmdi-var-flower", 24)
    
    func didInitialize() {
        fw.observeNotification(.ThemeChanged) { _ in
            FW.debug("主题改变通知：\(ThemeManager.shared.style.rawValue)")
        }
        
        // iOS13以下named方式不支持动态颜色和图像，可手工注册之
        if #available(iOS 13.0, *) {} else {
            UIColor.fw.setThemeColor(UIColor.fw.themeLight(.black, dark: .white), forName: "themeColor")
            UIImage.fw.setThemeImage(UIImage.fw.themeLight(ModuleBundle.imageNamed("themeImageLight"), dark: ModuleBundle.imageNamed("themeImageDark")), forName: "themeImage")
        }
    }
    
    func setupSubviews() {
        fw.extendedLayoutEdge = .bottom
        view.backgroundColor = UIColor.fw.themeLight(.white, dark: .black)
        
        var colorView = UIView(frame: CGRect(x: 20, y: 20, width: 50, height: 50))
        colorView.backgroundColor = UIColor.fw.themeLight(.black, dark: .white)
        view.addSubview(colorView)
        
        colorView = UIView(frame: CGRect(x: 90, y: 20, width: 50, height: 50))
        colorView.backgroundColor = UIColor.fw.themeNamed("themeColor", bundle: ModuleBundle.bundle())
        view.addSubview(colorView)
        
        let colorView1 = UIView(frame: CGRect(x: 160, y: 20, width: 50, height: 50))
        UIColor.fw.setThemeColor(UIColor.fw.themeLight(.black, dark: .white), forName: "dynamicColor")
        let dynamicColor = UIColor.fw.themeNamed("dynamicColor")
        colorView1.backgroundColor = dynamicColor.fw.color(forStyle: ThemeManager.shared.style)
        colorView1.fw.addThemeListener { style in
            colorView1.backgroundColor = dynamicColor.fw.color(forStyle: style)
        }
        view.addSubview(colorView1)
        
        let imageView1 = UIImageView(frame: CGRect(x: 20, y: 90, width: 50, height: 50))
        let themeImage = UIImage.fw.themeLight(ModuleBundle.imageNamed("themeImageLight"), dark: ModuleBundle.imageNamed("themeImageDark"))
        imageView1.image = themeImage.fw.image
        imageView1.fw.addThemeListener { style in
            imageView1.image = themeImage.fw.image
        }
        view.addSubview(imageView1)
        
        var imageView = UIImageView(frame: CGRect(x: 90, y: 90, width: 50, height: 50))
        imageView.fw.themeImage = UIImage.fw.themeNamed("themeImage", bundle: ModuleBundle.bundle())
        view.addSubview(imageView)
        
        let imageView2 = UIImageView(frame: CGRect(x: 160, y: 90, width: 50, height: 50))
        let reverseImage = UIImage.fw.themeNamed("themeImage", bundle: ModuleBundle.bundle())
        imageView2.image = reverseImage.fw.image(forStyle: ThemeManager.shared.style)
        imageView2.fw.addThemeListener { style in
            imageView2.image = reverseImage.fw.image(forStyle: style)
        }
        view.addSubview(imageView2)
        
        let layer1 = CALayer()
        layer1.frame = CGRect(x: 20, y: 160, width: 50, height: 50)
        let themeColor = UIColor.fw.themeLight(.black, dark: .white)
        layer1.backgroundColor = themeColor.fw.color(forStyle: ThemeManager.shared.style).cgColor
        layer1.fw.themeContext = self
        layer1.fw.addThemeListener { style in
            layer1.backgroundColor = themeColor.fw.color(forStyle: style).cgColor
        }
        view.layer.addSublayer(layer1)
        
        var layer = CALayer()
        layer.frame = CGRect(x: 90, y: 160, width: 50, height: 50)
        layer.fw.themeContext = self.view
        layer.fw.themeBackgroundColor = UIColor.fw.themeColor({ style in
            return style == .dark ? .white : .black
        })
        view.layer.addSublayer(layer)
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(x: 160, y: 160, width: 50, height: 50)
        gradientLayer.fw.themeContext = self
        gradientLayer.fw.themeColors = [UIColor.fw.themeNamed("themeColor", bundle: ModuleBundle.bundle()), UIColor.fw.themeNamed("themeColor", bundle: ModuleBundle.bundle())]
        view.layer.addSublayer(gradientLayer)
        
        let layer2 = CALayer()
        layer2.frame = CGRect(x: 20, y: 230, width: 50, height: 50)
        let layerImage = UIImage.fw.themeLight(ModuleBundle.imageNamed("themeImageLight"), dark: ModuleBundle.imageNamed("themeImageDark"))
        layer2.contents = layerImage.fw.image?.cgImage
        layer2.fw.themeContext = self.view
        layer2.fw.addThemeListener { style in
            layer2.contents = layerImage.fw.image?.cgImage
        }
        view.layer.addSublayer(layer2)
        
        layer = CALayer()
        layer.frame = CGRect(x: 90, y: 230, width: 50, height: 50)
        layer.fw.themeContext = self
        layer.fw.themeContents = UIImage.fw.themeImage({ style in
            return style == .dark ? ModuleBundle.imageNamed("themeImageDark") : ModuleBundle.imageNamed("themeImageLight")
        })
        view.layer.addSublayer(layer)
        
        layer = CALayer()
        layer.frame = CGRect(x: 160, y: 230, width: 50, height: 50)
        layer.fw.themeContext = self.view
        layer.fw.themeContents = UIImage.fw.themeNamed("themeImage", bundle: ModuleBundle.bundle())
        view.layer.addSublayer(layer)
        
        imageView = UIImageView(frame: CGRect(x: 20, y: 300, width: 50, height: 50))
        UIImage.fw.themeImageColor = AppTheme.textColor
        imageView.fw.themeImage = Self.testImage?.fw.themeImage
        view.addSubview(imageView)
        
        imageView = UIImageView(frame: CGRect(x: 90, y: 300, width: 50, height: 50))
        let colorImage = UIImage.fw.themeLight(Self.testImage, dark: Self.testImage)
        imageView.fw.themeImage = colorImage.fw.themeImage(color: AppTheme.textColor)
        view.addSubview(imageView)
        
        imageView = UIImageView(frame: CGRect(x: 160, y: 300, width: 50, height: 50))
        UIImage.fw.setThemeImage(UIImage.fw.themeLight(Self.testImage, dark: Self.testImage?.fw.image(tintColor: .white)), forName: "dynamicImage")
        let dynamicImage = UIImage.fw.themeNamed("dynamicImage")
        imageView.image = dynamicImage.fw.image(forStyle: ThemeManager.shared.style)
        imageView.fw.addThemeListener { style in
            imageView.image = dynamicImage.fw.image(forStyle: style)
        }
        view.addSubview(imageView)
        
        imageView = UIImageView(frame: CGRect(x: 20, y: 370, width: 50, height: 50))
        imageView.fw.themeAsset = UIImageAsset.fw.themeLight(Self.testImage, dark: Self.testImage?.fw.image(tintColor: .white))
        view.addSubview(imageView)
        
        imageView = UIImageView(frame: CGRect(x: 90, y: 370, width: 50, height: 50))
        imageView.fw.themeAsset = UIImageAsset.fw.themeAsset({ style in
            return style == .dark ? Self.testImage?.fw.image(tintColor: .white) : Self.testImage
        })
        view.addSubview(imageView)
        
        let imageView3 = UIImageView(frame: CGRect(x: 160, y: 370, width: 50, height: 50))
        imageView3.fw.themeImage = Self.testImage?.fw.themeImage(color: .red)
        view.addSubview(imageView3)
        
        let colorLabel = UILabel()
        colorLabel.frame = CGRect(x: 0, y: 440, width: FW.screenWidth, height: 25)
        colorLabel.textAlignment = .center
        colorLabel.font = FW.font(16).fw.boldFont
        colorLabel.textColor = AppTheme.textColor
        let lightColor = AppTheme.textColor.fw.color(forStyle: .light)
        let darkColor = AppTheme.textColor.fw.color(forStyle: .dark)
        colorLabel.text = "Light: \(lightColor.fw.hexString) Dark: \(darkColor.fw.hexString)"
        view.addSubview(colorLabel)
        
        let themeLabel = UILabel()
        themeLabel.frame = CGRect(x: 0, y: 475, width: FW.screenWidth, height: 25)
        themeLabel.textAlignment = .center
        themeLabel.attributedText = NSAttributedString.fw.attributedString("我是AttributedString", font: FW.font(16).fw.boldFont, textColor: UIColor.fw.themeLight(.black, dark: .white))
        view.addSubview(themeLabel)
        
        let themeButton = UIButton()
        themeButton.frame = CGRect(x: 0, y: 510, width: FW.screenWidth, height: 50)
        themeButton.titleLabel?.font = FW.font(16)
        themeButton.setTitleColor(UIColor.fw.themeLight(.black, dark: .white), for: .normal)
        
        let buttonImage = UIImage.fw.themeLight(ThemeManager.shared.style == .light ? nil : ModuleBundle.imageNamed("themeImageLight"), dark: ThemeManager.shared.style == .dark ? nil : ModuleBundle.imageNamed("themeImageDark"))
        let themeString = NSAttributedString.fw.themeObject(htmlString: "我是<span style='color:red;'>红色</span>AttributedString", defaultAttributes: [
            .font: FW.font(16, .bold),
            .foregroundColor: UIColor.fw.themeLight(.black, dark: .white)
        ])
        
        themeButton.setImage(buttonImage.fw.image, for: .normal)
        themeButton.setAttributedTitle(themeString.object, for: .normal)
        themeLabel.fw.addThemeListener { style in
            themeButton.setImage(buttonImage.fw.image, for: .normal)
            themeButton.setAttributedTitle(themeString.object, for: .normal)
        }
        view.addSubview(themeButton)
    }
    
}
