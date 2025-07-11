//
//  WebImageView.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import Combine
import SwiftUI
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

/// 网络图片视图，仅支持静态图
public struct WebImageView: View {
    @ObservedObject public private(set) var binder: ImageBinder

    var placeholder: AnyView?
    var cancelOnDisappear: Bool = false
    var configurations: [(Image) -> Image]

    public init(_ url: URLParameter?, isLoaded: Binding<Bool> = .constant(false)) {
        self.binder = ImageBinder(url: url, isLoaded: isLoaded)
        self.configurations = []
        binder.start()
    }

    public var body: some View {
        Group {
            if let uiImage = binder.image {
                configurations.reduce(Image(uiImage: uiImage)) { current, config in
                    config(current)
                }
            } else {
                Group {
                    if let placeholder {
                        placeholder
                    } else {
                        Image(uiImage: .init())
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .onDisappear { [weak binder = self.binder] in
                    if cancelOnDisappear {
                        binder?.cancel()
                    }
                }
            }
        }
        .onAppear { [weak binder] in
            guard let binder else { return }
            if !binder.loadingSucceed {
                binder.start()
            }
        }
    }

    public func placeholder<Content: View>(@ViewBuilder content: () -> Content) -> Self {
        var result = self
        result.placeholder = AnyView(content())
        return result
    }

    public func cancelOnDisappear(_ flag: Bool) -> Self {
        var result = self
        result.cancelOnDisappear = flag
        return result
    }

    public func configure(_ block: @escaping (Image) -> Image) -> Self {
        var result = self
        result.configurations.append(block)
        return result
    }

    public func resizable(capInsets: EdgeInsets = EdgeInsets(), resizingMode: Image.ResizingMode = .stretch) -> Self {
        configure { $0.resizable(capInsets: capInsets, resizingMode: resizingMode) }
    }

    public func renderingMode(_ renderingMode: Image.TemplateRenderingMode?) -> Self {
        configure { $0.renderingMode(renderingMode) }
    }

    public func interpolation(_ interpolation: Image.Interpolation) -> Self {
        configure { $0.interpolation(interpolation) }
    }

    public func antialiased(_ isAntialiased: Bool) -> Self {
        configure { $0.antialiased(isAntialiased) }
    }

    public func onCompletion(perform action: (@MainActor @Sendable (UIImage?, Error?) -> Void)?) -> Self {
        binder.onCompletion(perform: action)
        return self
    }

    public func onProgress(perform action: (@MainActor @Sendable (Double) -> Void)?) -> Self {
        binder.onProgress(perform: action)
        return self
    }
}

extension WebImageView {
    public class ImageBinder: ObservableObject, @unchecked Sendable {
        @Published var image: UIImage?

        let url: URLParameter?
        var isLoaded: Binding<Bool>
        var loadingSucceed: Bool = false
        var receipt: Any?
        var completionBlock: (@MainActor @Sendable (UIImage?, Error?) -> Void)?
        var progressBlock: (@MainActor @Sendable (Double) -> Void)?

        init(url: URLParameter?, isLoaded: Binding<Bool>) {
            self.url = url
            self.isLoaded = isLoaded
            self.image = nil
        }

        func start() {
            guard !loadingSucceed else { return }

            loadingSucceed = true
            receipt = UIImage.fw.downloadImage(url, completion: { [weak self] image, _, error in
                guard let self else { return }

                if let image {
                    self.image = image
                    isLoaded.wrappedValue = true
                    completionBlock?(image, error)
                } else {
                    loadingSucceed = false
                    completionBlock?(image, error)
                }
            }, progress: { [weak self] progress in
                self?.progressBlock?(progress)
            })
        }

        public func cancel() {
            UIImage.fw.cancelImageDownload(receipt)
        }

        func onCompletion(perform action: (@MainActor @Sendable (UIImage?, Error?) -> Void)?) {
            completionBlock = action
        }

        func onProgress(perform action: (@MainActor @Sendable (Double) -> Void)?) {
            progressBlock = action
        }
    }
}
