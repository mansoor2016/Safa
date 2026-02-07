//
//  SafaWidgetExtensionBundle.swift
//  SafaWidgetExtension
//
//  Created by Mansoor Aman on 07/02/2026.
//

import WidgetKit
import SwiftUI

@main
struct SafaWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        SafaWidgetExtension()
        SafaWidgetExtensionControl()
        SafaWidgetExtensionLiveActivity()
    }
}
