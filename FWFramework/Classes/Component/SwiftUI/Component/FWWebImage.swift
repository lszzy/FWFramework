//
//  FWWebImage.swift
//  FWFramework
//
//  Created by wuyong on 2020/11/13.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

#if canImport(SwiftUI) && canImport(Combine)
import SwiftUI
import Combine

/// SwiftUI加载网络图片
@available(iOS 13.0, *)
public struct FWWebImage: View {
    @ObservedObject public private(set) var binder: ImageBinder
    
    var placeholder: AnyView?
    var cancelOnDisappear: Bool = false
    var configurations: [(Image) -> Image]
    
    public init(_ url: Any?, isLoaded: Binding<Bool> = .constant(false)) {
        binder = ImageBinder(url: url, isLoaded: isLoaded)
        configurations = []
        binder.start()
    }
    
    public var body: some View {
        Group {
            if binder.image != nil {
                configurations.reduce(Image(uiImage: binder.image!)) { current, config in
                    config(current)
                }
            } else {
                Group {
                    if placeholder != nil {
                        placeholder
                    } else {
                        Image(uiImage: .init())
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .onDisappear { [weak binder = self.binder] in
                    if self.cancelOnDisappear {
                        binder?.cancel()
                    }
                }
            }
        }
        .onAppear { [weak binder] in
            guard let binder = binder else { return }
            if !binder.loadingSucceed {
                binder.start()
            }
        }
    }
    
    public func placeholder<Content: View>(@ViewBuilder _ builder: () -> Content) -> FWWebImage {
        var result = self
        result.placeholder = AnyView(builder())
        return result
    }
    
    public func cancelOnDisappear(_ flag: Bool) -> FWWebImage {
        var result = self
        result.cancelOnDisappear = flag
        return result
    }
    
    public func configure(_ block: @escaping (Image) -> Image) -> FWWebImage {
        var result = self
        result.configurations.append(block)
        return result
    }
    
    public func resizable(capInsets: EdgeInsets = EdgeInsets(), resizingMode: Image.ResizingMode = .stretch) -> FWWebImage {
        configure { $0.resizable(capInsets: capInsets, resizingMode: resizingMode) }
    }
    
    public func renderingMode(_ renderingMode: Image.TemplateRenderingMode?) -> FWWebImage {
        configure { $0.renderingMode(renderingMode) }
    }
    
    public func interpolation(_ interpolation: Image.Interpolation) -> FWWebImage {
        configure { $0.interpolation(interpolation) }
    }
    
    public func antialiased(_ isAntialiased: Bool) -> FWWebImage {
        configure { $0.antialiased(isAntialiased) }
    }
    
    public func onCompletion(perform action: ((UIImage?, Error?) -> Void)?) -> FWWebImage {
        binder.onCompletion(perform: action)
        return self
    }
    
    public func onProgress(perform action: ((Double) -> Void)?) -> FWWebImage {
        binder.onProgress(perform: action)
        return self
    }
}

@available(iOS 13.0, *)
extension FWWebImage {
    public class ImageBinder: ObservableObject {
        @Published var image: UIImage?
        
        let url: Any?
        var isLoaded: Binding<Bool>
        var loadingSucceed: Bool = false
        var receipt: Any?
        var completionBlock: ((UIImage?, Error?) -> Void)?
        var progressBlock: ((Double) -> Void)?
        
        init(url: Any?, isLoaded: Binding<Bool>) {
            self.url = url
            self.isLoaded = isLoaded
            self.image = nil
        }
        
        func start() {
            guard !loadingSucceed else { return }
            
            loadingSucceed = true
            receipt = UIImage.fwDownloadImage(url, completion: { [weak self] (image, error) in
                guard let self = self else { return }
                
                if image != nil {
                    self.image = image
                    self.isLoaded.wrappedValue = true
                    self.completionBlock?(image, error)
                } else {
                    self.loadingSucceed = false
                    self.completionBlock?(image, error)
                }
            }, progress: { [weak self] (progress) in
                self?.progressBlock?(progress)
            })
        }
        
        public func cancel() {
            UIImage.fwCancelDownload(receipt)
        }
        
        func onCompletion(perform action: ((UIImage?, Error?) -> Void)?) {
            completionBlock = action
        }
        
        func onProgress(perform action: ((Double) -> Void)?) {
            progressBlock = action
        }
    }
}

#endif
