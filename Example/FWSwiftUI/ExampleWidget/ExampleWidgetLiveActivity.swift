//
//  ExampleWidgetLiveActivity.swift
//  ExampleWidget
//
//  Created by wuyong on 2024/9/4.
//

import ActivityKit
import SwiftUI
import WidgetKit

struct ExampleWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ExampleWidgetAttributes.self) { context in
            VStack(alignment: .leading) {
                HStack {
                    VStack(alignment: .center) {
                        Text(context.state.courierName + " is on the way!")
                            .font(.headline)
                        
                        Text("You ordered \(context.attributes.numberOfGroceyItems) grocery items.")
                            .font(.subheadline)
                        
                        HStack {
                            Divider()
                                .frame(width: 50, height: 10)
                            .overlay(.gray)
                            .cornerRadius(5)
                            
                            Image("delivery")
                            
                            VStack {
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [4]))
                                    .frame(height: 10)
                                    .overlay(
                                        Text(context.state.deliveryTime, style: .timer)
                                            .font(.system(size: 8))
                                            .multilineTextAlignment(.center)
                                    )
                            }
                            
                            Image("address")
                        }
                    }
                }
            }
            .padding(15)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack {
                        Label {
                            Text("\(context.attributes.numberOfGroceyItems)")
                                .font(.title2)
                        } icon: {
                            Image("grocery")
                                .foregroundColor(.green)
                        }
                        
                        Text("items")
                            .font(.title2)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Label {
                        Text(context.state.deliveryTime, style: .timer)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 50)
                            .monospacedDigit()
                    } icon: {
                        Image(systemName: "timer")
                            .foregroundColor(.green)
                    }
                    .font(.title2)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    let url = URL(string: "widget://?courierId=1")!
                    
                    Link(destination: url) {
                        Label("Call courier", systemImage: "phone")
                    }
                    .foregroundColor(.green)
                }
            } compactLeading: {
                VStack {
                    Label {
                        Text("\(context.attributes.numberOfGroceyItems) items")
                    } icon: {
                        Image("grocery")
                            .foregroundColor(.green)
                    }
                    .font(.caption2)
                }
            } compactTrailing: {
                Text(context.state.deliveryTime, style: .timer)
                    .multilineTextAlignment(.center)
                    .frame(width: 40)
                    .font(.caption2)
            } minimal: {
                VStack(alignment: .center) {
                    Image(systemName: "timer")
                    
                    Text(context.state.deliveryTime, style: .timer)
                        .multilineTextAlignment(.center)
                        .monospacedDigit()
                        .font(.caption2)
                }
            }
            .keylineTint(.cyan)
        }
    }
}

@available(iOS 17.0, *)
#Preview("Notification", as: .content, using: ExampleWidgetAttributes(numberOfGroceyItems: 12)) {
    ExampleWidgetLiveActivity()
} contentStates: {
    ExampleWidgetAttributes.ContentState(courierName: "Mike", deliveryTime: .now + 120)
}
