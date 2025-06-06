//
//  Item.swift
//  clarity-loop-frontend
//
//  Created by Raymond Jung on 6/6/25.
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
