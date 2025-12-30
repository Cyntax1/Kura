//
//  CalendarView.swift
//  Kura
//
//  Created by Rishith Chennupati on 8/6/25.
//

import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var fastingSessions: [FastingSession]
    @Query private var dietPlans: [DietPlan]
    @Query private var foodEntries: [FoodEntry]
    
    @State private var selectedDate = Date()
    @State private var showingDateDetail = false
    
    private var activeFastingSession: FastingSession? {
        fastingSessions.first { $0.isActive || $0.isPaused }
    }
    
    private var activeDietPlan: DietPlan? {
        dietPlans.first { $0.isActive }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Current Status Cards
                    currentStatusSection
                    
                    // Calendar View
                    calendarSection
                    
                    // Selected Date Details
                    selectedDateSection
                    
                    // Upcoming Goals
                    upcomingGoalsSection
                }
                .padding()
            }
            .navigationTitle("Calendar")
        }
        .sheet(isPresented: $showingDateDetail) {
            DateDetailView(date: selectedDate)
        }
    }
    
    private var currentStatusSection: some View {
        VStack(spacing: 12) {
            // Active Fast Card
            if let activeSession = activeFastingSession {
                ActiveSessionCard(
                    title: "Active Fast",
                    subtitle: activeSession.type.rawValue,
                    timeRemaining: activeSession.remainingTime,
                    progress: activeSession.progressPercentage,
                    color: .blue,
                    icon: "clock.fill"
                )
            }
            
            // Active Diet Card
            if let activeDiet = activeDietPlan {
                ActiveSessionCard(
                    title: "Active Diet",
                    subtitle: activeDiet.name,
                    timeRemaining: activeDiet.daysRemaining != nil ? TimeInterval(activeDiet.daysRemaining! * 24 * 3600) : nil,
                    progress: nil,
                    color: .green,
                    icon: "leaf.fill"
                )
            }
        }
    }
    
    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Calendar")
                .font(.headline)
                .fontWeight(.semibold)
            
            CalendarGrid(
                selectedDate: $selectedDate,
                fastingSessions: fastingSessions,
                dietPlans: dietPlans,
                foodEntries: foodEntries
            )
        }
    }
    
    private var selectedDateSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Selected Date")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View Details") {
                    showingDateDetail = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            DateSummaryCard(
                date: selectedDate,
                fastingSessions: fastingSessions,
                foodEntries: foodEntries
            )
        }
    }
    
    private var upcomingGoalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Upcoming Goals")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                if let activeSession = activeFastingSession {
                    UpcomingGoalCard(
                        title: "Fast Completion",
                        subtitle: activeSession.type.rawValue,
                        targetDate: Date(timeIntervalSinceNow: activeSession.remainingTime),
                        icon: "checkmark.circle.fill",
                        color: .blue
                    )
                }
                
                if let activeDiet = activeDietPlan,
                   let endDate = activeDiet.endDate {
                    UpcomingGoalCard(
                        title: "Diet Plan End",
                        subtitle: activeDiet.name,
                        targetDate: endDate,
                        icon: "flag.checkered",
                        color: .green
                    )
                }
                
                // Weekly streak goals
                UpcomingGoalCard(
                    title: "Weekly Streak",
                    subtitle: "7 days of consistent tracking",
                    targetDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
                    icon: "flame.fill",
                    color: .orange
                )
            }
        }
    }
}

struct ActiveSessionCard: View {
    let title: String
    let subtitle: String
    let timeRemaining: TimeInterval?
    let progress: Double?
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let timeRemaining = timeRemaining {
                    Text(formatTimeRemaining(timeRemaining))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                    
                    Text("remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Ongoing")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func formatTimeRemaining(_ timeInterval: TimeInterval) -> String {
        let days = Int(timeInterval) / (24 * 3600)
        let hours = Int(timeInterval) % (24 * 3600) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        
        if days > 0 {
            return "\(days)d \(hours)h"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct CalendarGrid: View {
    @Binding var selectedDate: Date
    let fastingSessions: [FastingSession]
    let dietPlans: [DietPlan]
    let foodEntries: [FoodEntry]
    
    @State private var currentMonth = Date()
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 16) {
            // Month navigation
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text(dateFormatter.string(from: currentMonth))
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
            
            // Days of week header
            HStack {
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(daysInMonth, id: \.self) { date in
                    if let date = date {
                        CalendarDayView(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDate(date, inSameDayAs: Date()),
                            hasActivity: hasActivityOnDate(date),
                            onTap: { selectedDate = date }
                        )
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else {
            return []
        }
        
        let firstOfMonth = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let numberOfDaysInMonth = calendar.range(of: .day, in: .month, for: currentMonth)?.count ?? 0
        
        var days: [Date?] = []
        
        // Add empty cells for days before the first day of the month
        for _ in 1..<firstWeekday {
            days.append(nil)
        }
        
        // Add days of the month
        for day in 1...numberOfDaysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
    
    private func hasActivityOnDate(_ date: Date) -> Bool {
        let hasFasting = fastingSessions.contains { session in
            calendar.isDate(session.startTime, inSameDayAs: date) ||
            (session.endTime != nil && calendar.isDate(session.endTime!, inSameDayAs: date))
        }
        
        let hasFood = foodEntries.contains { entry in
            calendar.isDate(entry.timestamp, inSameDayAs: date)
        }
        
        return hasFasting || hasFood
    }
    
    private func previousMonth() {
        withAnimation {
            currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        }
    }
    
    private func nextMonth() {
        withAnimation {
            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        }
    }
}

struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasActivity: Bool
    let onTap: () -> Void
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 36, height: 36)
                
                Text(dayFormatter.string(from: date))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(textColor)
                
                if hasActivity {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 6, height: 6)
                        .offset(x: 12, y: -12)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return .blue
        } else if isToday {
            return .blue.opacity(0.2)
        } else {
            return .clear
        }
    }
    
    private var textColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return .blue
        } else {
            return .primary
        }
    }
}

struct DateSummaryCard: View {
    let date: Date
    let fastingSessions: [FastingSession]
    let foodEntries: [FoodEntry]
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }()
    
    private var dayFoodEntries: [FoodEntry] {
        foodEntries.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
    }
    
    private var dayCalories: Int {
        dayFoodEntries.reduce(0) { $0 + $1.calories }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(dateFormatter.string(from: date))
                .font(.headline)
                .fontWeight(.semibold)
            
            if dayFoodEntries.isEmpty {
                Text("No food logged on this day")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Total Calories: \(dayCalories)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Meals logged: \(dayFoodEntries.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct UpcomingGoalCard: View {
    let title: String
    let subtitle: String
    let targetDate: Date
    let icon: String
    let color: Color
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(dateFormatter.string(from: targetDate))
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.trailing)
                
                Text(timeUntilTarget)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var timeUntilTarget: String {
        let timeInterval = targetDate.timeIntervalSinceNow
        let days = Int(timeInterval) / (24 * 3600)
        
        if days > 0 {
            return "in \(days) day\(days == 1 ? "" : "s")"
        } else if days == 0 {
            return "today"
        } else {
            return "overdue"
        }
    }
}

#Preview {
    CalendarView()
        .modelContainer(for: [FastingSession.self, DietPlan.self, FoodEntry.self])
}
