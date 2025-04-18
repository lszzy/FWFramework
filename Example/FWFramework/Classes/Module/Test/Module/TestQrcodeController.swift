//
//  TestQrcodeController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/27.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestQrcodeController: UIViewController, ViewControllerProtocol {
    private let scanCode = ScanCode()
    private var currentZoomFactor: CGFloat = 1.0

    private lazy var scanView: ScanView = {
        let configuration = ScanViewConfiguration()
        configuration.scanlineImage = ModuleBundle.imageNamed("qrcodeLine")

        let result = ScanView(frame: CGRect(x: 0, y: 0, width: APP.screenWidth, height: APP.screenHeight), configuration: configuration)
        result.scanFrame = CGRect(x: 0, y: 0.18 * APP.screenHeight, width: APP.screenWidth, height: 0.54 * APP.screenHeight)
        result.doubleTapBlock = { [weak self] selected in
            self?.scanCode.videoZoomFactor = selected ? 4.0 : 1.0
        }
        result.pinchScaleBlock = { [weak self] scale in
            guard let self else { return }

            if scale <= 0 {
                currentZoomFactor = scanCode.videoZoomFactor
            } else {
                scanCode.videoZoomFactor = currentZoomFactor * scale
            }
        }
        return result
    }()

    private lazy var flashlightBtn: UIButton = {
        let result = UIButton(type: .custom)
        result.isHidden = true
        result.frame = CGRect(x: (APP.screenWidth - 30) / 2, y: scanView.scanFrame.maxY + 30, width: 30, height: 30)
        result.setBackgroundImage(ModuleBundle.imageNamed("qrcodeFlashlightOpen"), for: .normal)
        result.setBackgroundImage(ModuleBundle.imageNamed("qrcodeFlashlightClose"), for: .selected)
        result.app.addTouch { [weak self] _ in
            self?.toggleFlashlightBtn()
        }
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
        app.setRightBarItem(UIBarButtonItem.SystemItem.action.rawValue) { [weak self] _ in
            self?.app.showSheet(title: nil, message: nil, actions: ["相册二维码", "相册条形码", "扫描二维码", "扫描条形码", "同时扫描", "生成二维码", "生成条形码"], actionBlock: { index in
                if index == 0 {
                    self?.onPhotoLibrary(false)
                } else if index == 1 {
                    self?.onPhotoLibrary(true)
                } else if index == 2 {
                    self?.scanCode.metadataObjectTypes = ScanCode.metadataObjectTypesQRCode
                } else if index == 3 {
                    self?.scanCode.metadataObjectTypes = ScanCode.metadataObjectTypesBarcode
                } else if index == 4 {
                    self?.scanCode.metadataObjectTypes = ScanCode.metadataObjectTypesQRCode + ScanCode.metadataObjectTypesBarcode
                } else if index == 5 {
                    self?.onGenerateCode(false)
                } else if index == 6 {
                    self?.onGenerateCode(true)
                }
            })
        }
    }

    func setupSubviews() {
        view.backgroundColor = .black
        view.addSubview(scanView)
        view.addSubview(flashlightBtn)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
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

    func setupScanManager() {
        scanCode.stopWhenScanned = true
        scanCode.scanResultBlock = { [weak self] result in
            if result != nil, let sound = ModuleBundle.resourcePath("Qrcode.caf") {
                ScanCode.playSoundEffect(sound)
            }

            DispatchQueue.app.mainAsync { [weak self] in
                self?.stopScanManager()
                self?.onScanResult(result)
            }
        }
        scanCode.scanBrightnessBlock = { [weak self] brightness in
            if brightness < -1 {
                DispatchQueue.app.mainAsync { [weak self] in
                    self?.flashlightBtn.isHidden = false
                }
            } else {
                if !ScanCode.isTorchActive() {
                    DispatchQueue.app.mainAsync { [weak self] in
                        self?.removeFlashlightBtn()
                    }
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

    func toggleFlashlightBtn() {
        if !flashlightBtn.isSelected {
            flashlightBtn.isSelected = true

            ScanCode.turnOnTorch()
        } else {
            removeFlashlightBtn()
        }
    }

    func removeFlashlightBtn() {
        ScanCode.turnOffTorch()

        flashlightBtn.isSelected = false
        flashlightBtn.isHidden = true
    }

    func onPhotoLibrary(_ isBarcode: Bool = false) {
        stopScanManager()

        app.showImagePicker(filterType: .image, selectionLimit: 1, allowsEditing: false) { [weak self] imagePicker in
            guard let imagePicker = imagePicker as? UIViewController else { return }
            imagePicker.app.presentationDidDismiss = {
                self?.startScanManager()
            }
        } completion: { [weak self] objects, _, cancel in
            if cancel {
                self?.startScanManager()
            } else {
                if !isBarcode {
                    self?.app.showLoading(text: "识别中...")
                    ScanCode.readQRCode(objects.first as? UIImage) { result in
                        self?.app.hideLoading()

                        self?.onScanResult(result)
                    }
                } else {
                    self?.app.showLoading(text: "识别中...")
                    ScanCode.readBarcode(objects.first as? UIImage) { result in
                        self?.app.hideLoading()

                        self?.onScanResult(result)
                    }
                }
            }
        }
    }

    func onGenerateCode(_ isBarcode: Bool = false) {
        stopScanManager()

        app.showPrompt(title: nil, message: "Please input code", cancel: nil, confirm: nil, promptBlock: nil) { [weak self] value in
            guard !value.isEmpty else {
                self?.startScanManager()
                return
            }

            var image: UIImage?
            if isBarcode {
                image = ScanCode.generateBarcode(data: value, size: CGSize(width: 355, height: 105))
                image = image?.app.image(insets: UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10), color: UIColor.white)
            } else {
                image = ScanCode.generateQrcode(data: value, size: 375)
            }
            guard let image else {
                self?.startScanManager()
                return
            }

            self?.app.showImagePreview(imageURLs: [image], imageInfos: nil, currentIndex: 0, sourceView: nil)
        } cancelBlock: { [weak self] in
            self?.startScanManager()
        }
    }

    func onScanResult(_ result: String?) {
        if let result {
            app.showAlert(title: "扫描结果", message: result, cancel: nil) { [weak self] in
                self?.startScanManager()
            }
        } else {
            app.showMessage(text: "识别失败")
            startScanManager()
        }
    }
}
