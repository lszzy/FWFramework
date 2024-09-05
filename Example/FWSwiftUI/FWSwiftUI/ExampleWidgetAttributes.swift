//
//  ExampleWidgetAttributes.swift
//  FWSwiftUI
//
//  Created by wuyong on 2024/9/5.
//

import ActivityKit
import SwiftUI

struct ExampleWidgetAttributes: ActivityAttributes, Identifiable {
    public struct ContentState: Codable, Hashable {
        var courierName: String
        var deliveryTime: Date
    }

    var id = UUID()
    var numberOfGroceyItems: Int
}
