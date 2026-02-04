//
//  Item.swift
//  Safa
//
//  Created by Mansoor Aman on 04/02/2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
