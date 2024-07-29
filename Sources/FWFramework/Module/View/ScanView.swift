//
//  ScanView.swift
//  Pods
//
//  Created by wuyong on 2023/8/23.
//

import UIKit
import AVFoundation
#if canImport(Vision)
import Vision
#endif

// MARK: - ScanCode
public protocol ScanCodeDelegate: AnyObject {
    
    /// 扫描二维码结果函数
    ///
    /// - Parameters:
    ///   - scanCode: FWScanCode 对象
    ///   - result: 扫描二维码数据
    func scanCode(_ scanCode: ScanCode, result: String?)
    
}

public protocol ScanCodeSampleBufferDelegate: AnyObject {
    
    /// 扫描时捕获外界光线强弱函数
    ///
    /// - Parameters:
    ///   - scanCode: FWScanCode 对象
    ///   - brightness: 光线强弱值
    func scanCode(_ scanCode: ScanCode, brightness: CGFloat)
    
}

/// 二维码、条形码扫描，默认仅开启二维码
///
/// 不建议同时开启二维码和条形码，因为开启后条形码很难识别且只有中心位置可识别。
/// 默认二维码类型示例：[.qr]
/// 默认条形码类型示例：[.code39, .code39Mod43, .code93, .code128, .ean8, .ean13, .upce, .interleaved2of5]
///
/// [SGQRCode](https://github.com/kingsic/SGQRCode)
open class ScanCode: NSObject, AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    
    // MARK: - Accessor
    /// 默认二维码类型，可自定义
    nonisolated(unsafe) public static var metadataObjectTypesQRCode: [AVMetadataObject.ObjectType] = [.qr]
    
    /// 默认条形码类型，可自定义
    nonisolated(unsafe) public static var metadataObjectTypesBarcode: [AVMetadataObject.ObjectType] = [
        .code39, .code39Mod43, .code93, .code128, .ean8, .ean13, .upce, .interleaved2of5
    ]
    
    /// 预览视图，必须设置（传外界控制器视图）
    @MainActor open var preview: UIView? {
        didSet {
            preview?.layer.insertSublayer(videoPreviewLayer, at: 0)
        }
    }

    /// 扫描区域，以屏幕右上角为坐标原点，取值范围：0～1，默认为整个屏幕
    open var rectOfInterest: CGRect = .zero {
        didSet {
            metadataOutput.rectOfInterest = rectOfInterest
        }
    }

    /// 视频缩放因子，默认同系统（捕获内容）
    open var videoZoomFactor: CGFloat {
        get {
            return device?.videoZoomFactor ?? 0
        }
        set {
            guard let device = device else { return }
            
            let factor = min(max(device.minAvailableVideoZoomFactor, newValue), device.maxAvailableVideoZoomFactor)
            do {
                try device.lockForConfiguration()
                device.videoZoomFactor = factor
                device.unlockForConfiguration()
            } catch { }
        }
    }

    /// 扫描二维码数据代理
    open weak var delegate: ScanCodeDelegate? {
        didSet {
            setupMetadataOutput()
        }
    }

    /// 采样缓冲区代理
    open weak var sampleBufferDelegate: ScanCodeSampleBufferDelegate? {
        didSet {
            setupVideoDataOutput()
        }
    }

    /// 扫描二维码回调句柄
    open var scanResultBlock: ((String?) -> Void)? {
        didSet {
            setupMetadataOutput()
        }
    }

    /// 扫描二维码光线强弱回调句柄
    open var scanBrightnessBlock: ((CGFloat) -> Void)? {
        didSet {
            setupVideoDataOutput()
        }
    }
    
    /// 元对象类型，默认仅开启二维码
    open lazy var metadataObjectTypes: [AVMetadataObject.ObjectType] = {
        return ScanCode.metadataObjectTypesQRCode
    }() {
        didSet {
            setupMetadataObjectTypes()
        }
    }
    
    /// 会话预制，默认自动设置
    open lazy var sessionPreset: AVCaptureSession.Preset = {
        guard let device = device else { return .low }
        var presets: [AVCaptureSession.Preset] = [
            .hd4K3840x2160, .hd1920x1080, .hd1280x720,
            .vga640x480, .cif352x288, .high, .medium,
        ]
        for preset in presets {
            if device.supportsSessionPreset(preset) {
                return preset
            }
        }
        return .low
    }() {
        didSet {
            session.sessionPreset = sessionPreset
        }
    }
    
    private lazy var session: AVCaptureSession = {
        let result = AVCaptureSession()
        result.sessionPreset = sessionPreset
        return result
    }()
    
    private lazy var device: AVCaptureDevice? = {
        let result = AVCaptureDevice.default(for: .video)
        return result
    }()
    
    private lazy var deviceInput: AVCaptureDeviceInput? = {
        guard let device = device else { return nil }
        let result = try? AVCaptureDeviceInput(device: device)
        return result
    }()
    
    private lazy var metadataOutput: AVCaptureMetadataOutput = {
        let result = AVCaptureMetadataOutput()
        result.setMetadataObjectsDelegate(self, queue: .main)
        return result
    }()
    
    private lazy var videoDataOutput: AVCaptureVideoDataOutput = {
        let result = AVCaptureVideoDataOutput()
        result.setSampleBufferDelegate(self, queue: .main)
        return result
    }()
    
    @MainActor private lazy var videoPreviewLayer: AVCaptureVideoPreviewLayer = {
        let result = AVCaptureVideoPreviewLayer(session: session)
        result.videoGravity = .resizeAspectFill
        result.frame = preview?.frame ?? .zero
        return result
    }()
    
    private var issetMetadataOutput = false
    private var issetVideoDataOutput = false
    
    // MARK: - Lifecycle
    public override init() {
        super.init()
        
        if let deviceInput = deviceInput,
           session.canAddInput(deviceInput) {
            session.addInput(deviceInput)
        }
    }
    
    #if DEBUG
    deinit {
        Logger.debug(group: Logger.fw.moduleName, "%@ deinit", NSStringFromClass(type(of: self)))
    }
    #endif
    
    private func setupMetadataOutput() {
        guard !issetMetadataOutput else { return }
        issetMetadataOutput = true
        
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
        }
        
        setupMetadataObjectTypes()
    }
    
    private func setupVideoDataOutput() {
        guard !issetVideoDataOutput else { return }
        issetVideoDataOutput = true
        
        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
        }
    }
    
    private func setupMetadataObjectTypes() {
        guard issetMetadataOutput else { return }
        
        var objectTypes: [AVMetadataObject.ObjectType] = []
        for objectType in metadataObjectTypes {
            if metadataOutput.availableMetadataObjectTypes.contains(objectType) {
                objectTypes.append(objectType)
            }
        }
        metadataOutput.metadataObjectTypes = objectTypes
    }

    // MARK: - Public
    /// 配置扫描设备，比如自动聚焦等
    open func configCaptureDevice(_ block: ((AVCaptureDevice) -> Void)?) {
        guard let device = device else { return }
        
        do {
            try device.lockForConfiguration()
            block?(device)
            device.unlockForConfiguration()
        } catch { }
    }

    /// 开启扫描
    open func startRunning() {
        DispatchQueue.global().async {
            #if !targetEnvironment(simulator)
            if !self.session.isRunning {
                self.session.startRunning()
            }
            #endif
        }
    }

    /// 停止扫描
    open func stopRunning() {
        #if !targetEnvironment(simulator)
        if session.isRunning {
            session.stopRunning()
        }
        #endif
    }
    
    // MARK: - AVCaptureMetadataOutputObjectsDelegate
    open func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard metadataObjects.count > 0 else { return }
        let obj = metadataObjects[0] as? AVMetadataMachineReadableCodeObject
        let resultString = obj?.stringValue
        
        delegate?.scanCode(self, result: resultString)
        scanResultBlock?(resultString)
    }
                                  
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    open func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let metadataDict = CMCopyDictionaryOfAttachments(allocator: nil, target: sampleBuffer, attachmentMode: kCMAttachmentMode_ShouldPropagate) else { return }
        let metadata = metadataDict as NSDictionary
        if let exifMetadata = metadata[kCGImagePropertyExifDictionary as String] as? NSDictionary,
           let brightnessValue = exifMetadata[kCGImagePropertyExifBrightnessValue as String] as? NSNumber {
            let brightness = brightnessValue.doubleValue
            
            sampleBufferDelegate?.scanCode(self, brightness: brightness)
            scanBrightnessBlock?(brightness)
        }
    }

    // MARK: - Torch
    /// 手电筒是否已激活
    open class func isTorchActive() -> Bool {
        guard let device = AVCaptureDevice.default(for: .video) else { return false }
        return device.hasTorch && device.isTorchActive
    }

    /// 打开手电筒
    open class func turnOnTorch() {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else { return }
        
        do {
            try device.lockForConfiguration()
            device.torchMode = .on
            device.unlockForConfiguration()
        } catch { }
    }

    /// 关闭手电筒
    open class func turnOffTorch() {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else { return }
        
        do {
            try device.lockForConfiguration()
            device.torchMode = .off
            device.unlockForConfiguration()
        } catch { }
    }

    /// 检测后置摄像头是否可用
    @MainActor open class func isCameraRearAvailable() -> Bool {
        return UIImagePickerController.isCameraDeviceAvailable(.rear)
    }

    /// 播放音效
    open class func playSoundEffect(_ file: String) {
        UIApplication.fw.playSystemSound(file)
    }

    // MARK: - Read
    /// 读取图片中的二维码，主线程回调
    ///
    /// - Parameters:
    ///   - image: 图片
    ///   - compress: 是否按默认算法压缩图片，默认true，图片过大可能导致闪退，建议开启
    ///   - completion: 回调方法，读取成功时，回调参数 result 等于二维码数据，否则等于 nil
    open class func readQRCode(_ image: UIImage?, compress: Bool = true, completion: @escaping @MainActor @Sendable (String?) -> Void) {
        DispatchQueue.global().async {
            var compressImage = image
            if compress, compressImage != nil {
                compressImage = compressImage?.fw.compressImage(maxWidth: 1080)
                compressImage = compressImage?.fw.compressImage(maxLength: 512 * 1024)
            }
            
            var ciImage = compressImage?.ciImage
            if ciImage == nil, let cgImage = compressImage?.cgImage {
                ciImage = CIImage(cgImage: cgImage)
            }
            guard let ciImage = ciImage else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
            let features = detector?.features(in: ciImage) ?? []
            var messageString: String?
            for feature in features {
                if let qrcodeFeature = feature as? CIQRCodeFeature {
                    messageString = qrcodeFeature.messageString
                    break
                }
            }
            
            let resultString = messageString
            DispatchQueue.main.async {
                completion(resultString)
            }
        }
    }
    
    /// 读取图片中的条形码/二维码，主线程回调
    ///
    /// - Parameters:
    ///   - image: 图片
    ///   - compress: 是否按默认算法压缩图片，默认true，图片过大可能导致闪退，建议开启
    ///   - completion: 回调方法，读取成功时，回调参数 result 等于条形码/二维码数据，否则等于 nil
    open class func readBarcode(_ image: UIImage?, compress: Bool = true, completion: @escaping @MainActor @Sendable (String?) -> Void) {
        DispatchQueue.global().async {
            var compressImage = image
            if compress, compressImage != nil {
                compressImage = compressImage?.fw.compressImage(maxWidth: 1080)
                compressImage = compressImage?.fw.compressImage(maxLength: 512 * 1024)
            }
            
            guard let cgImage = compressImage?.cgImage else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            let request = VNDetectBarcodesRequest() { request, error in
                var messageString: String?
                let results = request.results ?? []
                for result in results {
                    if let barcode = result as? VNBarcodeObservation,
                       let value = barcode.payloadStringValue {
                        messageString = value
                        break
                    }
                }
                
                let resultString = messageString
                DispatchQueue.main.async {
                    completion(resultString)
                }
            }
           
            let handler = VNImageRequestHandler(cgImage: cgImage)
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }

    // MARK: - Generate
    /// 生成二维码
    ///
    /// - Parameters:
    ///   - data: 二维码数据
    ///   - size: 二维码大小
    ///   - color: 二维码颜色，默认黑色
    ///   - backgroundColor: 二维码背景颜色，默认白色
    /// - Returns: 二维码图片
    open class func generateQrcode(
        data: String,
        size: CGFloat,
        color: UIColor = .black,
        backgroundColor: UIColor = .white
    ) -> UIImage? {
        let stringData = data.data(using: .utf8)
        // 1、二维码滤镜
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter?.setValue(stringData, forKey: "inputMessage")
        filter?.setValue("H", forKey: "inputCorrectionLevel")
        let ciImage = filter?.outputImage
        // 2、颜色滤镜
        let colorFilter = CIFilter(name: "CIFalseColor")
        colorFilter?.setValue(ciImage, forKey: "inputImage")
        colorFilter?.setValue(CIColor(cgColor: color.cgColor), forKey: "inputColor0")
        colorFilter?.setValue(CIColor(cgColor: backgroundColor.cgColor), forKey: "inputColor1")
        // 3、生成处理
        guard var outImage = colorFilter?.outputImage else { return nil }
        let outWidth = outImage.extent.size.width
        let scale: CGFloat = outWidth > 0 ? (size / outWidth) : 1
        outImage = outImage.transformed(by: .init(scaleX: scale, y: scale))
        return UIImage(ciImage: outImage)
    }
    
    /// 生成带 logo 的二维码
    ///
    /// - Parameters:
    ///   - data: 二维码数据
    ///   - size: 二维码大小
    ///   - logoImage: logo
    ///   - ratio: logo 相对二维码的比例，默认0.25（取值范围 0.0 ～ 1.0f）
    ///   - logoImageCornerRadius: logo 外边框圆角，默认5
    ///   - logoImageBorderWidth: logo 外边框宽度，默认5
    ///   - logoImageBorderColor: logo 外边框颜色，默认白色
    /// - Returns: 二维码图片
    open class func generateQrcode(
        data: String,
        size: CGFloat,
        logoImage: UIImage?,
        ratio: CGFloat = 0.25,
        logoImageCornerRadius: CGFloat = 5,
        logoImageBorderWidth: CGFloat = 5,
        logoImageBorderColor: UIColor? = .white
    ) -> UIImage? {
        let image = generateQrcode(data: data, size: size, color: .black, backgroundColor: .white)
        guard let image = image,
              let logoImage = logoImage else { return image }
        
        let logoImageW = max(0, min(ratio, 1.0)) * size
        let logoImageH = logoImageW
        let logoImageX = 0.5 * (image.size.width - logoImageW)
        let logoImageY = 0.5 * (image.size.height - logoImageH)
        let logoImageRect = CGRect(x: logoImageX, y: logoImageY, width: logoImageW, height: logoImageH)
        
        // 绘制logo
        UIGraphicsBeginImageContextWithOptions(image.size, false, 0.0)
        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        let path = UIBezierPath(roundedRect: logoImageRect, cornerRadius: logoImageCornerRadius)
        path.lineWidth = logoImageBorderWidth
        logoImageBorderColor?.setStroke()
        path.stroke()
        path.addClip()
        logoImage.draw(in: logoImageRect)
        
        let qrcodeImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return qrcodeImage
    }
    
    /// 生成code128条形码，无空白区域
    ///
    /// - Parameters:
    ///   - data: 二维码数据
    ///   - size: 二维码大小
    ///   - color: 二维码颜色，默认黑色
    ///   - backgroundColor: 二维码背景颜色，默认白色
    /// - Returns: 条形码图片
    open class func generateBarcode(
        data: String,
        size: CGSize,
        color: UIColor = .black,
        backgroundColor: UIColor = .white
    ) -> UIImage? {
        let stringData = data.data(using: .utf8)
        // 1、二维码滤镜
        let filter = CIFilter(name: "CICode128BarcodeGenerator")
        filter?.setValue(stringData, forKey: "inputMessage")
        filter?.setValue(NSNumber(value: 0), forKey: "inputQuietSpace")
        let ciImage = filter?.outputImage
        // 2、颜色滤镜
        let colorFilter = CIFilter(name: "CIFalseColor")
        colorFilter?.setValue(ciImage, forKey: "inputImage")
        colorFilter?.setValue(CIColor(cgColor: color.cgColor), forKey: "inputColor0")
        colorFilter?.setValue(CIColor(cgColor: backgroundColor.cgColor), forKey: "inputColor1")
        // 3、生成处理
        guard var outImage = colorFilter?.outputImage else { return nil }
        let outSize = outImage.extent.size
        let scaleX: CGFloat = outSize.width > 0 ? (size.width / outSize.width) : 1
        let scaleY: CGFloat = outSize.height > 0 ? (size.height / outSize.height) : 1
        outImage = outImage.transformed(by: .init(scaleX: scaleX, y: scaleY))
        return UIImage(ciImage: outImage)
    }
    
}

// MARK: - ScanView
/// 扫码边角位置枚举
public enum ScanCornerLoaction: Int, Sendable {
    /// 默认与边框线同中心点
    case `default` = 0
    /// 在边框线内部
    case inside
    /// 在边框线外部
    case outside
}

/// 扫码视图配置
open class ScanViewConfiguration: NSObject {
    /// 扫描线，默认为：nil
    open var scanline: String?

    /// 扫描线图片，默认为：nil
    open var scanlineImage: UIImage?

    /// 扫描线每次移动的步长，默认为：3.5f
    open var scanlineStep: CGFloat = 3.5

    /// 扫描线是否执行逆动画，默认为：NO
    open var autoreverses: Bool = false

    /// 扫描线是否从扫描框顶部开始扫描，默认为：NO
    open var isFromTop: Bool = false

    /// 背景色，默认为：[[UIColor blackColor] colorWithAlphaComponent:0.5]
    open var color: UIColor = UIColor.black.withAlphaComponent(0.5)

    /// 是否需要辅助扫描框，默认为：NO
    open var isShowBorder: Bool = false

    /// 辅助扫描框的颜色，默认为：[UIColor whiteColor]
    open var borderColor: UIColor = UIColor.white

    /// 辅助扫描框的宽度，默认为：0.2f
    open var borderWidth: CGFloat = 0.2

    /// 辅助扫描边角位置，默认为：default
    open var cornerLocation: ScanCornerLoaction = .default

    /// 辅助扫描边角颜色，默认为：[UIColor greenColor]
    open var cornerColor: UIColor = UIColor.green

    /// 辅助扫描边角宽度，默认为：2.0f
    open var cornerWidth: CGFloat = 2.0

    /// 辅助扫描边角长度，默认为：20.0f
    open var cornerLength: CGFloat = 20.0
}

/// 扫码视图
open class ScanView: UIView {
    
    private class Proxy: NSObject {
        weak var target: ScanView?
        
        init(target: ScanView?) {
            super.init()
            self.target = target
        }
        
        @MainActor @objc func updateUI() {
            target?.updateUI()
        }
    }
    
    // MARK: - Accessor
    /// 当前配置
    open private(set) var configuration: ScanViewConfiguration = .init()

    /// 辅助扫描边框区域的frame
    ///
    /// 默认x为：0.5 * (self.frame.size.width - w)
    /// 默认y为：0.5 * (self.frame.size.height - w)
    /// 默认width和height为：0.7 * self.frame.size.width
    open var borderFrame: CGRect = .zero

    /// 扫描区域的frame
    open var scanFrame: CGRect = .zero {
        didSet {
            contentView.frame = scanFrame
            if scanlineImgView.image != nil {
                updateScanLineFrame()
            }
        }
    }

    /// 双击回调方法
    open var doubleTapBlock: ((Bool) -> Void)? {
        didSet {
            tapGesture.isEnabled = doubleTapBlock != nil
        }
    }
    
    /// 缩放回调方法，0表示开始
    open var pinchScaleBlock: ((CGFloat) -> Void)? {
        didSet {
            pinchGesture.isEnabled = pinchScaleBlock != nil
        }
    }
    
    private lazy var contentView: UIView = {
        let result = UIView(frame: scanFrame)
        result.backgroundColor = .clear
        result.clipsToBounds = true
        return result
    }()
    
    private var scanlineImgView: UIImageView {
        get {
            if let imgView = _scanlineImgView {
                return imgView
            }
            
            let imgView = UIImageView()
            _scanlineImgView = imgView
            
            var image: UIImage?
            if configuration.scanlineImage != nil {
                image = configuration.scanlineImage
            } else if let scanline = configuration.scanline {
                image = UIImage(named: scanline)
            }
            imgView.image = image
            
            if image != nil {
                updateScanLineFrame()
            }
            return imgView
        }
        set {
            _scanlineImgView = newValue
        }
    }
    private var _scanlineImgView: UIImageView?
    
    private lazy var tapGesture: UITapGestureRecognizer = {
        let result = UITapGestureRecognizer(target: self, action: #selector(doubleTapAction))
        result.numberOfTapsRequired = 2
        result.isEnabled = false
        return result
    }()
    
    private lazy var pinchGesture: UIPinchGestureRecognizer = {
        let result = UIPinchGestureRecognizer(target: self, action: #selector(pinchAction(_:)))
        result.isEnabled = false
        return result
    }()
    
    nonisolated(unsafe) private var displayLink: CADisplayLink?
    private var isTop = true
    private var isSelected = false
    
    // MARK: - Lifecycle
    /// 对象方法创建 ScanView
    ///
    /// - Parameters:
    ///   - frame: ScanView 的 frame
    ///   - configuration: ScanView 的配置
    public init(frame: CGRect, configuration: ScanViewConfiguration) {
        super.init(frame: frame)
        
        self.configuration = configuration
        didInitialize()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        didInitialize()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        didInitialize()
    }
    
    private func didInitialize() {
        let width = 0.7 * frame.size.width
        borderFrame = CGRect(x: 0.5 * (frame.width - width), y: 0.5 * (frame.height - width), width: width, height: width)
        scanFrame = borderFrame
        
        backgroundColor = .clear
        addSubview(contentView)
        
        addGestureRecognizer(tapGesture)
        addGestureRecognizer(pinchGesture)
    }
    
    deinit {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    open override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard configuration.isShowBorder else { return }

        /// 边框 frame
        let borderW = borderFrame.size.width
        let borderH = borderFrame.size.height
        let borderX = borderFrame.origin.x
        let borderY = borderFrame.origin.y
        let borderLineW = configuration.borderWidth

        /// 空白区域设置
        configuration.color.setFill()
        UIRectFill(rect)
        // 获取上下文，并设置混合模式 -> kCGBlendModeDestinationOut
        let context = UIGraphicsGetCurrentContext()
        context?.setBlendMode(.destinationOut)
        // 设置空白区
        let bezierPath = UIBezierPath(rect: CGRect(x: borderX + 0.5 * borderLineW, y: borderY + 0.5 * borderLineW, width: borderW - borderLineW, height: borderH - borderLineW))
        bezierPath.fill()
        // 执行混合模式
        context?.setBlendMode(.normal)

        /// 边框设置
        let borderPath = UIBezierPath(rect: CGRect(x: borderX, y: borderY, width: borderW, height: borderH))
        borderPath.lineCapStyle = .butt
        borderPath.lineWidth = borderLineW
        configuration.borderColor.set()
        borderPath.stroke()

        let cornerLength = configuration.cornerLength
        let insideExcess = abs(0.5 * (configuration.cornerWidth - borderLineW))
        let outsideExcess = 0.5 * (borderLineW + configuration.cornerWidth)

        /// 绘制四个角小图标
        drawLeftTop(borderX: borderX, borderY: borderY, cornerLength: cornerLength, insideExcess: insideExcess, outsideExcess: outsideExcess)
        drawLeftBottom(borderX: borderX, borderY: borderY, borderH: borderH, cornerLength: cornerLength, insideExcess: insideExcess, outsideExcess: outsideExcess)
        drawRightTop(borderX: borderX, borderY: borderY, borderW: borderW, cornerLength: cornerLength, insideExcess: insideExcess, outsideExcess: outsideExcess)
        drawRightBottom(borderX: borderX, borderY: borderY, borderW: borderW, borderH: borderH, cornerLength: cornerLength, insideExcess: insideExcess, outsideExcess: outsideExcess)
    }

    // MARK: - Public
    /// 开始扫描
    open func startScanning() {
        guard scanlineImgView.image != nil else { return }
        
        contentView.addSubview(scanlineImgView)
        if displayLink == nil {
            displayLink = CADisplayLink(target: Proxy(target: self), selector: #selector(Proxy.updateUI))
            displayLink?.add(to: .main, forMode: .common)
        }
    }

    /// 停止扫描
    open func stopScanning() {
        guard
            scanlineImgView.image != nil,
            displayLink != nil
        else {
            return
        }
        
        scanlineImgView.removeFromSuperview()
        _scanlineImgView = nil
        displayLink?.invalidate()
        displayLink = nil
    }
    
    // MARK: - Private
    private func updateScanLineFrame() {
        let w = contentView.frame.width
        let imageSize = scanlineImgView.image?.size ?? .zero
        let h = imageSize.width > 0 ? (w * imageSize.height) / imageSize.width : 0
        let x: CGFloat = 0
        let y = configuration.isFromTop ? -h : 0
        scanlineImgView.frame = CGRect(x: x, y: y, width: w, height: h)
    }
    
    private func updateUI() {
        var frame = scanlineImgView.frame
        let contentViewHeight = contentView.frame.height
        let scanlineY = scanlineImgView.frame.origin.y + (configuration.isFromTop ? 0 : scanlineImgView.frame.size.height)

        if configuration.autoreverses {
            if isTop {
                frame.origin.y += configuration.scanlineStep
                scanlineImgView.frame = frame

                if contentViewHeight <= scanlineY {
                    isTop = false
                }
            } else {
                frame.origin.y -= configuration.scanlineStep
                scanlineImgView.frame = frame

                if scanlineY <= scanlineImgView.frame.size.height {
                    isTop = true
                }
            }
        } else {
            if contentViewHeight <= scanlineY {
                let scanlineH = scanlineImgView.frame.size.height
                frame.origin.y = -scanlineH + (configuration.isFromTop ? 0 : scanlineH)
                scanlineImgView.frame = frame
            } else {
                frame.origin.y += configuration.scanlineStep
                scanlineImgView.frame = frame
            }
        }
    }
    
    private func drawLeftTop(borderX: CGFloat, borderY: CGFloat, cornerLength: CGFloat, insideExcess: CGFloat, outsideExcess: CGFloat) {
        let leftTopPath = UIBezierPath()
        leftTopPath.lineWidth = configuration.cornerWidth
        configuration.cornerColor.set()

        if configuration.cornerLocation == .inside {
            leftTopPath.move(to: CGPoint(x: borderX + insideExcess, y: borderY + cornerLength + insideExcess))
            leftTopPath.addLine(to: CGPoint(x: borderX + insideExcess, y: borderY + insideExcess))
            leftTopPath.addLine(to: CGPoint(x: borderX + cornerLength + insideExcess, y: borderY + insideExcess))
        } else if configuration.cornerLocation == .outside {
            leftTopPath.move(to: CGPoint(x: borderX - outsideExcess, y: borderY + cornerLength - outsideExcess))
            leftTopPath.addLine(to: CGPoint(x: borderX - outsideExcess, y: borderY - outsideExcess))
            leftTopPath.addLine(to: CGPoint(x: borderX + cornerLength - outsideExcess, y: borderY - outsideExcess))
        } else {
            leftTopPath.move(to: CGPoint(x: borderX, y: borderY + cornerLength))
            leftTopPath.addLine(to: CGPoint(x: borderX, y: borderY))
            leftTopPath.addLine(to: CGPoint(x: borderX + cornerLength, y: borderY))
        }

        leftTopPath.stroke()
    }

    private func drawRightTop(borderX: CGFloat, borderY: CGFloat, borderW: CGFloat, cornerLength: CGFloat, insideExcess: CGFloat, outsideExcess: CGFloat) {
        let rightTopPath = UIBezierPath()
        rightTopPath.lineWidth = configuration.cornerWidth
        configuration.cornerColor.set()

        if configuration.cornerLocation == .inside {
            rightTopPath.move(to: CGPoint(x: borderX + borderW - cornerLength - insideExcess, y: borderY + insideExcess))
            rightTopPath.addLine(to: CGPoint(x: borderX + borderW - insideExcess, y: borderY + insideExcess))
            rightTopPath.addLine(to: CGPoint(x: borderX + borderW - insideExcess, y: borderY + cornerLength + insideExcess))
        } else if configuration.cornerLocation == .outside {
            rightTopPath.move(to: CGPoint(x: borderX + borderW - cornerLength + outsideExcess, y: borderY - outsideExcess))
            rightTopPath.addLine(to: CGPoint(x: borderX + borderW + outsideExcess, y: borderY - outsideExcess))
            rightTopPath.addLine(to: CGPoint(x: borderX + borderW + outsideExcess, y: borderY + cornerLength - outsideExcess))
        } else {
            rightTopPath.move(to: CGPoint(x: borderX + borderW - cornerLength, y: borderY))
            rightTopPath.addLine(to: CGPoint(x: borderX + borderW, y: borderY))
            rightTopPath.addLine(to: CGPoint(x: borderX + borderW, y: borderY + cornerLength))
        }

        rightTopPath.stroke()
    }
    
    private func drawLeftBottom(borderX: CGFloat, borderY: CGFloat, borderH: CGFloat, cornerLength: CGFloat, insideExcess: CGFloat, outsideExcess: CGFloat) {
        let leftBottomPath = UIBezierPath()
        leftBottomPath.lineWidth = configuration.cornerWidth
        configuration.cornerColor.set()

        if configuration.cornerLocation == .inside {
            leftBottomPath.move(to: CGPoint(x: borderX + cornerLength + insideExcess, y: borderY + borderH - insideExcess))
            leftBottomPath.addLine(to: CGPoint(x: borderX + insideExcess, y: borderY + borderH - insideExcess))
            leftBottomPath.addLine(to: CGPoint(x: borderX + insideExcess, y: borderY + borderH - cornerLength - insideExcess))
        } else if configuration.cornerLocation == .outside {
            leftBottomPath.move(to: CGPoint(x: borderX + cornerLength - outsideExcess, y: borderY + borderH + outsideExcess))
            leftBottomPath.addLine(to: CGPoint(x: borderX - outsideExcess, y: borderY + borderH + outsideExcess))
            leftBottomPath.addLine(to: CGPoint(x: borderX - outsideExcess, y: borderY + borderH - cornerLength + outsideExcess))
        } else {
            leftBottomPath.move(to: CGPoint(x: borderX + cornerLength, y: borderY + borderH))
            leftBottomPath.addLine(to: CGPoint(x: borderX, y: borderY + borderH))
            leftBottomPath.addLine(to: CGPoint(x: borderX, y: borderY + borderH - cornerLength))
        }

        leftBottomPath.stroke()
    }

    private func drawRightBottom(borderX: CGFloat, borderY: CGFloat, borderW: CGFloat, borderH: CGFloat, cornerLength: CGFloat, insideExcess: CGFloat, outsideExcess: CGFloat) {
        let rightBottomPath = UIBezierPath()
        rightBottomPath.lineWidth = configuration.cornerWidth
        configuration.cornerColor.set()

        if configuration.cornerLocation == .inside {
            rightBottomPath.move(to: CGPoint(x: borderX + borderW - insideExcess, y: borderY + borderH - cornerLength - insideExcess))
            rightBottomPath.addLine(to: CGPoint(x: borderX + borderW - insideExcess, y: borderY + borderH - insideExcess))
            rightBottomPath.addLine(to: CGPoint(x: borderX + borderW - cornerLength - insideExcess, y: borderY + borderH - insideExcess))
        } else if configuration.cornerLocation == .outside {
            rightBottomPath.move(to: CGPoint(x: borderX + borderW + outsideExcess, y: borderY + borderH - cornerLength + outsideExcess))
            rightBottomPath.addLine(to: CGPoint(x: borderX + borderW + outsideExcess, y: borderY + borderH + outsideExcess))
            rightBottomPath.addLine(to: CGPoint(x: borderX + borderW - cornerLength + outsideExcess, y: borderY + borderH + outsideExcess))
        } else {
            rightBottomPath.move(to: CGPoint(x: borderX + borderW, y: borderY + borderH - cornerLength))
            rightBottomPath.addLine(to: CGPoint(x: borderX + borderW, y: borderY + borderH))
            rightBottomPath.addLine(to: CGPoint(x: borderX + borderW - cornerLength, y: borderY + borderH))
        }

        rightBottomPath.stroke()
    }

    
    @objc private func doubleTapAction() {
        isSelected = !isSelected
        doubleTapBlock?(isSelected)
    }
    
    @objc private func pinchAction(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .began {
            pinchScaleBlock?(0)
        } else if gesture.state == .changed {
            pinchScaleBlock?(gesture.scale)
        }
    }
    
}
