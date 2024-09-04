//
//  ExampleWidgetBundle.swift
//  ExampleWidget
//
//  Created by wuyong on 2024/9/4.
//

import WidgetKit
import SwiftUI

@main
struct ExampleWidgetBundle: WidgetBundle {
    var body: some Widget {
        ExampleWidget()
        ExampleWidgetLiveActivity()
    }
}
