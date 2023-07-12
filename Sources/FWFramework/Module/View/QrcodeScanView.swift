//
//  QrcodeScanView.swift
//  Pods
//
//  Created by wuyong on 2023/7/12.
//

import UIKit
import AVFoundation

// MARK: - QrcodeScanManager
/// 扫码管理器
///
/// [SGQRCode](https://github.com/kingsic/SGQRCode)
open class QrcodeScanManager: NSObject, AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    // MARK: - Accessor
    /// 会话预置，默认为：AVCaptureSessionPreset1920x1080
    open var sessionPreset: AVCaptureSession.Preset = .hd1920x1080
    /// 元对象类型，默认为：AVMetadataObjectTypeQRCode
    open var metadataObjectTypes: [AVMetadataObject.ObjectType] = [.qr]
    /// 扫描范围，默认整个视图（每一个取值 0 ～ 1，以屏幕右上角为坐标原点）
    open var rectOfInterest: CGRect = .zero
    /// 是否需要样本缓冲代理（光线强弱），默认为：NO
    open var sampleBufferDelegate: Bool = false
    /// 扫描二维码回调方法
    open var scanResultBlock: ((String?) -> Void)?
    /// 扫描二维码光线强弱回调方法；调用之前配置属性 sampleBufferDelegate 必须为 YES
    open var scanBrightnessBlock: ((CGFloat) -> Void)?
    
    private lazy var captureSession: AVCaptureSession = {
        let result = AVCaptureSession()
        return result
    }()
    
    // MARK: - Public
    /// 创建扫描二维码方法
    @discardableResult
    open func scanQrcode(view: UIView) -> Bool {
        guard let device = AVCaptureDevice.default(for: .video) else {
            return false
        }
        
        // 1、捕获设备输入流
        let deviceInput = try? AVCaptureDeviceInput(device: device)
        // 2、捕获元数据输出流
        let metadataOutput = AVCaptureMetadataOutput()
        metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
        
        // 设置扫描范围（每一个取值 0 ～ 1，以屏幕右上角为坐标原点）
        // 注：微信二维码的扫描范围是整个屏幕，这里并没有做处理（可不用设置）
        if rectOfInterest != .zero {
            metadataOutput.rectOfInterest = rectOfInterest
        }
        
        // 3、设置会话采集率
        captureSession.sessionPreset = sessionPreset
        
        // 4(1)、添加捕获元数据输出流到会话对象
        captureSession.addOutput(metadataOutput)
        // 4(2)、添加捕获输出流到会话对象；构成识了别光线强弱
        if sampleBufferDelegate {
            let videoDataOutput = AVCaptureVideoDataOutput()
            videoDataOutput.setSampleBufferDelegate(self, queue: .main)
            captureSession.addOutput(videoDataOutput)
        }
        // 4(3)、添加捕获设备输入流到会话对象
        if let deviceInput = deviceInput {
            captureSession.addInput(deviceInput)
        }
        
        // 5、设置数据输出类型，需要将数据输出添加到会话后，才能指定元数据类型，否则会报错
        var objectTypes: [AVMetadataObject.ObjectType] = []
        for objectType in metadataObjectTypes {
            if metadataOutput.availableMetadataObjectTypes.contains(objectType) {
                objectTypes.append(objectType)
            }
        }
        metadataOutput.metadataObjectTypes = objectTypes
        
        // 6、预览图层
        let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        // 保持纵横比，填充层边界
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.frame = view.frame
        view.layer.insertSublayer(videoPreviewLayer, at: 0)
        return true
    }
    
    /// 开启扫描回调方法
    open func startRunning() {
        DispatchQueue.global().async { [weak self] in
            guard let captureSession = self?.captureSession else { return }
            if !captureSession.isRunning {
                captureSession.startRunning()
            }
        }
    }
    
    /// 停止扫描方法
    open func stopRunning() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }
    
    /// 打开手电筒
    @discardableResult
    public static func openFlashlight() -> Bool {
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            return false
        }
        
        if captureDevice.hasTorch {
            do {
                try captureDevice.lockForConfiguration()
                captureDevice.torchMode = .on
                captureDevice.unlockForConfiguration()
                
                return true
            } catch {
                return false
            }
        }
        return false
    }
    
    /// 关闭手电筒
    @discardableResult
    public static func closeFlashlight() -> Bool {
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            return false
        }
        
        if captureDevice.hasTorch {
            do {
                try captureDevice.lockForConfiguration()
                captureDevice.torchMode = .off
                captureDevice.unlockForConfiguration()
                
                return true
            } catch {
                return false
            }
        }
        return false
    }
    
    /// 配置扫描设备，比如自动聚焦等
    public static func configCaptureDevice(_ block: (AVCaptureDevice) -> Void) {
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        
        do {
            try captureDevice.lockForConfiguration()
            block(captureDevice)
            captureDevice.unlockForConfiguration()
        } catch { }
    }
    
    /// 扫描图片二维码，识别失败返回nil。图片过大可能导致闪退，建议先压缩再识别
    public static func scanQrcode(image: UIImage) -> String? {
        // 创建 CIDetector，并设定识别类型：CIDetectorTypeQRCode
        guard let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]) else {
            return nil
        }
        
        // 识别结果为空
        guard let ciImage = CIImage(image: image) else {
            return nil
        }
        let features = detector.features(in: ciImage)
        if features.count < 1 {
            return nil
        }
        
        // 获取识别结果
        var qrcodeString: String?
        for feature in features {
            if let qrcodeFeature = feature as? CIQRCodeFeature {
                qrcodeString = qrcodeFeature.messageString
            }
        }
        return qrcodeString
    }
    
    /// 生成二维码
    /// - Parameters:
    ///   - data: 二维码数据
    ///   - size: 二维码大小
    ///   - color: 二维码颜色，默认黑色
    ///   - backgroundColor: 二维码背景颜色，默认白色
    /// - Returns: 二维码图片
    public static func generateQrcode(
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
        let scale: CGFloat = outWidth > 0 ? (size / outWidth) : 0
        outImage = outImage.transformed(by: .init(scaleX: scale, y: scale))
        return UIImage(ciImage: outImage)
    }
    
    /// 生成带 logo 的二维码
    /// - Parameters:
    ///   - data: 二维码数据
    ///   - size: 二维码大小
    ///   - logoImage: logo
    ///   - ratio: logo 相对二维码的比例，默认0.25（取值范围 0.0 ～ 1.0f）
    ///   - logoImageCornerRadius: logo 外边框圆角，默认5
    ///   - logoImageBorderWidth: logo 外边框宽度，默认5
    ///   - logoImageBorderColor: logo 外边框颜色，默认白色
    /// - Returns: 二维码图片
    public static func generateQrcode(
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
        UIGraphicsBeginImageContextWithOptions(image.size, false, UIScreen.main.scale)
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
    
    // MARK: - AVCaptureMetadataOutputObjectsDelegate
    open func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard metadataObjects.count > 0 else { return }
        
        let obj = metadataObjects[0] as? AVMetadataMachineReadableCodeObject
        scanResultBlock?(obj?.stringValue)
    }
                                  
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    open func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let metadataDict = CMCopyDictionaryOfAttachments(allocator: nil, target: sampleBuffer, attachmentMode: kCMAttachmentMode_ShouldPropagate) else { return }
        let metadata = metadataDict as NSDictionary
        if let exifMetadata = metadata[kCGImagePropertyExifDictionary as String] as? NSDictionary,
           let brightnessValue = exifMetadata[kCGImagePropertyExifBrightnessValue as String] as? NSNumber {
            scanBrightnessBlock?(brightnessValue.doubleValue)
        }
    }
    
}

// MARK: - QrcodeScanView
/// 扫码边角位置枚举
public enum QrcodeCornerLocation: Int {
    /// 默认与边框线同中心点
    case `default` = 0
    /// 在边框线内部
    case inside
    /// 在边框线外部
    case outside
}

/// 扫码动画样式枚举
public enum QrcodeScanAnimationStyle: Int {
    /// 单线扫描样式
    case `default` = 0
    /// 网格扫描样式
    case grid
}

/// 扫码视图
open class QrcodeScanView: UIView {
    
    // MARK: - Accessor
    /// 扫描样式，默认 default
    open var scanAnimationStyle: QrcodeScanAnimationStyle = .default
    /// 扫描线名，支持NSString和UIImage，默认无
    open var scanImage: Any?
    /// 边框颜色，默认白色
    open var borderColor: UIColor = .white
    /// 边框frame，默认视图宽度*0.7，居中
    open var borderFrame: CGRect = .zero
    /// 边框宽度，默认0.2f
    open var borderWidth: CGFloat = 0.2
    /// 边角位置，默认 default
    open var cornerLocation: QrcodeCornerLocation = .default
    /// 边角颜色，默认微信颜色
    open var cornerColor: UIColor = UIColor(red: 85.0 / 255.0, green: 183.0 / 255.0, blue: 55.0 / 255.0, alpha: 1.0)
    /// 边角宽度，默认 2.f
    open var cornerWidth: CGFloat = 2.0
    /// 边角长度，默认20.f
    open var cornerLength: CGFloat = 20
    /// 扫描区周边颜色的 alpha 值，默认 0.5f
    open var backgroundAlpha: CGFloat = 0.5
    /// 扫描线动画时间，默认 0.02s
    open var animationTimeInterval: CGFloat = 0.02
    
    private var timer: Timer?
    private static var animationFlag: Bool = true
    
    // MARK: - Subviews
    private lazy var contentView: UIView = {
        let result = UIView()
        result.frame = borderFrame
        result.clipsToBounds = true
        result.backgroundColor = .clear
        return result
    }()
    
    private lazy var scanningLine: UIImageView = {
        let result = UIImageView()
        if let image = scanImage as? UIImage {
            result.image = image
        } else if let imageName = scanImage as? String {
            result.image = UIImage(named: imageName)
        } else {
            result.image = nil
        }
        return result
    }()
    
    // MARK: - Lifecycle
    public override init(frame: CGRect) {
        super.init(frame: frame)
        didInitialize()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        didInitialize()
    }
    
    private func didInitialize() {
        backgroundColor = .clear
        borderFrame = CGRect(x: 0.15 * frame.size.width, y: 0.5 * (frame.size.height - 0.7 * frame.size.width), width: 0.7 * frame.size.width, height: 0.7 * frame.size.width)
    }
    
    open override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        /// 边框 frame
        let borderW = borderFrame.size.width
        let borderH = borderFrame.size.height
        let borderX = borderFrame.origin.x
        let borderY = borderFrame.origin.y
        
        /// 空白区域设置
        UIColor.black.withAlphaComponent(backgroundAlpha).setFill()
        UIRectFill(rect)
        // 获取上下文，并设置混合模式 -> kCGBlendModeDestinationOut
        let context = UIGraphicsGetCurrentContext()
        context?.setBlendMode(.destinationOut)
        // 设置空白区
        let bezierPath = UIBezierPath(rect: CGRect(x: borderX + 0.5 * borderWidth, y: borderY + 0.5 * borderWidth, width: borderW - borderWidth, height: borderH - borderWidth))
        bezierPath.fill()
        // 执行混合模式
        context?.setBlendMode(.normal)
        
        /// 边框设置
        let borderPath = UIBezierPath(rect: CGRect(x: borderX, y: borderY, width: borderW, height: borderH))
        borderPath.lineCapStyle = .butt
        borderPath.lineWidth = borderWidth
        borderColor.set()
        borderPath.stroke()
        
        /// 左上角小图标
        let leftTopPath = UIBezierPath()
        leftTopPath.lineWidth = cornerWidth
        cornerColor.set()
        
        let insideExcess = abs(0.5 * (cornerWidth - borderWidth))
        let outsideExcess = 0.5 * (borderWidth + cornerWidth)
        if (cornerLocation == .inside) {
            leftTopPath.move(to: CGPoint(x: borderX + insideExcess, y: borderY + cornerLength + insideExcess))
            leftTopPath.addLine(to: CGPoint(x: borderX + insideExcess, y: borderY + insideExcess))
            leftTopPath.addLine(to: CGPoint(x: borderX + cornerLength + insideExcess, y: borderY + insideExcess))
        } else if (cornerLocation == .outside) {
            leftTopPath.move(to: CGPoint(x: borderX - outsideExcess, y: borderY + cornerLength - outsideExcess))
            leftTopPath.addLine(to: CGPoint(x: borderX - outsideExcess, y: borderY - outsideExcess))
            leftTopPath.addLine(to: CGPoint(x: borderX + cornerLength - outsideExcess, y: borderY - outsideExcess))
        } else {
            leftTopPath.move(to: CGPoint(x: borderX, y: borderY + cornerLength))
            leftTopPath.addLine(to: CGPoint(x: borderX, y: borderY))
            leftTopPath.addLine(to: CGPoint(x: borderX + cornerLength, y: borderY))
        }
        leftTopPath.stroke()
        
        /// 左下角小图标
        let leftBottomPath = UIBezierPath()
        leftBottomPath.lineWidth = cornerWidth
        cornerColor.set()
        
        if (cornerLocation == .inside) {
            leftBottomPath.move(to: CGPoint(x: borderX + cornerLength + insideExcess, y: borderY + borderH - insideExcess))
            leftBottomPath.addLine(to: CGPoint(x: borderX + insideExcess, y: borderY + borderH - insideExcess))
            leftBottomPath.addLine(to: CGPoint(x: borderX + insideExcess, y: borderY + borderH - cornerLength - insideExcess))
        } else if (cornerLocation == .outside) {
            leftBottomPath.move(to: CGPoint(x: borderX + cornerLength - outsideExcess, y: borderY + borderH + outsideExcess))
            leftBottomPath.addLine(to: CGPoint(x: borderX - outsideExcess, y: borderY + borderH + outsideExcess))
            leftBottomPath.addLine(to: CGPoint(x: borderX - outsideExcess, y: borderY + borderH - cornerLength + outsideExcess))
        } else {
            leftBottomPath.move(to: CGPoint(x: borderX + cornerLength, y: borderY + borderH))
            leftBottomPath.addLine(to: CGPoint(x: borderX, y: borderY + borderH))
            leftBottomPath.addLine(to: CGPoint(x: borderX, y: borderY + borderH - cornerLength))
        }
        leftBottomPath.stroke()
        
        /// 右上角小图标
        let rightTopPath = UIBezierPath()
        rightTopPath.lineWidth = cornerWidth
        cornerColor.set()
        
        if (cornerLocation == .inside) {
            rightTopPath.move(to: CGPoint(x: borderX + borderW - cornerLength - insideExcess, y: borderY + insideExcess))
            rightTopPath.addLine(to: CGPoint(x: borderX + borderW - insideExcess, y: borderY + insideExcess))
            rightTopPath.addLine(to: CGPoint(x: borderX + borderW - insideExcess, y: borderY + cornerLength + insideExcess))
        } else if (cornerLocation == .outside) {
            rightTopPath.move(to: CGPoint(x: borderX + borderW - cornerLength + outsideExcess, y: borderY - outsideExcess))
            rightTopPath.addLine(to: CGPoint(x: borderX + borderW + outsideExcess, y: borderY - outsideExcess))
            rightTopPath.addLine(to: CGPoint(x: borderX + borderW + outsideExcess, y: borderY + cornerLength - outsideExcess))
        } else {
            rightTopPath.move(to: CGPoint(x: borderX + borderW - cornerLength, y: borderY))
            rightTopPath.addLine(to: CGPoint(x: borderX + borderW, y: borderY))
            rightTopPath.addLine(to: CGPoint(x: borderX + borderW, y: borderY + cornerLength))
        }
        rightTopPath.stroke()
        
        /// 右下角小图标
        let rightBottomPath = UIBezierPath()
        rightBottomPath.lineWidth = cornerWidth
        cornerColor.set()
        
        if (cornerLocation == .inside) {
            rightBottomPath.move(to: CGPoint(x: borderX + borderW - insideExcess, y: borderY + borderH - cornerLength - insideExcess))
            rightBottomPath.addLine(to: CGPoint(x: borderX + borderW - insideExcess, y: borderY + borderH - insideExcess))
            rightBottomPath.addLine(to: CGPoint(x: borderX + borderW - cornerLength - insideExcess, y: borderY + borderH - insideExcess))
        } else if (cornerLocation == .outside) {
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
    
    // MARK: - Public
    /// 添加定时器
    open func addTimer() {
        removeTimer()
        
        var scanningLineX: CGFloat = 0
        var scanningLineY: CGFloat = 0
        var scanningLineW: CGFloat = 0
        var scanningLineH: CGFloat = 0
        if (scanAnimationStyle == .grid) {
            addSubview(contentView)
            contentView.addSubview(scanningLine)
            scanningLineW = borderFrame.size.width
            scanningLineH = borderFrame.size.height
            scanningLineX = 0
            scanningLineY = -borderFrame.size.height
            scanningLine.frame = CGRectMake(scanningLineX, scanningLineY, scanningLineW, scanningLineH)
        } else {
            addSubview(scanningLine)
            scanningLineW = borderFrame.size.width
            scanningLineH = scanningLine.image?.size.height ?? 0
            scanningLineX = borderFrame.origin.x
            scanningLineY = borderFrame.origin.y
            scanningLine.frame = CGRectMake(scanningLineX, scanningLineY, scanningLineW, scanningLineH)
        }
        
        let timer = Timer(timeInterval: animationTimeInterval, target: self, selector: #selector(beginRefreshUI), userInfo: nil, repeats: true)
        self.timer = timer
        RunLoop.main.add(timer, forMode: .common)
    }
    
    /// 移除定时器
    open func removeTimer() {
        timer?.invalidate()
        timer = nil
        scanningLine.removeFromSuperview()
    }
    
    // MARK: - Private
    @objc private func beginRefreshUI() {
        var frame: CGRect = scanningLine.frame
        
        if scanAnimationStyle == .grid {
            if QrcodeScanView.animationFlag {
                frame.origin.y = -borderFrame.size.height
                QrcodeScanView.animationFlag = false
                UIView.animate(withDuration: animationTimeInterval) { [weak self] in
                    frame.origin.y += 2
                    self?.scanningLine.frame = frame
                }
            } else {
                if scanningLine.frame.origin.y >= -borderFrame.size.height {
                    let scanMaxY: CGFloat = 0
                    if scanningLine.frame.origin.y >= scanMaxY {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                            frame.origin.y = -(self?.borderFrame.size.height ?? 0)
                            self?.scanningLine.frame = frame
                            QrcodeScanView.animationFlag = true
                        }
                    } else {
                        UIView.animate(withDuration: animationTimeInterval) { [weak self] in
                            frame.origin.y += 2
                            self?.scanningLine.frame = frame
                        }
                    }
                } else {
                    QrcodeScanView.animationFlag = !QrcodeScanView.animationFlag
                }
            }
        } else {
            if QrcodeScanView.animationFlag {
                frame.origin.y = borderFrame.origin.y
                QrcodeScanView.animationFlag = false
                UIView.animate(withDuration: animationTimeInterval) { [weak self] in
                    frame.origin.y += 2
                    self?.scanningLine.frame = frame
                }
            } else {
                if scanningLine.frame.origin.y >= borderFrame.origin.y {
                    let scanMaxY: CGFloat = borderFrame.origin.y + borderFrame.size.height - (scanningLine.image?.size.height ?? 0)
                    if scanningLine.frame.origin.y >= scanMaxY {
                        frame.origin.y = borderFrame.origin.y
                        scanningLine.frame = frame
                        QrcodeScanView.animationFlag = true
                    } else {
                        UIView.animate(withDuration: animationTimeInterval) { [weak self] in
                            frame.origin.y += 2
                            self?.scanningLine.frame = frame
                        }
                    }
                } else {
                    QrcodeScanView.animationFlag = !QrcodeScanView.animationFlag
                }
            }
        }
    }
    
}
