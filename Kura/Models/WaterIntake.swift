//
//  WaterIntake.swift
//  Kura
//
//  Water intake tracking model
//

import Foundation
import SwiftData

@Model
final class WaterIntake {
    var id: UUID
    var date: Date
    var amount: Double // in ml
    var timestamp: Date
    
    init(amount: Double = 250.0, date: Date = Date()) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.amount = amount
        self.timestamp = Date()
    }
    
    // Common water amounts
    static let cupSize: Double = 250.0 // 250ml cup
    static let glassSize: Double = 350.0 // 350ml glass
    static let bottleSize: Double = 500.0 // 500ml bottle
    static let largeBottleSize: Double = 1000.0 // 1L bottle
    
    // Daily goal in ml (2 liters = 2000ml)
    static let dailyGoal: Double = 2000.0
}
