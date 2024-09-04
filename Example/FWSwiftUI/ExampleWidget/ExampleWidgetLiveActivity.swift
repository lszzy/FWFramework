//
//  ExampleWidgetLiveActivity.swift
//  ExampleWidget
//
//  Created by wuyong on 2024/9/4.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct ExampleWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct ExampleWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ExampleWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension ExampleWidgetAttributes {
    fileprivate static var preview: ExampleWidgetAttributes {
        ExampleWidgetAttributes(name: "World")
    }
}

extension ExampleWidgetAttributes.ContentState {
    fileprivate static var smiley: ExampleWidgetAttributes.ContentState {
        ExampleWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: ExampleWidgetAttributes.ContentState {
         ExampleWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: ExampleWidgetAttributes.preview) {
   ExampleWidgetLiveActivity()
} contentStates: {
    ExampleWidgetAttributes.ContentState.smiley
    ExampleWidgetAttributes.ContentState.starEyes
}
