//
//  SafaWidgetExtensionLiveActivity.swift
//  SafaWidgetExtension
//
//  Created by Mansoor Aman on 07/02/2026.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct SafaWidgetExtensionAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct SafaWidgetExtensionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SafaWidgetExtensionAttributes.self) { context in
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

extension SafaWidgetExtensionAttributes {
    fileprivate static var preview: SafaWidgetExtensionAttributes {
        SafaWidgetExtensionAttributes(name: "World")
    }
}

extension SafaWidgetExtensionAttributes.ContentState {
    fileprivate static var smiley: SafaWidgetExtensionAttributes.ContentState {
        SafaWidgetExtensionAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: SafaWidgetExtensionAttributes.ContentState {
         SafaWidgetExtensionAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: SafaWidgetExtensionAttributes.preview) {
   SafaWidgetExtensionLiveActivity()
} contentStates: {
    SafaWidgetExtensionAttributes.ContentState.smiley
    SafaWidgetExtensionAttributes.ContentState.starEyes
}
