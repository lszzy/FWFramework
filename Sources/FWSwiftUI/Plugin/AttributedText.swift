//
//  AttributedText.swift
//  FWFramework
//
//  Created by wuyong on 2024/8/16.
//

#if canImport(SwiftUI)
import UIKit
import SwiftUI
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

// MARK: - AttributedText
/// 富文本组件，兼容NSAttributedString
public struct AttributedText: View {
    
    // MARK: - Accessor
    @State private var textSize: CGSize?
    private var viewModel = ViewModel()
    
    private let attributedText: NSAttributedString
    private let clickedOnLink: ((Any?) -> Void)?
    
    // MARK: - Lifecycle
    public init(_ attributedText: AttributedStringParameter, clickedOnLink: ((Any?) -> Void)? = nil) {
        self.attributedText = attributedText.attributedStringValue
        self.clickedOnLink = clickedOnLink
    }
    
    // MARK: - Public
    public func font(_ font: UIFont) -> Self {
        configure({ $0.viewModel.font = font })
    }

    public func foregroundColor(_ foregroundColor: UIColor) -> Self {
        configure({ $0.viewModel.foregroundColor = foregroundColor })
    }

    @_disfavoredOverload
    public func foregroundColor(_ foregroundColor: Color?) -> Self {
        configure({ $0.viewModel.foregroundColor = foregroundColor?.toUIColor() })
    }
    
    public func baselineAdjustment(_ baselineAdjustment: UIBaselineAdjustment) -> Self {
        configure({ $0.viewModel.baselineAdjustment = baselineAdjustment })
    }
    
    public func adjustsFontSizeToFitWidth(_ adjustsFontSizeToFitWidth: Bool) -> Self {
        configure({ $0.viewModel.adjustsFontSizeToFitWidth = adjustsFontSizeToFitWidth })
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ViewRepresentable(
                attributedText: attributedText,
                maxLayoutWidth: geometry.size.width - geometry.safeAreaInsets.leading - geometry.safeAreaInsets.trailing,
                viewModel: viewModel,
                clickedOnLink: clickedOnLink
            )
        }
        .frame(idealWidth: textSize?.width, idealHeight: textSize?.height)
        .fixedSize(horizontal: false, vertical: true)
        .onReceive(viewModel.$textSize) { size in
            textSize = size
        }
    }
    
}

extension AttributedText {
    
    class ViewModel {
        @Published var textSize: CGSize?
        var font: UIFont?
        var foregroundColor: UIColor?
        var baselineAdjustment: UIBaselineAdjustment?
        var adjustsFontSizeToFitWidth: Bool?
    }
    
    struct ViewRepresentable: UIViewRepresentable {
        var attributedText: NSAttributedString
        var maxLayoutWidth: CGFloat
        var viewModel: ViewModel
        var clickedOnLink: ((Any?) -> Void)?
        
        // MARK: - UIViewRepresentable
        typealias UIViewType = ViewLabel
        
        func makeUIView(context: Context) -> ViewLabel {
            ViewLabel()
        }
        
        func updateUIView(_ label: ViewLabel, context: Context) {
            if let font = viewModel.font { label.font = font }
            if let foregroundColor = viewModel.foregroundColor { label.textColor = foregroundColor }
            if let baselineAdjustment = viewModel.baselineAdjustment { label.baselineAdjustment = baselineAdjustment }
            if let adjustsFontSizeToFitWidth = viewModel.adjustsFontSizeToFitWidth { label.adjustsFontSizeToFitWidth = adjustsFontSizeToFitWidth }
            
            label.allowsDefaultTighteningForTruncation = context.environment.allowsTightening
            label.minimumScaleFactor = context.environment.minimumScaleFactor
            label.numberOfLines = context.environment.lineLimit ?? 0
            label.textAlignment = textAlignment(from: context.environment.multilineTextAlignment)
            label.lineBreakMode = lineBreakMode(from: context.environment.truncationMode)
            label.isUserInteractionEnabled = context.environment.isEnabled
            label.clickedOnLink = clickedOnLink
            
            label.attributedText = attributedText
            label.maxLayoutWidth = maxLayoutWidth
            viewModel.textSize = label.intrinsicContentSize
        }
        
        // MARK: - Private
        func textAlignment(from textAlignment: TextAlignment) -> NSTextAlignment {
            switch textAlignment {
            case .leading:
                return .left
            case .center:
                return .center
            case .trailing:
                return .right
            @unknown default:
                return .left
            }
        }
        
        func lineBreakMode(from truncationMode: Text.TruncationMode) -> NSLineBreakMode {
            switch truncationMode {
            case .head:
                return .byTruncatingHead
            case .tail:
                return .byTruncatingTail
            case .middle:
                return .byTruncatingMiddle
            @unknown default:
                return .byWordWrapping
            }
        }
    }
    
    class ViewLabel: UILabel {
        var maxLayoutWidth: CGFloat = 0 {
            didSet {
                guard maxLayoutWidth != oldValue else { return }
                invalidateIntrinsicContentSize()
            }
        }
        
        var clickedOnLink: ((Any?) -> Void)? {
            didSet {
                linkGesture?.isEnabled = clickedOnLink != nil
            }
        }
        
        private var linkGesture: UITapGestureRecognizer?
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            backgroundColor = .clear
            linkGesture = fw.addLinkGesture { [weak self] link in
                self?.clickedOnLink?(link)
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override var intrinsicContentSize: CGSize {
            guard maxLayoutWidth > 0 else {
                return super.intrinsicContentSize
            }
            
            return sizeThatFits(CGSize(width: maxLayoutWidth, height: .greatestFiniteMagnitude))
        }
    }
    
}

#endif
