//
//  TestThemeController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/15.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestThemeController: UIViewController, ViewControllerProtocol {
    static let testImage = APP.iconImage("zmdi-var-flower", 24)

    func didInitialize() {
        app.observeNotification(.ThemeChanged) { _ in
            APP.debug("主题改变通知：\(ThemeManager.shared.style.rawValue)")
        }
    }

    func setupSubviews() {
        app.extendedLayoutEdge = .bottom
        view.backgroundColor = UIColor.app.themeLight(.white, dark: .black)

        var colorView = UIView(frame: CGRect(x: 20, y: 20, width: 50, height: 50))
        colorView.backgroundColor = UIColor.app.themeLight(.black, dark: .white)
        view.addSubview(colorView)

        colorView = UIView(frame: CGRect(x: 90, y: 20, width: 50, height: 50))
        colorView.backgroundColor = UIColor.app.themeNamed("themeColor", bundle: ModuleBundle.bundle())
        view.addSubview(colorView)

        let colorView1 = UIView(frame: CGRect(x: 160, y: 20, width: 50, height: 50))
        UIColor.app.setThemeColor(UIColor.app.themeLight(.black, dark: .white), forName: "dynamicColor")
        let dynamicColor = UIColor.app.themeNamed("dynamicColor")
        colorView1.backgroundColor = dynamicColor.app.color(forStyle: ThemeManager.shared.style)
        colorView1.app.addThemeListener { style in
            colorView1.backgroundColor = dynamicColor.app.color(forStyle: style)
        }
        view.addSubview(colorView1)

        let imageView1 = UIImageView(frame: CGRect(x: 20, y: 90, width: 50, height: 50))
        let themeImage = UIImage.app.themeLight(ModuleBundle.imageNamed("themeImageLight"), dark: ModuleBundle.imageNamed("themeImageDark"))
        imageView1.image = themeImage.app.image
        imageView1.app.addThemeListener { _ in
            imageView1.image = themeImage.app.image
        }
        view.addSubview(imageView1)

        var imageView = UIImageView(frame: CGRect(x: 90, y: 90, width: 50, height: 50))
        imageView.app.themeImage = UIImage.app.themeNamed("themeImage", bundle: ModuleBundle.bundle())
        view.addSubview(imageView)

        let imageView2 = UIImageView(frame: CGRect(x: 160, y: 90, width: 50, height: 50))
        let reverseImage = UIImage.app.themeNamed("themeImage", bundle: ModuleBundle.bundle())
        imageView2.image = reverseImage.app.image(forStyle: ThemeManager.shared.style)
        imageView2.app.addThemeListener { style in
            imageView2.image = reverseImage.app.image(forStyle: style)
        }
        view.addSubview(imageView2)

        let layer1 = CALayer()
        layer1.frame = CGRect(x: 20, y: 160, width: 50, height: 50)
        let themeColor = UIColor.app.themeLight(.black, dark: .white)
        layer1.backgroundColor = themeColor.app.color(forStyle: ThemeManager.shared.style).cgColor
        layer1.app.themeContext = self
        layer1.app.addThemeListener { style in
            layer1.backgroundColor = themeColor.app.color(forStyle: style).cgColor
        }
        view.layer.addSublayer(layer1)

        var layer = CALayer()
        layer.frame = CGRect(x: 90, y: 160, width: 50, height: 50)
        layer.app.themeContext = view
        layer.app.themeBackgroundColor = UIColor.app.themeColor { style in
            style == .dark ? .white : .black
        }
        view.layer.addSublayer(layer)

        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(x: 160, y: 160, width: 50, height: 50)
        gradientLayer.app.themeContext = self
        gradientLayer.app.themeColors = [UIColor.app.themeNamed("themeColor", bundle: ModuleBundle.bundle()), UIColor.app.themeNamed("themeColor", bundle: ModuleBundle.bundle())]
        view.layer.addSublayer(gradientLayer)

        let layer2 = CALayer()
        layer2.frame = CGRect(x: 20, y: 230, width: 50, height: 50)
        let layerImage = UIImage.app.themeLight(ModuleBundle.imageNamed("themeImageLight"), dark: ModuleBundle.imageNamed("themeImageDark"))
        layer2.contents = layerImage.app.image?.cgImage
        layer2.app.themeContext = view
        layer2.app.addThemeListener { _ in
            layer2.contents = layerImage.app.image?.cgImage
        }
        view.layer.addSublayer(layer2)

        layer = CALayer()
        layer.frame = CGRect(x: 90, y: 230, width: 50, height: 50)
        layer.app.themeContext = self
        layer.app.themeContents = UIImage.app.themeImage { style in
            style == .dark ? ModuleBundle.imageNamed("themeImageDark") : ModuleBundle.imageNamed("themeImageLight")
        }
        view.layer.addSublayer(layer)

        layer = CALayer()
        layer.frame = CGRect(x: 160, y: 230, width: 50, height: 50)
        layer.app.themeContext = view
        layer.app.themeContents = UIImage.app.themeNamed("themeImage", bundle: ModuleBundle.bundle())
        view.layer.addSublayer(layer)

        imageView = UIImageView(frame: CGRect(x: 20, y: 300, width: 50, height: 50))
        UIImage.app.themeImageColorConfiguration = { AppTheme.textColor }
        imageView.app.themeImage = Self.testImage?.app.themeImage
        view.addSubview(imageView)

        imageView = UIImageView(frame: CGRect(x: 90, y: 300, width: 50, height: 50))
        let colorImage = UIImage.app.themeLight(Self.testImage, dark: Self.testImage)
        imageView.app.themeImage = colorImage.app.themeImage(color: AppTheme.textColor)
        view.addSubview(imageView)

        imageView = UIImageView(frame: CGRect(x: 160, y: 300, width: 50, height: 50))
        UIImage.app.setThemeImage(UIImage.app.themeLight(Self.testImage, dark: Self.testImage?.app.image(tintColor: .white)), forName: "dynamicImage")
        let dynamicImage = UIImage.app.themeNamed("dynamicImage")
        imageView.image = dynamicImage.app.image(forStyle: ThemeManager.shared.style)
        imageView.app.addThemeListener { style in
            imageView.image = dynamicImage.app.image(forStyle: style)
        }
        view.addSubview(imageView)

        imageView = UIImageView(frame: CGRect(x: 20, y: 370, width: 50, height: 50))
        imageView.app.themeAsset = UIImageAsset.app.themeLight(Self.testImage, dark: Self.testImage?.app.image(tintColor: .white))
        view.addSubview(imageView)

        imageView = UIImageView(frame: CGRect(x: 90, y: 370, width: 50, height: 50))
        imageView.app.themeAsset = UIImageAsset.app.themeAsset { style in
            style == .dark ? Self.testImage?.app.image(tintColor: .white) : Self.testImage
        }
        view.addSubview(imageView)

        let imageView3 = UIImageView(frame: CGRect(x: 160, y: 370, width: 50, height: 50))
        imageView3.app.themeImage = Self.testImage?.app.themeImage(color: .red)
        view.addSubview(imageView3)

        let colorLabel = UILabel()
        colorLabel.frame = CGRect(x: 0, y: 440, width: APP.screenWidth, height: 25)
        colorLabel.textAlignment = .center
        colorLabel.font = APP.font(16).app.boldFont
        colorLabel.textColor = AppTheme.textColor
        let lightColor = AppTheme.textColor.app.color(forStyle: .light)
        let darkColor = AppTheme.textColor.app.color(forStyle: .dark)
        colorLabel.text = "Light: \(lightColor.app.hexString) Dark: \(darkColor.app.hexString)"
        view.addSubview(colorLabel)

        let themeLabel = UILabel()
        themeLabel.frame = CGRect(x: 0, y: 475, width: APP.screenWidth, height: 25)
        themeLabel.textAlignment = .center
        themeLabel.attributedText = NSAttributedString.app.attributedString("我是AttributedString", font: APP.font(16).app.boldFont, textColor: UIColor.app.themeLight(.black, dark: .white))
        view.addSubview(themeLabel)

        let themeButton = UIButton()
        themeButton.frame = CGRect(x: 0, y: 510, width: APP.screenWidth, height: 50)
        themeButton.titleLabel?.font = APP.font(16)
        themeButton.setTitleColor(UIColor.app.themeLight(.black, dark: .white), for: .normal)

        let buttonImage = UIImage.app.themeLight(ThemeManager.shared.style == .light ? nil : ModuleBundle.imageNamed("themeImageLight"), dark: ThemeManager.shared.style == .dark ? nil : ModuleBundle.imageNamed("themeImageDark"))
        let themeString = NSAttributedString.app.themeObject(htmlString: "我是<span style='color:red;'>红色</span>AttributedString", defaultAttributes: [
            .font: APP.font(16, .bold),
            .foregroundColor: UIColor.app.themeLight(.black, dark: .white)
        ])

        themeButton.setImage(buttonImage.app.image, for: .normal)
        themeButton.setAttributedTitle(themeString.object, for: .normal)
        themeLabel.app.addThemeListener { _ in
            themeButton.setImage(buttonImage.app.image, for: .normal)
            themeButton.setAttributedTitle(themeString.object, for: .normal)
        }
        view.addSubview(themeButton)
    }
}
