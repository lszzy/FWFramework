//
//  TestSegmentController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/29.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestSegmentController: UIViewController, ViewControllerProtocol, UIScrollViewDelegate {
    
    private lazy var tagCollectionView: TextTagCollectionView = {
        let result = TextTagCollectionView()
        result.verticalSpacing = 5
        result.horizontalSpacing = 5
        return result
    }()
    
    private var textTagConfig: TextTagConfig {
        let result = TextTagConfig()
        result.textFont = UIFont.systemFont(ofSize: 10)
        result.textColor = AppTheme.textColor
        result.selectedTextColor = AppTheme.textColor
        result.backgroundColor = AppTheme.cellColor
        result.selectedBackgroundColor = AppTheme.cellColor
        result.cornerRadius = 2
        result.selectedCornerRadius = 2
        result.borderWidth = 1
        result.selectedBorderWidth = 1
        result.borderColor = UIColor.fw.color(hex: 0xF3B2AF)
        result.extraSpace = CGSize(width: 10, height: 6)
        result.enableGradientBackground = false
        return result
    }
    
    private lazy var scrollView: UIScrollView = {
        let result = UIScrollView()
        result.isPagingEnabled = true
        result.showsHorizontalScrollIndicator = false
        result.delegate = self
        return result
    }()
    
    private lazy var segmentedControl: SegmentedControl = {
        let result = SegmentedControl(sectionTitles: [])
        result.backgroundColor = AppTheme.cellColor
        result.selectionStyle = .box
        result.selectionIndicatorBoxCornerRadius = 12
        result.selectionIndicatorBoxEdgeInsets = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        result.contentEdgeInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        result.segmentEdgeInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        result.segmentWidthStyle = .dynamic
        result.selectionIndicatorLocation = .none
        result.selectionIndicatorCornerRadius = 2.5
        result.titleTextAttributes = [
            NSAttributedString.Key.font: UIFont.fw.font(ofSize: 14),
            NSAttributedString.Key.foregroundColor: AppTheme.textColor,
        ]
        result.selectedTitleTextAttributes = [
            NSAttributedString.Key.font: UIFont.fw.font(ofSize: 14, weight: .bold),
            NSAttributedString.Key.foregroundColor: AppTheme.textColor,
        ]
        result.segmentCustomBlock = { segmentedControl, index, rect in
            if index == 1, segmentedControl.selectedSegmentIndex != 1 {
                let layer = CAShapeLayer()
                let path = UIBezierPath()
                path.addArc(withCenter: CGPoint(x: rect.maxX - 8, y: rect.minY + 8 + 4), radius: 4, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: false)
                layer.fillColor = UIColor.red.cgColor
                layer.path = path.cgPath
                segmentedControl.scrollView.layer.addSublayer(layer)
            }
        }
        return result
    }()
    
    private lazy var gifImageView: UIImageView = {
        let result = UIImageView()
        result.contentMode = .scaleAspectFill
        result.layer.masksToBounds = true
        result.isUserInteractionEnabled = true
        return result
    }()
    
    func setupNavbar() {
        fw.setRightBarItem("Save") { [weak self] _ in
            self?.gifImageView.image?.fw.saveImage()
        }
    }
    
    func setupSubviews() {
        view.addSubview(gifImageView)
        gifImageView.fw.layoutChain
            .edges(toSafeArea: .zero, excludingEdge: .bottom)
            .height(100)
        
        let progressView = ProgressView()
        progressView.color = AppTheme.textColor
        gifImageView.addSubview(progressView)
        progressView.fw.layoutChain.center().size(CGSize(width: 40, height: 40))
        
        let gifImageUrl = "http://ww2.sinaimg.cn/bmiddle/642beb18gw1ep3629gfm0g206o050b2a.gif"
        progressView.progress = 0
        progressView.isHidden = false
        gifImageView.fw.setImage(url: gifImageUrl, placeholderImage: nil, options: .ignoreCache, context: nil) { [weak self] image, error in
            progressView.isHidden = true
            if let image = image {
                self?.gifImageView.image = image
            }
        } progress: { progress in
            progressView.progress = progress
        }
        
        let activitySize = CGSize(width: 30, height: 30)
        let activityView = UIActivityIndicatorView(style: .gray)
        activityView.color = AppTheme.textColor
        activityView.size = activitySize
        activityView.startAnimating()
        view.addSubview(activityView)
        activityView.fw.layoutChain
            .centerX()
            .top(toViewBottom: gifImageView, offset: 10)
            .size(activitySize)
        
        let textLabel = UILabel.fw.label(font: UIFont.fw.font(ofSize: 15), textColor: AppTheme.textColor)
        textLabel.numberOfLines = 0
        textLabel.textAlignment = .center
        view.addSubview(textLabel)
        textLabel.fw.layoutChain.centerX()
            .top(toViewBottom: activityView, offset: 10)
        
        let attrStr = NSMutableAttributedString()
        var attrFont = FW.font(16, .light)
        attrStr.append(NSAttributedString.fw.attributedString("细体16 ", font: attrFont))
        attrFont = FW.font(16, .regular)
        attrStr.append(NSAttributedString.fw.attributedString("常规16 ", font: attrFont))
        attrFont = FW.font(16, .bold)
        attrStr.append(NSAttributedString.fw.attributedString("粗体16 ", font: attrFont))
        attrFont = UIFont.italicSystemFont(ofSize: 16)
        attrStr.append(NSAttributedString.fw.attributedString("斜体16 ", font: attrFont))
        attrFont = UIFont.italicSystemFont(ofSize: 16).fw.boldFont
        attrStr.append(NSAttributedString.fw.attributedString("粗斜体16 ", font: attrFont))
        
        attrFont = UIFont.fw.font(ofSize: 16, weight: .light)
        attrStr.append(NSAttributedString.fw.attributedString("\n细体16 ", font: attrFont))
        attrFont = UIFont.fw.font(ofSize: 16, weight: .regular)
        attrStr.append(NSAttributedString.fw.attributedString("常规16 ", font: attrFont))
        attrFont = UIFont.fw.font(ofSize: 16, weight: .bold)
        attrStr.append(NSAttributedString.fw.attributedString("粗体16 ", font: attrFont))
        attrFont = UIFont.fw.font(ofSize: 16).fw.italicFont
        attrStr.append(NSAttributedString.fw.attributedString("斜体16 ", font: attrFont))
        attrFont = UIFont.fw.font(ofSize: 16, weight: .bold).fw.italicFont.fw.nonBoldFont.fw.boldFont.fw.nonItalicFont.fw.italicFont
        attrStr.append(NSAttributedString.fw.attributedString("粗斜体16 ", font: attrFont))
        textLabel.attributedText = attrStr
        
        let label = AttributedLabel()
        label.backgroundColor = AppTheme.cellColor
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = AppTheme.textColor
        label.textAlignment = .center
        view.addSubview(label)
        label.fw.layoutChain
            .horizontal()
            .top(toViewBottom: textLabel, offset: 10)
            .height(30)
        
        label.appendText("文本 ")
        let labelView = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        labelView.backgroundColor = .red
        labelView.fw.setCornerRadius(15)
        label.append(labelView, margin: .zero, alignment: .center)
        label.appendText(" ")
        if let image = UIImage.fw.image(color: .blue, size: CGSize(width: 30, height: 30)) {
            label.append(image, maxSize: image.size, margin: .zero, alignment: .center)
        }
        label.appendText(" 结束")
        
        view.addSubview(tagCollectionView)
        tagCollectionView.fw.layoutChain
            .horizontal(10)
            .top(toViewBottom: label, offset: 10)
        
        tagCollectionView.removeAllTags()
        let testTags = ["80减12", "首单减15", "在线支付", "支持自提", "26减3", "80减12", "首单减15", "在线支付", "支持自提", "26减3"]
        for tagName in testTags {
            tagCollectionView.addTag(tagName, with: textTagConfig)
        }
        
        let marqueeLabel = MarqueeLabel.fw.label(font: UIFont.fw.font(ofSize: 16), textColor: AppTheme.textColor, text: "FWMarqueeLabel 会在添加到界面上后，并且文字超过 label 宽度时自动滚动")
        view.addSubview(marqueeLabel)
        marqueeLabel.fw.layoutChain
            .horizontal(10)
            .top(toViewBottom: tagCollectionView, offset: 10)
            .height(20)
        marqueeLabel.setNeedsLayout()
        marqueeLabel.layoutIfNeeded()
        
        let sectionTitles = ["菜单一", "菜单二", "长的菜单三", "菜单四", "菜单五", "菜单六"]
        let sectionContents = ["我是内容一", "我是内容二", "我是长的内容三", "我是内容四", "我是内容五", "我是内容六"]
        view.addSubview(segmentedControl)
        segmentedControl.fw.layoutChain
            .horizontal()
            .top(toViewBottom: marqueeLabel, offset: 10)
            .height(40)
        segmentedControl.sectionTitles = sectionTitles
        segmentedControl.selectedSegmentIndex = 5
        segmentedControl.indexChangeBlock = { [weak self] index in
            self?.scrollView.scrollRectToVisible(CGRect(x: FW.screenWidth * CGFloat(index), y: 0, width: FW.screenWidth, height: 100), animated: true)
        }
        
        scrollView.contentSize = CGSizeMake(FW.screenWidth * CGFloat(sectionTitles.count), 100)
        scrollView.scrollRectToVisible(CGRect(x: FW.screenWidth * CGFloat(segmentedControl.selectedSegmentIndex), y: 0, width: FW.screenWidth, height: 100), animated: false)
        view.addSubview(scrollView)
        scrollView.fw.layoutChain
            .horizontal()
            .top(toViewBottom: segmentedControl)
            .height(100)
        
        for i in 0 ..< sectionContents.count {
            let label = UILabel(frame: CGRectMake(FW.screenWidth * CGFloat(i), 0, FW.screenWidth, 100))
            label.text = sectionContents[i]
            label.numberOfLines = 0
            scrollView.addSubview(label)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page = UInt(scrollView.contentOffset.x / scrollView.frame.size.width)
        segmentedControl.setSelectedSegmentIndex(page, animated: true)
    }
    
}
