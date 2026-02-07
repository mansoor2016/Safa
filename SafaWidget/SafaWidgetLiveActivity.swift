//
//  SafaWidgetLiveActivity.swift
//  SafaWidget
//
//  Created by Mansoor Aman on 07/02/2026.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct SafaWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct SafaWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SafaWidgetAttributes.self) { context in
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

extension SafaWidgetAttributes {
    fileprivate static var preview: SafaWidgetAttributes {
        SafaWidgetAttributes(name: "World")
    }
}

extension SafaWidgetAttributes.ContentState {
    fileprivate static var smiley: SafaWidgetAttributes.ContentState {
        SafaWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: SafaWidgetAttributes.ContentState {
         SafaWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: SafaWidgetAttributes.preview) {
   SafaWidgetLiveActivity()
} contentStates: {
    SafaWidgetAttributes.ContentState.smiley
    SafaWidgetAttributes.ContentState.starEyes
}
