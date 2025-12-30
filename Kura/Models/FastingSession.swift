//
//  FastingSession.swift
//  Kura
//
//  Created by Rishith Chennupati on 8/6/25.
//

import Foundation
import SwiftData

enum FastingType: String, CaseIterable, Codable {
    case twentyFourHour = "24 Hour Fast"
    case custom = "Custom Fast"
    case intermittent = "Intermittent Fast"
    case juice = "Juice Fast"
    case water = "Water Fast"
    case dry = "Dry Fast"
    
    var systemImage: String {
        switch self {
        case .twentyFourHour: return "clock.fill"
        case .custom: return "slider.horizontal.3"
        case .intermittent: return "timer"
        case .juice: return "drop.fill"
        case .water: return "drop.circle.fill"
        case .dry: return "sun.max.fill"
        }
    }
    
    var description: String {
        switch self {
        case .twentyFourHour: return "Complete 24-hour fast"
        case .custom: return "Set your own fasting duration"
        case .intermittent: return "16:8, 18:6, or custom eating windows"
        case .juice: return "Juice-only fasting period"
        case .water: return "Water-only fasting"
        case .dry: return "No food or water"
        }
    }
}

enum FastingStatus: String, Codable {
    case active = "active"
    case paused = "paused"
    case completed = "completed"
    case stopped = "stopped"
}

@Model
final class FastingSession {
    var id: UUID
    var type: FastingType
    var status: FastingStatus
    var startTime: Date
    var endTime: Date?
    var pausedTime: Date?
    var totalPausedDuration: TimeInterval
    var plannedDuration: TimeInterval // in seconds
    var actualDuration: TimeInterval
    var notes: String
    var createdAt: Date
    
    init(type: FastingType, plannedDuration: TimeInterval, notes: String = "") {
        self.id = UUID()
        self.type = type
        self.status = .active
        self.startTime = Date()
        self.endTime = nil
        self.pausedTime = nil
        self.totalPausedDuration = 0
        self.plannedDuration = plannedDuration
        self.actualDuration = 0
        self.notes = notes
        self.createdAt = Date()
    }
    
    var isActive: Bool {
        status == .active
    }
    
    var isPaused: Bool {
        status == .paused
    }
    
    var isCompleted: Bool {
        status == .completed
    }
    
    var currentDuration: TimeInterval {
        let now = Date()
        
        switch status {
        case .active:
            // Active: current time minus start time minus total paused duration
            let totalElapsed = now.timeIntervalSince(startTime)
            return max(0, totalElapsed - totalPausedDuration)
            
        case .paused:
            // Paused: time up to pause minus total previous paused duration
            guard let pausedTime = pausedTime else {
                return max(0, now.timeIntervalSince(startTime) - totalPausedDuration)
            }
            let elapsedUntilPause = pausedTime.timeIntervalSince(startTime)
            return max(0, elapsedUntilPause - totalPausedDuration)
            
        case .completed, .stopped:
            // Completed/Stopped: use stored actual duration
            return actualDuration > 0 ? actualDuration : max(0, now.timeIntervalSince(startTime) - totalPausedDuration)
        }
    }
    
    var remainingTime: TimeInterval {
        max(0, plannedDuration - currentDuration)
    }
    
    var progressPercentage: Double {
        min(1.0, currentDuration / plannedDuration)
    }
}
