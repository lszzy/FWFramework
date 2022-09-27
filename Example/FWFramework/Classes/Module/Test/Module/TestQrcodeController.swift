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
    
    private lazy var scanManager: QrcodeScanManager = {
        let result = QrcodeScanManager()
        result.sampleBufferDelegate = true
        result.scanResultBlock = { [weak self] result in
            guard let result = result else { return }
            if let sound = ModuleBundle.resourcePath("Qrcode.caf") {
                UIApplication.fw.playSystemSound(sound)
            }
            self?.stopScanManager()
            self?.onScanResult(result)
        }
        result.scanBrightnessBlock = { [weak self] brightness in
            guard let self = self else { return }
            if brightness < -1 {
                self.view.addSubview(self.flashlightBtn)
            } else {
                if !self.flashlightSelected {
                    self.removeFlashlightBtn()
                }
            }
        }
        return result
    }()
    
    private lazy var scanView: QrcodeScanView = {
        let result = QrcodeScanView(frame: CGRect(x: 0, y: 0, width: FW.screenWidth, height: FW.screenHeight))
        result.scanImageName = ModuleBundle.imageNamed("qrcodeLine")
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
        AuthorizeManager.manager(type: .camera)?.authorize({ [weak self] status in
            guard let self = self else { return }
            if status != .authorized {
                self.fw.showAlert(title: status == .restricted ? "未检测到您的摄像头" : "未打开摄像头权限", message: nil)
            } else {
                self.setupScanManager()
                self.view.addSubview(self.scanView)
                self.view.addSubview(self.promptLabel)
                
                // 由于异步授权，viewWillAppear时可能未完成，此处调用start
                self.startScanManager()
            }
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.startScanManager()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.stopScanManager()
    }
    
    deinit {
        removeScanView()
    }
    
    func setupScanManager() {
        scanManager.scanQrcode(with: view)
    }
    
    func startScanManager() {
        scanManager.startRunning()
        scanView.addTimer()
    }
    
    func stopScanManager() {
        scanView.removeTimer()
        removeFlashlightBtn()
        scanManager.stopRunning()
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
                if let image = image,
                   let result = QrcodeScanManager.scanQrcode(with: image) {
                    self?.onScanResult(result)
                }
            }
        }
    }
    
    func onScanResult(_ result: String) {
        fw.showAlert(title: "扫描结果", message: result, cancel: nil) { [weak self] in
            self?.startScanManager()
        }
    }
    
}
