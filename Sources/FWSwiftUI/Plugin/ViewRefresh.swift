//
//  ViewRefresh.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#if canImport(SwiftUI)
import SwiftUI

// MARK: - Refresh
/// [Refresh](https://github.com/wxxsw/Refresh)
public enum Refresh {}

public typealias RefreshHeader = Refresh.Header

public typealias RefreshFooter = Refresh.Footer

// MARK: - Header
extension Refresh {
    
    public struct Header<Label> where Label: View {
        
        let action: () -> Void
        let label: (CGFloat) -> Label
        
        @Binding var refreshing: Bool

        public init(refreshing: Binding<Bool>, action: @escaping () -> Void, @ViewBuilder label: @escaping (CGFloat) -> Label) {
            self.action = action
            self.label = label
            self._refreshing = refreshing
        }
        
        @Environment(\.refreshHeaderUpdate) var update
    }
}

extension Refresh.Header: View {
    
    public var body: some View {
        if update.refresh, !refreshing, update.progress > 1.01 {
            DispatchQueue.main.async {
                self.refreshing = true
                self.action()
            }
        }
        
        return Group {
            if update.enable {
                VStack(alignment: .center, spacing: 0) {
                    Spacer()
                    label(update.progress)
                        .opacity(opacity)
                }
                .frame(maxWidth: .infinity)
            } else {
                EmptyView()
            }
        }
        .listRowInsets(.zero)
        .anchorPreference(key: Refresh.HeaderAnchorKey.self, value: .bounds) {
            [.init(bounds: $0, refreshing: self.refreshing)]
        }
    }
    
    var opacity: Double {
        (!refreshing && update.refresh) || (update.progress == 0) ? 0 : 1
    }
}

// MARK: - HeaderKey
extension EnvironmentValues {
    
    var refreshHeaderUpdate: Refresh.HeaderUpdateKey.Value {
        get { self[Refresh.HeaderUpdateKey.self] }
        set { self[Refresh.HeaderUpdateKey.self] = newValue }
    }
}

extension Refresh {
    
    struct HeaderAnchorKey {
        nonisolated(unsafe) static var defaultValue: Value = []
    }
    
    struct HeaderUpdateKey {
        nonisolated(unsafe) static var defaultValue: Value = .init(enable: false)
    }
}

extension Refresh.HeaderAnchorKey: PreferenceKey {
    
    typealias Value = [Item]
    
    struct Item {
        let bounds: Anchor<CGRect>
        let refreshing: Bool
    }
    
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.append(contentsOf: nextValue())
    }
}

extension Refresh.HeaderUpdateKey: EnvironmentKey {
    
    struct Value {
        let enable: Bool
        var progress: CGFloat = 0
        var refresh: Bool = false
    }
}

// MARK: - Footer
extension Refresh {
    
    public struct Footer<Label> where Label: View {
        
        let action: () -> Void
        let label: () -> Label
        
        @Binding var refreshing: Bool
        
        private var noMore: Bool = false
        private var preloadOffset: CGFloat = 0

        public init(refreshing: Binding<Bool>, action: @escaping () -> Void, @ViewBuilder label: @escaping () -> Label) {
            self.action = action
            self.label = label
            self._refreshing = refreshing
        }
        
        @Environment(\.refreshFooterUpdate) var update
    }
}

extension Refresh.Footer {
    
    public func noMore(_ noMore: Bool) -> Self {
        var view = self
        view.noMore = noMore
        return view
    }
    
    public func preload(offset: CGFloat) -> Self {
        var view = self
        view.preloadOffset = offset
        return view
    }
}

extension Refresh.Footer: View {
    
    public var body: some View {
        if !noMore, update.refresh, !refreshing {
            DispatchQueue.main.async {
                self.refreshing = true
                self.action()
            }
        }
        
        return Group {
            if update.enable {
                VStack(alignment: .center, spacing: 0) {
                    if refreshing || noMore {
                        label()
                    } else {
                        EmptyView()
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                EmptyView()
            }
        }
        .listRowInsets(.zero)
        .anchorPreference(key: Refresh.FooterAnchorKey.self, value: .bounds) {
            if self.noMore || self.refreshing {
                return []
            } else {
                return [.init(bounds: $0, preloadOffset: self.preloadOffset, refreshing: self.refreshing)]
            }
        }
    }
}

// MARK: - FooterKey
extension EnvironmentValues {
    
    var refreshFooterUpdate: Refresh.FooterUpdateKey.Value {
        get { self[Refresh.FooterUpdateKey.self] }
        set { self[Refresh.FooterUpdateKey.self] = newValue }
    }
}

extension Refresh {
    
    struct FooterAnchorKey {
        nonisolated(unsafe) static var defaultValue: Value = []
    }
    
    struct FooterUpdateKey {
        nonisolated(unsafe) static var defaultValue: Value = .init(enable: false)
    }
}

extension Refresh.FooterAnchorKey: PreferenceKey {
    
    typealias Value = [Item]
    
    struct Item {
        let bounds: Anchor<CGRect>
        let preloadOffset: CGFloat
        let refreshing: Bool
    }
    
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.append(contentsOf: nextValue())
    }
}

extension Refresh.FooterUpdateKey: EnvironmentKey {
    
    struct Value: Equatable {
        let enable: Bool
        var refresh: Bool = false
    }
}

// MARK: - List
extension ScrollView {
    
    // 启用刷新，添加到首尾即可
    public func enableRefresh(_ enable: Bool = true) -> some View {
        modifier(Refresh.Modifier(enable: enable))
    }
}

extension List {
    
    // 启用刷新，添加到Header|Footer即可
    public func enableRefresh(_ enable: Bool = true) -> some View {
        modifier(Refresh.Modifier(enable: enable))
    }
}

// MARK: - Modifier
extension Refresh {
    
    public struct Modifier: @unchecked Sendable {
        let isEnabled: Bool
        
        @State private var id: Int = 0
        @State private var headerUpdate: HeaderUpdateKey.Value
        @State private var headerPadding: CGFloat = 0
        @State private var headerPreviousProgress: CGFloat = 0
        
        @State private var footerUpdate: FooterUpdateKey.Value
        @State private var footerPreviousRefreshAt: Date?
        
        public init(enable: Bool) {
            isEnabled = enable
            _headerUpdate = State(initialValue: .init(enable: enable))
            _footerUpdate = State(initialValue: .init(enable: enable))
        }
        
        @Environment(\.defaultMinListRowHeight) var rowHeight
    }
}

extension Refresh.Modifier: ViewModifier {
    
    public func body(content: Content) -> some View {
        return GeometryReader { proxy in
            content
                .environment(\.refreshHeaderUpdate, self.headerUpdate)
                .environment(\.refreshFooterUpdate, self.footerUpdate)
                .padding(.top, self.headerPadding)
                .clipped(proxy.safeAreaInsets == .zero)
                .backgroundPreferenceValue(Refresh.HeaderAnchorKey.self) { v -> Color in
                    DispatchQueue.main.async { self.update(proxy: proxy, value: v) }
                    return Color.clear
                }
                .backgroundPreferenceValue(Refresh.FooterAnchorKey.self) { v -> Color in
                    DispatchQueue.main.async { self.update(proxy: proxy, value: v) }
                    return Color.clear
                }
                .id(self.id)
        }
    }
    
    func update(proxy: GeometryProxy, value: Refresh.HeaderAnchorKey.Value) {
        guard let item = value.first else { return }
        guard !footerUpdate.refresh else { return }
        
        let bounds = proxy[item.bounds]
        var update = headerUpdate
        
        update.progress = max(0, (bounds.maxY) / bounds.height)
        
        if update.refresh != item.refreshing {
            update.refresh = item.refreshing
            
            if !item.refreshing {
                id += 1
                DispatchQueue.main.async {
                    self.headerUpdate.progress = 0
                }
            }
        } else {
            update.refresh = update.refresh || (headerPreviousProgress > 1 && update.progress < headerPreviousProgress && update.progress >= 1)
        }
        
        headerUpdate = update
        headerPadding = headerUpdate.refresh ? 0 : -max(rowHeight, bounds.height)
        headerPreviousProgress = update.progress
    }
    
    func update(proxy: GeometryProxy, value: Refresh.FooterAnchorKey.Value) {
        guard let item = value.first else { return }
        guard headerUpdate.progress == 0 else { return }
        
        let bounds = proxy[item.bounds]
        var update = footerUpdate
        
        if bounds.minY <= rowHeight || bounds.minY <= bounds.height {
            update.refresh = false
        } else if update.refresh && !item.refreshing {
            update.refresh = false
        } else {
            update.refresh = proxy.size.height - bounds.minY + item.preloadOffset > 0
        }
        
        if update.refresh, !footerUpdate.refresh {
            if let date = footerPreviousRefreshAt, Date().timeIntervalSince(date) < 0.1 {
                update.refresh = false
            }
            footerPreviousRefreshAt = Date()
        }
        
        footerUpdate = update
    }
}

#endif
