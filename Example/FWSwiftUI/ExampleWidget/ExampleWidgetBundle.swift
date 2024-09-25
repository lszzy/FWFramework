//
//  ExampleWidgetBundle.swift
//  ExampleWidget
//
//  Created by wuyong on 2024/9/4.
//

import SwiftUI
import WidgetKit

@main
struct ExampleWidgetBundle: WidgetBundle {
    var body: some Widget {
        ExampleWidget()
        ExampleWidgetLiveActivity()
    }
}
