//
//  SafaWidgetBundle.swift
//  SafaWidget
//
//  Created by Mansoor Aman on 07/02/2026.
//

import WidgetKit
import SwiftUI

@main
struct SafaWidgetBundle: WidgetBundle {
    var body: some Widget {
        SafaWidget()
        SafaWidgetControl()
        SafaWidgetLiveActivity()
    }
}
