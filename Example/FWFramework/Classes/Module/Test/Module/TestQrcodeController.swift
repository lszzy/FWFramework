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
    
    private lazy var scanCode: ScanCode = {
        let result = ScanCode()
        return result
    }()
    
    private lazy var scanView: ScanView = {
        let configure = ScanViewConfigure()
        configure.scanlineImage = ModuleBundle.imageNamed("qrcodeLine")
        
        let result = ScanView(frame: CGRect(x: 0, y: 0, width: FW.screenWidth, height: FW.screenHeight), configure: configure)
        result.doubleTapBlock = { [weak self] selected in
            self?.scanCode.videoZoomFactor = selected ? 4.0 : 1.0
        }
        return result
    }()
    
    private lazy var flashlightBtn: UIButton = {
        let result = UIButton(type: .custom)
        let btnW: CGFloat = 30
        let btnH: CGFloat = 30
        let btnX: CGFloat = 0.5 * (view.frame.width - btnW)
        let btnY: CGFloat = 0.5 * FW.screenHeight + 0.35 * view.frame.width - btnH - 25
        result.frame = CGRect(x: btnX, y: btnY, width: btnW, height: btnH)
        result.setBackgroundImage(ModuleBundle.imageNamed("qrcodeFlashlightOpen"), for: .normal)
        result.setBackgroundImage(ModuleBundle.imageNamed("qrcodeFlashlightClose"), for: .selected)
        result.addTarget(self, action: #selector(toggleFlashlightBtn(_:)), for: .touchUpInside)
        return result
    }()
    
    private lazy var promptLabel: UILabel = {
        let labelY = 0.5 * FW.screenHeight + 0.35 * view.frame.width + 12
        let result = UILabel(frame: CGRect(x: 0, y: labelY, width: FW.screenWidth, height: 20))
        result.font = UIFont.systemFont(ofSize: 13)
        result.textColor = AppTheme.textColor
        result.textAlignment = .center
        result.text = "将二维码/条码放入框内, 即可自动扫描"
        return result
    }()
    
    func setupNavbar() {
        fw.navigationBarStyle = .transparent
        fw.extendedLayoutEdge = .top
        navigationItem.title = "扫一扫"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "相册", style: .done, target: self, action: #selector(TestQrcodeController.onPhotoLibrary))
    }
    
    func setupSubviews() {
        view.backgroundColor = .black
        view.addSubview(scanView)
        view.addSubview(promptLabel)
        
        setupScanManager()
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
        guard ScanCode.isCameraRearAvailable() else { return }
        
        scanCode.scanResultBlock = { [weak self] result in
            if result != nil,
               let sound = ModuleBundle.resourcePath("Qrcode.caf") {
                ScanCode.playSoundEffect(sound)
            }
            
            self?.stopScanManager()
            self?.onScanResult(result)
        }
        scanCode.scanBrightnessBlock = { [weak self] brightness in
            guard let self = self else { return }
            if brightness < -1 {
                self.view.addSubview(self.flashlightBtn)
            } else {
                if !self.flashlightSelected {
                    self.removeFlashlightBtn()
                }
            }
        }
        scanCode.preview = view
    }
    
    func startScanManager() {
        scanCode.startRunning()
        scanView.startScanning()
    }
    
    func stopScanManager() {
        scanCode.stopRunning()
        scanView.stopScanning()
        removeFlashlightBtn()
    }
    
    @objc func toggleFlashlightBtn(_ button: UIButton) {
        if !button.isSelected {
            ScanCode.turnOnTorch()
            
            flashlightSelected = true
            button.isSelected = true
        } else {
            removeFlashlightBtn()
        }
    }
    
    @objc func removeFlashlightBtn() {
        ScanCode.turnOffTorch()
        
        flashlightSelected = false
        flashlightBtn.isSelected = false
        flashlightBtn.removeFromSuperview()
    }
    
    @objc func removeScanView() {
        scanView.stopScanning()
        scanView.removeFromSuperview()
    }
    
    @objc func onPhotoLibrary() {
        stopScanManager()
        
        fw.showImagePicker(filterType: .image, selectionLimit: 1, allowsEditing: false) { [weak self] imagePicker in
            guard let imagePicker = imagePicker as? UIViewController else { return }
            imagePicker.fw.presentationDidDismiss = {
                self?.startScanManager()
            }
        } completion: { [weak self] objects, results, cancel in
            if cancel {
                self?.startScanManager()
            } else {
                var image = objects.first as? UIImage
                image = image?.fw.compressImage(maxWidth: 1200)
                image = image?.fw.compressImage(maxLength: 300 * 1024)
                if let image = image {
                    ScanCode.readQRCode(image) { result in
                        self?.onScanResult(result)
                    }
                } else {
                    self?.startScanManager()
                }
            }
        }
    }
    
    func onScanResult(_ result: String?) {
        fw.showAlert(title: "扫描结果", message: result ?? "失败", cancel: nil) { [weak self] in
            self?.startScanManager()
        }
    }
    
}
