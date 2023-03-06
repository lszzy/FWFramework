//
//  TestDrawerController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/28.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestDrawerController: UIViewController, ViewControllerProtocol, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    private lazy var contentView: UIView = {
        let result = UIView()
        result.frame = CGRect(x: -FW.screenWidth / 2.0, y: 0, width: FW.screenWidth / 2.0, height: view.fw.height)
        result.backgroundColor = .brown
        return result
    }()
    
    private lazy var bottomView: UIView = {
        let result = UIView()
        result.isHidden = true
        result.frame = CGRect(x: 0, y: 100, width: FW.screenWidth, height: view.fw.height)
        result.backgroundColor = .brown
        return result
    }()
    
    private lazy var imageView: UIImageView = {
        let result = UIImageView()
        result.contentMode = .scaleAspectFit
        return result
    }()
    
    func didInitialize() {
        fw.extendedLayoutEdge = .top
        fw.navigationBarStyle = .transparent
    }
    
    override var shouldPopController: Bool {
        let drawerView = contentView.fw.drawerView
        drawerView?.setPosition(drawerView?.openPosition ?? 0, animated: true)
        return false
    }
    
    func setupNavbar() {
        fw.setLeftBarItem(FW.iconImage("zmdi-var-menu", 24)) { [weak self] _ in
            guard let drawerView = self?.contentView.fw.drawerView else { return }
            let position = drawerView.position == drawerView.openPosition ? drawerView.closePosition : drawerView.openPosition
            drawerView.setPosition(position, animated: true)
        }
        
        fw.addRightBarItem("相册", target: self, action: #selector(self.onPhotoSheet(_:)))
    }
    
    func setupSubviews() {
        view.backgroundColor = AppTheme.tableColor
        
        let topLabel = UILabel(frame: CGRect(x: 50, y: 200, width: 100, height: 30))
        topLabel.text = "Menu 1"
        contentView.addSubview(topLabel)
        topLabel.isUserInteractionEnabled = true
        topLabel.fw.addTapGesture { [weak self] _ in
            guard let self = self else { return }
            self.bottomView.isHidden = false
            self.bottomView.fw.drawerView?.setPosition(100, animated: true)
        }
        
        let middleLabel = UILabel(frame: CGRect(x: 50, y: 250, width: 100, height: 30))
        middleLabel.text = "Menu 2"
        contentView.addSubview(middleLabel)
        middleLabel.isUserInteractionEnabled = true
        middleLabel.fw.addTapGesture { [weak self] _ in
            guard let self = self else { return }
            self.bottomView.isHidden = false
            self.bottomView.fw.drawerView?.setPosition(self.view.fw.height / 2.0, animated: true)
        }
        
        let bottomLabel = UILabel(frame: CGRect(x: 50, y: 300, width: 100, height: 30))
        bottomLabel.text = "Menu 3"
        contentView.addSubview(bottomLabel)
        bottomLabel.isUserInteractionEnabled = true
        bottomLabel.fw.addTapGesture { [weak self] _ in
            guard let self = self else { return }
            self.bottomView.isHidden = false
            self.bottomView.fw.drawerView?.setPosition(self.view.fw.height - 100.0, animated: true)
        }
        
        let closeLabel = UILabel(frame: CGRect(x: 50, y: 400, width: 100, height: 30))
        closeLabel.text = "Back"
        closeLabel.isUserInteractionEnabled = true
        closeLabel.fw.addTapGesture { [weak self] _ in
            self?.fw.close()
        }
        contentView.addSubview(closeLabel)
        view.addSubview(contentView)
        
        contentView.fw.drawerView(
            .right,
            positions: [NSNumber(value: -FW.screenWidth / 2.0), NSNumber(value: 0)],
            kickbackHeight: 25
        )
        
        view.addSubview(imageView)
        imageView.fw.layoutChain
            .center()
            .size(CGSize(width: 200, height: 200))
        
        view.addSubview(bottomView)
        
        bottomView.fw.drawerView(
            .up,
            positions: [NSNumber(value: 100), NSNumber(value: view.fw.height / 2.0), NSNumber(value: view.fw.height - 100.0)],
            kickbackHeight: 0
        )
    }
    
    @objc func onPhotoSheet(_ sender: UIBarButtonItem) {
        fw.showSheet(title: nil, message: nil, cancel: "取消", actions: ["拍照", "选取相册"]) { [weak self] index in
            if index == 0 {
                if !UIImagePickerController.isSourceTypeAvailable(.camera) {
                    self?.fw.showAlert(title: "未检测到您的摄像头", message: nil)
                    return
                }
                
                self?.fw.showImageCamera(allowsEditing: true, completion: { image, cancel in
                    self?.onPickerResult(image, cancelled: cancel)
                })
            } else {
                self?.fw.showImagePicker(allowsEditing: true) { image, cancel in
                    self?.onPickerResult(image, cancelled: cancel)
                }
            }
        }
    }
    
    func onPickerResult(_ image: UIImage?, cancelled: Bool) {
        imageView.image = cancelled ? nil : image
        guard let cgImage = imageView.image?.cgImage else { return }
        
        if #available(iOS 13.0, *) {
            UIWindow.fw.showLoading()
            Detector.recognizeText(in: cgImage) { request in
                request.recognitionLanguages = ["zh-CN", "en-US"]
                request.usesLanguageCorrection = true
            } completion: { results in
                UIWindow.fw.hideLoading()
                let string = NSMutableString()
                for result in results {
                    string.appendFormat("text: %@\nconfidence: %@\n", result.text, NSNumber(value: result.confidence))
                }
                let message = string.length > 0 ? string.copy() : "识别结果为空"
                UIWindow.fw.main?.fw.showAlert(title: "扫描结果", message: message)
            }
        }
    }
    
}
