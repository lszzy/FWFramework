//
//  TestQrcodeController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/27.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestQrcodeController: UIViewController, ViewControllerProtocol {
    
    private var flashlightSelected = false
    
    private var scanManager: QrcodeScanManager?
    
    private lazy var scanView: QrcodeScanView = {
        let result = QrcodeScanView(frame: CGRect(x: 0, y: 0, width: APP.screenWidth, height: APP.screenHeight))
        result.scanImage = ModuleBundle.imageNamed("qrcodeLine")
        return result
    }()
    
    private lazy var flashlightBtn: UIButton = {
        let result = UIButton(type: .custom)
        let btnW: CGFloat = 30
        let btnH: CGFloat = 30
        let btnX: CGFloat = 0.5 * (view.frame.width - btnW)
        let btnY: CGFloat = 0.5 * APP.screenHeight + 0.35 * view.frame.width - btnH - 25
        result.frame = CGRect(x: btnX, y: btnY, width: btnW, height: btnH)
        result.setBackgroundImage(ModuleBundle.imageNamed("qrcodeFlashlightOpen"), for: .normal)
        result.setBackgroundImage(ModuleBundle.imageNamed("qrcodeFlashlightClose"), for: .selected)
        result.addTarget(self, action: #selector(toggleFlashlightBtn(_:)), for: .touchUpInside)
        return result
    }()
    
    private lazy var promptLabel: UILabel = {
        let labelY = 0.5 * APP.screenHeight + 0.35 * view.frame.width + 12
        let result = UILabel(frame: CGRect(x: 0, y: labelY, width: APP.screenWidth, height: 20))
        result.font = UIFont.systemFont(ofSize: 13)
        result.textColor = .white
        result.textAlignment = .center
        result.text = "将二维码/条码放入框内, 即可自动扫描"
        return result
    }()
    
    func setupNavbar() {
        let appearance = NavigationBarAppearance()
        appearance.foregroundColor = .white
        appearance.backgroundTransparent = true
        appearance.leftBackImage = Icon.backImage
        app.navigationBarAppearance = appearance
        app.extendedLayoutEdge = .top
        
        navigationItem.title = "扫一扫"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "相册", style: .done, target: self, action: #selector(TestQrcodeController.onPhotoLibrary))
    }
    
    func setupSubviews() {
        #if !targetEnvironment(simulator)
        setupScanManager()
        #endif
        view.backgroundColor = .black
        view.addSubview(scanView)
        view.addSubview(promptLabel)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startScanManager()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopScanManager()
    }
    
    deinit {
        removeScanView()
    }
    
    func setupScanManager() {
        let scanManager = QrcodeScanManager()
        self.scanManager = scanManager
        scanManager.sampleBufferDelegate = true
        scanManager.scanQrcode(view: view)
        
        scanManager.scanResultBlock = { [weak self] result in
            guard let result = result else { return }
            if let sound = ModuleBundle.resourcePath("Qrcode.caf") {
                UIApplication.app.playSystemSound(sound)
            }
            self?.stopScanManager()
            self?.onScanResult(result)
        }
        scanManager.scanBrightnessBlock = { [weak self] brightness in
            guard let self = self else { return }
            if brightness < -1 {
                self.view.addSubview(self.flashlightBtn)
            } else {
                if !self.flashlightSelected {
                    self.removeFlashlightBtn()
                }
            }
        }
    }
    
    func startScanManager() {
        scanManager?.startRunning()
        scanView.addTimer()
    }
    
    func stopScanManager() {
        scanView.removeTimer()
        removeFlashlightBtn()
        scanManager?.stopRunning()
    }
    
    @objc func toggleFlashlightBtn(_ button: UIButton) {
        if !button.isSelected {
            QrcodeScanManager.openFlashlight()
            
            flashlightSelected = true
            button.isSelected = true
        } else {
            removeFlashlightBtn()
        }
    }
    
    @objc func removeFlashlightBtn() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            QrcodeScanManager.closeFlashlight()
            
            self?.flashlightSelected = false
            self?.flashlightBtn.isSelected = false
            self?.flashlightBtn.removeFromSuperview()
        }
    }
    
    @objc func removeScanView() {
        scanView.removeTimer()
        scanView.removeFromSuperview()
    }
    
    @objc func onPhotoLibrary() {
        stopScanManager()
        
        app.showImagePicker(filterType: .image, selectionLimit: 1, allowsEditing: false) { [weak self] imagePicker in
            guard let imagePicker = imagePicker as? UIViewController else { return }
            imagePicker.app.presentationDidDismiss = {
                self?.startScanManager()
            }
        } completion: { [weak self] objects, results, cancel in
            if cancel {
                self?.startScanManager()
            } else {
                var image = objects.first as? UIImage
                image = image?.app.compressImage(maxWidth: 1200)
                image = image?.app.compressImage(maxLength: 300 * 1024)
                if let image = image,
                   let result = QrcodeScanManager.scanQrcode(image: image) {
                    self?.onScanResult(result)
                } else {
                    self?.app.showMessage(text: "识别失败")
                    self?.startScanManager()
                }
            }
        }
    }
    
    func onScanResult(_ result: String) {
        app.showAlert(title: "扫描结果", message: result, cancel: nil) { [weak self] in
            self?.startScanManager()
        }
    }
    
}
