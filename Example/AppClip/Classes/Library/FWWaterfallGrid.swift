//
//  Copyright © 2019 Paolo Leonardi.
//
//  Licensed under the MIT license. See the LICENSE file for more info.
//

import SwiftUI

/// https://github.com/paololeonardi/WaterfallGrid
@available(iOS 13, OSX 10.15, tvOS 13, watchOS 6, *)
public struct FWWaterfallGrid<Data, ID, Content>: View where Data : RandomAccessCollection, Content : View, ID : Hashable {

    @Environment(\.fwGridStyle) private var style
    @Environment(\.fwScrollOptions) private var scrollOptions

    private let data: Data
    private let dataId: KeyPath<Data.Element, ID>
    private let content: (Data.Element) -> Content

    @State private var loaded = false
    @State private var gridHeight: CGFloat = 0

    @State private var alignmentGuides = [AnyHashable: CGPoint]() {
        didSet { loaded = !oldValue.isEmpty }
    }
    
    public var body: some View {
        VStack {
            GeometryReader { geometry in
                self.grid(in: geometry)
                    .onPreferenceChange(FWElementPreferenceKey.self, perform: { preferences in
                        DispatchQueue.global(qos: .userInteractive).async {
                            let alignmentGuides = self.calculateAlignmentGuides(columns: self.style.columns,
                                                                                spacing: self.style.spacing,
                                                                                scrollDirection: self.scrollOptions.direction,
                                                                                preferences: preferences)
                            DispatchQueue.main.async {
                                self.alignmentGuides = alignmentGuides
                            }
                        }
                    })
            }
        }
        .frame(width: self.scrollOptions.direction == .horizontal ? gridHeight : nil,
               height: self.scrollOptions.direction == .vertical ? gridHeight : nil)
    }

    private func grid(in geometry: GeometryProxy) -> some View {
        let columnWidth = self.columnWidth(columns: style.columns, spacing: style.spacing,
                                           scrollDirection: scrollOptions.direction, geometrySize: geometry.size)
        return
            ZStack(alignment: .topLeading) {
                ForEach(data, id: self.dataId) { element in
                    self.content(element)
                        .frame(width: self.scrollOptions.direction == .vertical ? columnWidth : nil,
                               height: self.scrollOptions.direction == .horizontal ? columnWidth : nil)
                        .background(FWPreferenceSetter(id: element[keyPath: self.dataId]))
                        .alignmentGuide(.top, computeValue: { _ in self.alignmentGuides[element[keyPath: self.dataId]]?.y ?? 0 })
                        .alignmentGuide(.leading, computeValue: { _ in self.alignmentGuides[element[keyPath: self.dataId]]?.x ?? 0 })
                        .opacity(self.alignmentGuides[element[keyPath: self.dataId]] != nil ? 1 : 0)
                }
            }
            .animation(self.loaded ? self.style.animation : nil)
    }

    // MARK: - Helpers

    func calculateAlignmentGuides(columns: Int, spacing: CGFloat, scrollDirection: Axis.Set, preferences: [FWElementPreferenceData]) -> [AnyHashable: CGPoint] {
        var heights = Array(repeating: CGFloat(0), count: columns)
        var alignmentGuides = [AnyHashable: CGPoint]()

        preferences.forEach { preference in
            if let minValue = heights.min(), let indexMin = heights.firstIndex(of: minValue) {
                let preferenceSizeWidth = scrollDirection == .vertical ? preference.size.width : preference.size.height
                let preferenceSizeHeight = scrollDirection == .vertical ? preference.size.height : preference.size.width
                let width = preferenceSizeWidth * CGFloat(indexMin) + CGFloat(indexMin) * spacing
                let height = heights[indexMin]
                let offset = CGPoint(x: 0 - (scrollDirection == .vertical ? width : height),
                                     y: 0 - (scrollDirection == .vertical ? height : width))
                heights[indexMin] += preferenceSizeHeight + spacing
                alignmentGuides[preference.id] = offset
            }
        }
        
        gridHeight = (heights.max() ?? spacing) - spacing
        
        return alignmentGuides
    }

    func columnWidth(columns: Int, spacing: CGFloat, scrollDirection: Axis.Set, geometrySize: CGSize) -> CGFloat {
        let geometrySizeWidth = scrollDirection == .vertical ? geometrySize.width : geometrySize.height
        let width = max(0, geometrySizeWidth - (spacing * (CGFloat(columns) - 1)))
        return width / CGFloat(columns)
    }
}

// MARK: - Initializers

@available(iOS 13.0, *)
extension FWWaterfallGrid {

    /// Creates an instance that uniquely identifies views across updates based
    /// on the `id` key path to a property on an underlying data element.
    ///
    /// - Parameter data: A collection of data.
    /// - Parameter id: Key path to a property on an underlying data element.
    /// - Parameter content: A function that can be used to generate content on demand given underlying data.
    public init(_ data: Data, id: KeyPath<Data.Element, ID>, content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.dataId = id
        self.content = content
    }

}

@available(iOS 13.0, *)
extension FWWaterfallGrid where ID == Data.Element.ID, Data.Element : Identifiable {

    /// Creates an instance that uniquely identifies views across updates based
    /// on the identity of the underlying data element.
    ///
    /// - Parameter data: A collection of identified data.
    /// - Parameter content: A function that can be used to generate content on demand given underlying data.
    public init(_ data: Data, content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.dataId = \Data.Element.id
        self.content = content
    }

}

@available(iOS 13.0, *)
struct FWGridSyle {
    @FWPositiveNumber var columnsInPortrait: Int
    @FWPositiveNumber var columnsInLandscape: Int

    let spacing: CGFloat
    let animation: Animation?

    var columns: Int {
        let screenSize = UIScreen.main.bounds.size
        return screenSize.width > screenSize.height ? columnsInLandscape : columnsInPortrait
    }
}

@available(iOS 13.0, *)
struct FWGridStyleKey: EnvironmentKey {
    static let defaultValue = FWGridSyle(columnsInPortrait: 2, columnsInLandscape: 2,
                                       spacing: 8, animation: .default)
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    var fwGridStyle: FWGridSyle {
        get { self[FWGridStyleKey.self] }
        set { self[FWGridStyleKey.self] = newValue }
    }
}

@available(iOS 13.0, *)
@propertyWrapper
struct FWPositiveNumber {
    private var value: Int = 1
    
    var wrappedValue: Int {
        get { value }
        set { value = max(1, newValue) }
    }
    
    init(wrappedValue initialValue: Int) {
        self.wrappedValue = initialValue
    }
}

@available(iOS 13.0, *)
struct FWScrollOptions {
    let direction: Axis.Set
}

@available(iOS 13.0, *)
struct FWScrollOptionsKey: EnvironmentKey {
    static let defaultValue = FWScrollOptions(direction: .vertical)
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    var fwScrollOptions: FWScrollOptions {
        get { self[FWScrollOptionsKey.self] }
        set { self[FWScrollOptionsKey.self] = newValue }
    }
}

@available(iOS 13.0, *)
struct FWElementPreferenceData: Equatable {
    let id: AnyHashable
    let size: CGSize
}

@available(iOS 13.0, *)
struct FWElementPreferenceKey: PreferenceKey {
    typealias Value = [FWElementPreferenceData]

    static var defaultValue: [FWElementPreferenceData] = []

    static func reduce(value: inout [FWElementPreferenceData], nextValue: () -> [FWElementPreferenceData]) {
        value.append(contentsOf: nextValue())
    }
}

@available(iOS 13.0, *)
struct FWPreferenceSetter<ID: Hashable>: View {
    var id: ID
    var body: some View {
        GeometryReader { geometry in
            Color.clear
                .preference(key: FWElementPreferenceKey.self, value: [FWElementPreferenceData(id: AnyHashable(self.id), size: geometry.size)])
        }
    }
}


// MARK: - View+FWWaterfallGrid

@available(iOS 13.0, *)
extension View {

    /// Sets the style for `FWWaterfallGrid` within the environment of `self`.
    ///
    /// - Parameter columns: The number of columns of the grid. The default is `2`.
    /// - Parameter spacing: The distance between adjacent items. The default is `8`.
    /// - Parameter animation: The animation to apply when data change. If `animation` is `nil`, the grid doesn't animate.
    public func fwGridStyle(
        columns: Int = 2,
        spacing: CGFloat = 8,
        animation: Animation? = .default
    ) -> some View {
        let style = FWGridSyle(
            columnsInPortrait: columns,
            columnsInLandscape: columns,
            spacing: spacing,
            animation: animation
        )
        return self.environment(\.fwGridStyle, style)
    }
    
    /// Sets the scroll options for `FWWaterfallGrid` within the environment of `self`.
    ///
    /// - Parameters:
    ///   - direction: The scrollable axes. The default is `.vertical`.
    public func fwScrollOptions(direction: Axis.Set) -> some View {
        let options = FWScrollOptions(direction: direction)
        return self.environment(\.fwScrollOptions, options)
    }

}
