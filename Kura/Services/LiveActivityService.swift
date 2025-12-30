//
//  LiveActivityService.swift
//  Kura
//
//  Created by Rishith Chennupati on 9/26/25.
//

import ActivityKit
import Foundation

@Observable
class LiveActivityService {
    static let shared = LiveActivityService()
    
    private var currentActivity: Activity<FastingAttributes>?
    
    private init() {}
    
    // MARK: - Live Activity Management
    
    func startLiveActivity(for session: FastingSession) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are not enabled")
            return
        }
        
        // End any existing activity first
        endCurrentActivity()
        
        let attributes = FastingAttributes(
            fastingType: session.type,
            plannedDuration: session.plannedDuration,
            startTime: session.startTime,
            sessionId: session.id.uuidString
        )
        
        let contentState = FastingAttributes.ContentState(
            currentDuration: session.currentDuration,
            remainingTime: session.remainingTime,
            progressPercentage: session.progressPercentage,
            status: session.status,
            isPaused: session.isPaused
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil),
                pushType: nil
            )
            
            currentActivity = activity
            print("Live Activity started successfully")
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }
    
    func updateLiveActivity(for session: FastingSession) {
        guard let activity = currentActivity else {
            print("No active Live Activity to update")
            return
        }
        
        // Check if this is the same session
        guard activity.attributes.sessionId == session.id.uuidString else {
            print("Session ID mismatch, starting new Live Activity")
            startLiveActivity(for: session)
            return
        }
        
        let contentState = FastingAttributes.ContentState(
            currentDuration: session.currentDuration,
            remainingTime: session.remainingTime,
            progressPercentage: session.progressPercentage,
            status: session.status,
            isPaused: session.isPaused
        )
        
        Task {
            await activity.update(.init(state: contentState, staleDate: nil))
        }
    }
    
    func endLiveActivity(reason: ActivityUIDismissalPolicy = .default) {
        guard let activity = currentActivity else {
            print("No active Live Activity to end")
            return
        }
        
        Task {
            await activity.end(
                .init(state: activity.content.state, staleDate: Date()),
                dismissalPolicy: reason
            )
        }
        
        currentActivity = nil
        print("Live Activity ended")
    }
    
    func endCurrentActivity() {
        if currentActivity != nil {
            endLiveActivity()
        }
    }
    
    // MARK: - Activity Status
    
    var hasActiveActivity: Bool {
        return currentActivity != nil
    }
    
    var activityState: ActivityState? {
        return currentActivity?.activityState
    }
    
    // MARK: - Permissions
    
    func requestLiveActivityPermission() async -> Bool {
        let authInfo = ActivityAuthorizationInfo()
        
        if authInfo.areActivitiesEnabled {
            return true
        }
        
        // Activities are controlled by system settings
        // We can't programmatically request permission
        // User needs to enable in Settings > [App Name] > Live Activities
        return false
    }
    
    func checkLiveActivityPermission() -> Bool {
        return ActivityAuthorizationInfo().areActivitiesEnabled
    }
}

// MARK: - Extensions

extension FastingSession {
    var liveActivityContentState: FastingAttributes.ContentState {
        return FastingAttributes.ContentState(
            currentDuration: currentDuration,
            remainingTime: remainingTime,
            progressPercentage: progressPercentage,
            status: status,
            isPaused: isPaused
        )
    }
}
