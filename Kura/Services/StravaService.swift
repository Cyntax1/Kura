//
//  StravaService.swift
//  Kura
//
//  Strava API integration for workout tracking
//

import Foundation
import SwiftUI

class StravaService: ObservableObject {
    static let shared = StravaService()
    
    @Published var isConnected = false
    @Published var athlete: StravaAthlete?
    @Published var recentActivities: [StravaActivity] = []
    
    // Strava API Configuration
    private let clientID = "182251"
    private let clientSecret = "656b3683c9b6a79143c6f2038647369af17e71e8"
    private let redirectURI = "http://localhost" // Strava-approved redirect for mobile apps
    
    // Token storage
    private var accessToken: String? {
        get { UserDefaults.standard.string(forKey: "stravaAccessToken") }
        set { UserDefaults.standard.set(newValue, forKey: "stravaAccessToken") }
    }
    
    private var refreshToken: String? {
        get { UserDefaults.standard.string(forKey: "stravaRefreshToken") }
        set { UserDefaults.standard.set(newValue, forKey: "stravaRefreshToken") }
    }
    
    private var tokenExpiresAt: Date? {
        get {
            if let timestamp = UserDefaults.standard.object(forKey: "stravaTokenExpiresAt") as? TimeInterval {
                return Date(timeIntervalSince1970: timestamp)
            }
            return nil
        }
        set {
            UserDefaults.standard.set(newValue?.timeIntervalSince1970, forKey: "stravaTokenExpiresAt")
        }
    }
    
    init() {
        checkConnectionStatus()
    }
    
    // MARK: - Authentication
    
    func getAuthorizationURL() -> URL? {
        var components = URLComponents(string: "https://www.strava.com/oauth/mobile/authorize")
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "approval_prompt", value: "auto"),
            URLQueryItem(name: "scope", value: "read,activity:read")
        ]
        return components?.url
    }
    
    func handleAuthorizationCallback(code: String) async throws {
        let url = URL(string: "https://www.strava.com/oauth/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "client_id": clientID,
            "client_secret": clientSecret,
            "code": code,
            "grant_type": "authorization_code"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(StravaTokenResponse.self, from: data)
        
        await MainActor.run {
            self.accessToken = response.access_token
            self.refreshToken = response.refresh_token
            self.tokenExpiresAt = Date(timeIntervalSince1970: TimeInterval(response.expires_at))
            self.isConnected = true
            self.athlete = response.athlete
        }
        
        try await fetchRecentActivities()
    }
    
    func disconnect() {
        accessToken = nil
        refreshToken = nil
        tokenExpiresAt = nil
        isConnected = false
        athlete = nil
        recentActivities = []
    }
    
    private func checkConnectionStatus() {
        isConnected = accessToken != nil
        if isConnected {
            Task {
                try? await refreshTokenIfNeeded()
                try? await fetchRecentActivities()
            }
        }
    }
    
    private func refreshTokenIfNeeded() async throws {
        guard let tokenExpiresAt = tokenExpiresAt,
              Date() >= tokenExpiresAt.addingTimeInterval(-300), // Refresh 5 min before expiry
              let refreshToken = refreshToken else {
            return
        }
        
        let url = URL(string: "https://www.strava.com/oauth/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "client_id": clientID,
            "client_secret": clientSecret,
            "refresh_token": refreshToken,
            "grant_type": "refresh_token"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(StravaTokenResponse.self, from: data)
        
        await MainActor.run {
            self.accessToken = response.access_token
            self.refreshToken = response.refresh_token
            self.tokenExpiresAt = Date(timeIntervalSince1970: TimeInterval(response.expires_at))
        }
    }
    
    // MARK: - API Calls
    
    func fetchRecentActivities(page: Int = 1, perPage: Int = 30) async throws {
        try await refreshTokenIfNeeded()
        
        guard let accessToken = accessToken else {
            throw StravaError.notAuthenticated
        }
        
        var components = URLComponents(string: "https://www.strava.com/api/v3/athlete/activities")!
        components.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per_page", value: "\(perPage)")
        ]
        
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let activities = try JSONDecoder().decode([StravaActivity].self, from: data)
        
        await MainActor.run {
            self.recentActivities = activities
        }
    }
    
    func getWeeklyStats() -> (totalActivities: Int, totalCalories: Int, totalDistance: Double, totalTime: Int) {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let weeklyActivities = recentActivities.filter { activity in
            guard let date = activity.startDate else { return false }
            return date >= weekAgo
        }
        
        let totalCalories = weeklyActivities.reduce(0) { $0 + ($1.calories ?? 0) }
        let totalDistance = weeklyActivities.reduce(0.0) { $0 + $1.distance }
        let totalTime = weeklyActivities.reduce(0) { $0 + $1.moving_time }
        
        return (weeklyActivities.count, totalCalories, totalDistance / 1000, totalTime) // distance in km
    }
}

// MARK: - Models

struct StravaTokenResponse: Codable {
    let access_token: String
    let refresh_token: String
    let expires_at: Int
    let athlete: StravaAthlete?
}

struct StravaAthlete: Codable {
    let id: Int
    let firstname: String
    let lastname: String
    let profile_medium: String?
    let profile: String?
}

struct StravaActivity: Codable, Identifiable {
    let id: Int
    let name: String
    let distance: Double // meters
    let moving_time: Int // seconds
    let elapsed_time: Int // seconds
    let total_elevation_gain: Double // meters
    let type: String // Run, Ride, Swim, etc.
    let start_date: String
    let average_speed: Double? // m/s
    let max_speed: Double? // m/s
    let average_heartrate: Double?
    let max_heartrate: Double?
    let calories: Int?
    
    var startDate: Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: start_date)
    }
    
    var formattedDistance: String {
        let km = distance / 1000
        return String(format: "%.2f km", km)
    }
    
    var formattedDuration: String {
        let hours = moving_time / 3600
        let minutes = (moving_time % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
    
    var activityIcon: String {
        switch type.lowercased() {
        case "run": return "figure.run"
        case "ride", "virtualride", "ebikeride": return "bicycle"
        case "swim": return "figure.pool.swim"
        case "walk": return "figure.walk"
        case "hike": return "figure.hiking"
        case "workout", "weighttraining": return "dumbbell.fill"
        case "yoga": return "figure.mind.and.body"
        default: return "figure.mixed.cardio"
        }
    }
    
    var activityColor: Color {
        switch type.lowercased() {
        case "run": return .orange
        case "ride", "virtualride", "ebikeride": return .blue
        case "swim": return .cyan
        case "walk": return .green
        case "hike": return .brown
        case "workout", "weighttraining": return .purple
        case "yoga": return .pink
        default: return .gray
        }
    }
}

enum StravaError: Error, LocalizedError {
    case notAuthenticated
    case invalidResponse
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "Not connected to Strava"
        case .invalidResponse: return "Invalid response from Strava"
        case .networkError: return "Network error"
        }
    }
}
