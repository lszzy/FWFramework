//
//  WaterfallGrid.swift
//  FWFramework
//
//  Created by wuyong on 2025/3/11.
//

#if canImport(SwiftUI)
import SwiftUI

// MARK: - WaterfallGrid
/// [WaterfallGrid](https://github.com/paololeonardi/WaterfallGrid)
public struct WaterfallGrid<Data, ID, Content>: View where Data: RandomAccessCollection, Content: View, ID: Hashable {
    @Environment(\.gridStyle) private var style
    @Environment(\.scrollOptions) private var scrollOptions

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
                let styleConfig = self.style
                let scrollConfig = self.scrollOptions
                grid(in: geometry)
                    .onPreferenceChange(ElementPreferenceKey.self, perform: { preferences in
                        let sendablePreferences = SendableValue(preferences)
                        DispatchQueue.global(qos: .userInteractive).async {
                            let (alignmentGuides, gridHeight) = alignmentsAndGridHeight(columns: styleConfig.columns,
                                                                                        spacing: styleConfig.spacing,
                                                                                        scrollDirection: scrollConfig.direction,
                                                                                        preferences: sendablePreferences.value)
                            DispatchQueue.main.async {
                                self.alignmentGuides = alignmentGuides
                                self.gridHeight = gridHeight
                            }
                        }
                    })
            }
        }
        .frame(width: scrollOptions.direction == .horizontal ? gridHeight : nil,
               height: scrollOptions.direction == .vertical ? gridHeight : nil)
    }

    private func grid(in geometry: GeometryProxy) -> some View {
        let columnWidth = columnWidth(columns: style.columns, spacing: style.spacing,
                                      scrollDirection: scrollOptions.direction, geometrySize: geometry.size)
        return
            ZStack(alignment: .topLeading) {
                ForEach(data, id: dataId) { element in
                    let guideValue = alignmentGuides[element[keyPath: dataId]]
                    content(element)
                        .frame(width: scrollOptions.direction == .vertical ? columnWidth : nil,
                               height: scrollOptions.direction == .horizontal ? columnWidth : nil)
                        .background(PreferenceSetter(id: element[keyPath: dataId]))
                        .alignmentGuide(.top, computeValue: { _ in guideValue?.y ?? 0 })
                        .alignmentGuide(.leading, computeValue: { _ in guideValue?.x ?? 0 })
                        .opacity(guideValue != nil ? 1 : 0)
                }
            }
            .animation(loaded ? style.animation : nil, value: UUID())
    }

    // MARK: - Helpers
    nonisolated func alignmentsAndGridHeight(columns: Int, spacing: CGFloat, scrollDirection: Axis.Set, preferences: [ElementPreferenceData]) -> ([AnyHashable: CGPoint], CGFloat) {
        var heights = Array(repeating: CGFloat(0), count: columns)
        var alignmentGuides = [AnyHashable: CGPoint]()

        for preference in preferences {
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

        let gridHeight = max(0, (heights.max() ?? spacing) - spacing)

        return (alignmentGuides, gridHeight)
    }

    func columnWidth(columns: Int, spacing: CGFloat, scrollDirection: Axis.Set, geometrySize: CGSize) -> CGFloat {
        let geometrySizeWidth = scrollDirection == .vertical ? geometrySize.width : geometrySize.height
        let width = max(0, geometrySizeWidth - (spacing * (CGFloat(columns) - 1)))
        return width / CGFloat(columns)
    }
}

// MARK: - Initializers
extension WaterfallGrid {
    public init(_ data: Data, id: KeyPath<Data.Element, ID>, content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.dataId = id
        self.content = content
    }
}

extension WaterfallGrid where ID == Data.Element.ID, Data.Element: Identifiable {
    public init(_ data: Data, content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.dataId = \Data.Element.id
        self.content = content
    }
}

// MARK: - ScrollOptions
extension View {
    public func scrollOptions(direction: Axis.Set) -> some View {
        let options = ScrollOptions(direction: direction)
        return environment(\.scrollOptions, options)
    }
}

// MARK: - GridStyle
extension View {
    public func gridStyle(
        columns: Int = 2,
        spacing: CGFloat = 8,
        animation: Animation? = .default
    ) -> some View {
        let style = GridSyle(
            columnsInPortrait: columns,
            columnsInLandscape: columns,
            spacing: spacing,
            animation: animation
        )
        return environment(\.gridStyle, style)
    }

    public func gridStyle(
        columnsInPortrait: Int = 2,
        columnsInLandscape: Int = 2,
        spacing: CGFloat = 8,
        animation: Animation? = .default
    ) -> some View {
        let style = GridSyle(
            columnsInPortrait: columnsInPortrait,
            columnsInLandscape: columnsInLandscape,
            spacing: spacing,
            animation: animation
        )
        return environment(\.gridStyle, style)
    }
}

struct PreferenceSetter<ID: Hashable>: View {
    var id: ID
    var body: some View {
        GeometryReader { geometry in
            Color.clear
                .preference(key: ElementPreferenceKey.self, value: [ElementPreferenceData(id: AnyHashable(id), size: geometry.size)])
        }
    }
}

struct ElementPreferenceData: Equatable {
    let id: AnyHashable
    let size: CGSize
}

struct ElementPreferenceKey: PreferenceKey {
    typealias Value = [ElementPreferenceData]

    static var defaultValue: [ElementPreferenceData] { [] }

    static func reduce(value: inout [ElementPreferenceData], nextValue: () -> [ElementPreferenceData]) {
        value.append(contentsOf: nextValue())
    }
}

struct ScrollOptions {
    let direction: Axis.Set
}

struct ScrollOptionsKey: EnvironmentKey {
    static let defaultValue = ScrollOptions(direction: .vertical)
}

extension EnvironmentValues {
    var scrollOptions: ScrollOptions {
        get { self[ScrollOptionsKey.self] }
        set { self[ScrollOptionsKey.self] = newValue }
    }
}

@propertyWrapper
struct PositiveNumber {
    private var value: Int = 1

    var wrappedValue: Int {
        get { value }
        set { value = max(1, newValue) }
    }

    init(wrappedValue initialValue: Int) {
        self.wrappedValue = initialValue
    }
}

struct GridSyle {
    @PositiveNumber var columnsInPortrait: Int
    @PositiveNumber var columnsInLandscape: Int

    let spacing: CGFloat
    let animation: Animation?

    var columns: Int {
        let screenSize = UIScreen.fw.screenSize
        return screenSize.width > screenSize.height ? columnsInLandscape : columnsInPortrait
    }
}

struct GridStyleKey: EnvironmentKey {
    static let defaultValue = GridSyle(columnsInPortrait: 2, columnsInLandscape: 2,
                                       spacing: 8, animation: .default)
}

extension EnvironmentValues {
    var gridStyle: GridSyle {
        get { self[GridStyleKey.self] }
        set { self[GridStyleKey.self] = newValue }
    }
}

#endif
