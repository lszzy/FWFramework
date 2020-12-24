//
//  FWPullToRefresh.swift
//  FWPullToRefresh
//
//  Created by András Samu on 2019. 09. 15..
//  Updated by Veit Progl on 29.01.20.
//  Copyright © 2019. András Samu. All rights reserved.
//

import SwiftUI

/// https://github.com/AppPear/SwiftUI-PullToRefresh
@available(iOS 13.0, macOS 10.15, *)
class FWRefreshData: ObservableObject {
    @Binding var isDone: Bool
    
    @Published var showText: String
    @Published var showRefreshView: Bool {
        didSet {
            self.showText = "Loading"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if self.showRefreshView {
                    self.showRefreshView = false
                    self.showDone = true
                    self.showText = "Done"
                }
            }
        }
    }
    @Published var pullStatus: CGFloat
    @Published var showDone: Bool {
        didSet {
            if self.showDone && self.isDone {
                self.showDone = false
                self.showText = "Pull to refresh"
            }
            print(self.isDone)
        }
    }
    
    init(isDone:Binding<Bool>) {
        self._isDone = isDone
        self.showText = "Pull to refresh"
        self.showRefreshView = false
        self.pullStatus = 0
        self.showDone = false
    }
}


@available(iOS 13.0, macOS 10.15, *)
public struct FWRefreshableNavigationView<Content: View>: View {
    let content: () -> Content
    let action: () -> Void
    private var title: String
    @Binding var isDone: Bool

    @ObservedObject var data: FWRefreshData

    public init(title:String, action: @escaping () -> Void,isDone: Binding<Bool> ,@ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.action = action
        self.content = content
        self._isDone = isDone
        self.data = FWRefreshData(isDone: isDone)
    }
    
    public var body: some View {
        NavigationView{
            FWRefreshableList(data: data, action: self.action) {
                self.content()
            }.navigationBarTitle(title)
        }
    }
}

@available(iOS 13.0, macOS 10.15, *)
public struct FWRefreshableNavigationViewWithItem<Content: View, LeadingItem: View, TrailingItem: View>: View {
    let content: () -> Content
    let leadingItem: () -> LeadingItem
    let trailingItem: () -> TrailingItem
    let action: () -> Void
    private var title: String
    @Binding var isDone: Bool

    @ObservedObject var data: FWRefreshData
    
    public init(title:String, action: @escaping () -> Void, isDone: Binding<Bool> ,@ViewBuilder leadingItem: @escaping () -> LeadingItem, @ViewBuilder trailingItem: @escaping () -> TrailingItem, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.action = action
        self.content = content
        self.leadingItem = leadingItem
        self.trailingItem = trailingItem
        self._isDone = isDone
        self.data = FWRefreshData(isDone: isDone)
    }
    
    public var body: some View {
        NavigationView{
            FWRefreshableList(data: data, action: self.action) {
                self.content()
            }.navigationBarTitle(title)
             .navigationBarItems(leading: self.leadingItem(), trailing: self.trailingItem())
        }
    }
}

@available(iOS 13.0, macOS 10.15, *)
public struct FWRefreshableList<Content: View>: View {
    @ObservedObject var data: FWRefreshData
    
    let action: () -> Void
    let content: () -> Content
    
    init(data: FWRefreshData, action: @escaping () -> Void, @ViewBuilder content: @escaping () -> Content) {
        self.data = data
        self.action = action
        self.content = content
        UITableViewHeaderFooterView.appearance().tintColor = UIColor.clear
    }
    
    public var body: some View {
        
        List{
            Section(header: FWPullToRefreshView(data: self.data)) {
             content()
            }
        }
        .offset(y: -40)
        .onPreferenceChange(FWRefreshableKeyTypes.PrefKey.self) { values in
            guard let bounds = values.first?.bounds else { return }
            self.data.pullStatus = CGFloat((bounds.origin.y - 106) / 80)
            self.refresh(offset: bounds.origin.y)
        }
    }
    
    func refresh(offset: CGFloat) {
        if offset > 185 && !self.data.showRefreshView && !self.data.showDone {
            self.data.showRefreshView = true
            DispatchQueue.main.async {
                self.action()
            }
            
        }
    }
}

@available(iOS 13.0, macOS 10.15, *)
struct FWSpinner: View {
    @Binding var percentage: CGFloat
    
    var body: some View {
        GeometryReader{ geometry in
            ForEach(1...10, id: \.self) { i in
                Rectangle()
                    .fill(Color.gray)
                    .cornerRadius(1)
                    .frame(width: 2.5, height: 8)
                    .opacity(self.percentage * 10 >= CGFloat(i) ? Double(i)/10.0 : 0)
                    .offset(x: 0, y: -8)
                    .rotationEffect(.degrees(Double(36 * i)), anchor: .bottom)
            }.offset(x: 20, y: 12)
        }.frame(width: 40, height: 40)
    }
}

@available(iOS 13.0, macOS 10.15, *)
struct FWRefreshView: View {
    @ObservedObject var data: FWRefreshData
    
    var body: some View {
        HStack() {
            VStack(alignment: .center){
                if self.data.showDone {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(Color.green)
                        .imageScale(.large)
                } else if (!data.showRefreshView) {
                    FWSpinner(percentage: self.$data.pullStatus)
                } else {
                    FWActivityIndicator(isAnimating: .constant(true), style: .large)
                }
                Text(self.data.showText).font(.caption)
            }
        }
    }
}

@available(iOS 13.0, macOS 10.15, *)
struct FWPullToRefreshView: View {
    @ObservedObject var data: FWRefreshData
    var body: some View {
        GeometryReader{ geometry in
            FWRefreshView(data: self.data)
                .opacity(Double((geometry.frame(in: CoordinateSpace.global).origin.y - 106) / 80)).preference(key: FWRefreshableKeyTypes.PrefKey.self, value: [FWRefreshableKeyTypes.PrefData(bounds: geometry.frame(in: CoordinateSpace.global))])
                .offset(y: -70)
        }
        .offset(y: -20)
    }
}

@available(iOS 13.0, macOS 10.15, *)
struct FWActivityIndicator: UIViewRepresentable {

    @Binding var isAnimating: Bool
    let style: UIActivityIndicatorView.Style

    func makeUIView(context: UIViewRepresentableContext<FWActivityIndicator>) -> UIActivityIndicatorView {
        return UIActivityIndicatorView(style: style)
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<FWActivityIndicator>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}

@available(iOS 13.0, macOS 10.15, *)
struct FWRefreshableKeyTypes {
    
    struct PrefData: Equatable {
        let bounds: CGRect
    }

    struct PrefKey: PreferenceKey {
        static var defaultValue: [PrefData] = []

        static func reduce(value: inout [PrefData], nextValue: () -> [PrefData]) {
            value.append(contentsOf: nextValue())
        }

        typealias Value = [PrefData]
    }
}
