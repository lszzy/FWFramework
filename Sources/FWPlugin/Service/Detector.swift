//
//  Detector.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/25.
//

import UIKit
#if canImport(Vision)
import Vision
#endif
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

/// 智能检测器
public class Detector: NSObject {
    
    /// 识别图片文字，可设置语言(zh-CN,en-US)等，完成时主线程回调结果
    public static func recognizeText(in image: CGImage, configuration: ((VNRecognizeTextRequest) -> Void)?, completion: @escaping ([OcrResult]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            Detector.performOcr(image: image, configuration: configuration) { results in
                DispatchQueue.main.async {
                    completion(results)
                }
            }
        }
    }
    
    private static func performOcr(image: CGImage, configuration: ((VNRecognizeTextRequest) -> Void)?, completion: @escaping ([OcrResult]) -> Void) {
        let textRequest = VNRecognizeTextRequest() { request, error in
            let imageSize = CGSize(width: image.width, height: image.height)
            guard let results = request.results as? [VNRecognizedTextObservation], !results.isEmpty else {
                completion([])
                return
            }
            
            let outputObjects: [OcrResult] = results.compactMap { result in
                guard let candidate = result.topCandidates(1).first,
                      let box = try? candidate.boundingBox(for: candidate.string.startIndex..<candidate.string.endIndex) else {
                    return nil
                }
                
                let unwrappedBox: VNRectangleObservation = box
                let boxRect = Detector.convertToImageRect(boundingBox: unwrappedBox, imageSize: imageSize)
                let confidence: Float = candidate.confidence
                
                let ocrResult = OcrResult()
                ocrResult.text = candidate.string
                ocrResult.confidence = confidence
                ocrResult.rect = boxRect
                ocrResult.imageSize = imageSize
                return ocrResult
            }
            completion(outputObjects)
        }
       
        textRequest.recognitionLevel = .accurate
        textRequest.usesLanguageCorrection = false
        configuration?(textRequest)
       
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        do {
            try handler.perform([textRequest])
        } catch {
            completion([])
        }
    }
    
    private static func convertToImageRect(boundingBox: VNRectangleObservation, imageSize: CGSize) -> CGRect {
        let topLeft = VNImagePointForNormalizedPoint(boundingBox.topLeft,
                                                     Int(imageSize.width),
                                                     Int(imageSize.height))
        let bottomRight = VNImagePointForNormalizedPoint(boundingBox.bottomRight,
                                                         Int(imageSize.width),
                                                         Int(imageSize.height))
        return CGRect(x: topLeft.x, y: imageSize.height - topLeft.y,
                      width: abs(bottomRight.x - topLeft.x),
                      height: abs(topLeft.y - bottomRight.y))
    }
    
}

/// OCR扫描结果
public class OcrResult: NSObject {
    
    /// 识别文本
    public var text: String = ""
    /// 可信度，0到1
    public var confidence: Float = 0
    /// 图片大小
    public var imageSize: CGSize = .zero
    /// 识别区域
    public var rect: CGRect = .zero
    
}

// MARK: - Autoloader+Service
@objc extension Autoloader {
    static func loadPlugin_Service() {}
}
