//
//  Item.swift
//  Kura
//
//  Created by Aaditya Shah on 8/6/25.
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
