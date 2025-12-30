//
//  DateDetailView.swift
//  Kura
//
//  Created by Aaditya Shah on 8/6/25.
//

import SwiftUI
import SwiftData

struct DateDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var fastingSessions: [FastingSession]
    @Query private var foodEntries: [FoodEntry]
    
    let date: Date
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }()
    
    private var dayFoodEntries: [FoodEntry] {
        foodEntries.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
    }
    
    private var dayFastingSessions: [FastingSession] {
        fastingSessions.filter { session in
            calendar.isDate(session.startTime, inSameDayAs: date) ||
            (session.endTime != nil && calendar.isDate(session.endTime!, inSameDayAs: date))
        }
    }
    
    private var totalCalories: Int {
        dayFoodEntries.reduce(0) { $0 + $1.calories }
    }
    
    private var totalProtein: Double {
        dayFoodEntries.reduce(0) { $0 + $1.protein }
    }
    
    private var totalCarbs: Double {
        dayFoodEntries.reduce(0) { $0 + $1.carbs }
    }
    
    private var totalFat: Double {
        dayFoodEntries.reduce(0) { $0 + $1.fat }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "calendar.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text(dateFormatter.string(from: date))
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // Daily Summary
                    if !dayFoodEntries.isEmpty || !dayFastingSessions.isEmpty {
                        dailySummarySection
                    }
                    
                    // Fasting Sessions
                    if !dayFastingSessions.isEmpty {
                        fastingSessionsSection
                    }
                    
                    // Food Entries
                    if !dayFoodEntries.isEmpty {
                        foodEntriesSection
                    }
                    
                    // Empty State
                    if dayFoodEntries.isEmpty && dayFastingSessions.isEmpty {
                        emptyStateSection
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var dailySummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Summary")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 12) {
                SummaryMetric(
                    title: "Calories",
                    value: "\(totalCalories)",
                    unit: "cal",
                    color: .red
                )
                
                SummaryMetric(
                    title: "Meals",
                    value: "\(dayFoodEntries.count)",
                    unit: "logged",
                    color: .green
                )
                
                SummaryMetric(
                    title: "Fasts",
                    value: "\(dayFastingSessions.count)",
                    unit: "sessions",
                    color: .blue
                )
            }
            
            if !dayFoodEntries.isEmpty {
                // Macro breakdown
                HStack(spacing: 12) {
                    MacroMetric(
                        title: "Protein",
                        value: Int(totalProtein),
                        unit: "g",
                        color: .red
                    )
                    
                    MacroMetric(
                        title: "Carbs",
                        value: Int(totalCarbs),
                        unit: "g",
                        color: .orange
                    )
                    
                    MacroMetric(
                        title: "Fat",
                        value: Int(totalFat),
                        unit: "g",
                        color: .yellow
                    )
                }
            }
        }
    }
    
    private var fastingSessionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Fasting Sessions")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ForEach(dayFastingSessions, id: \.id) { session in
                    FastingSessionCard(session: session, date: date)
                }
            }
        }
    }
    
    private var foodEntriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Food Entries")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Group by meal type
            ForEach(MealType.allCases, id: \.self) { mealType in
                let mealEntries = dayFoodEntries.filter { $0.mealType == mealType }
                
                if !mealEntries.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: mealType.systemImage)
                                .foregroundColor(.blue)
                            
                            Text(mealType.rawValue)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Text("\(mealEntries.reduce(0) { $0 + $1.calories }) cal")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 6) {
                            ForEach(mealEntries, id: \.id) { entry in
                                FoodEntryDetailRow(entry: entry)
                            }
                        }
                        .padding(.leading, 24)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
            }
        }
    }
    
    private var emptyStateSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Activity")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("No fasting sessions or food entries were logged on this day.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 40)
    }
}

struct SummaryMetric: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct MacroMetric: View {
    let title: String
    let value: Int
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 2) {
                Text("\(value)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(unit)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct FastingSessionCard: View {
    let session: FastingSession
    let date: Date
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: session.type.systemImage)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(session.type.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                HStack {
                    Text("Started: \(timeFormatter.string(from: session.startTime))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let endTime = session.endTime {
                        Text("• Ended: \(timeFormatter.string(from: endTime))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatDuration(session.actualDuration))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                
                Text(session.status.rawValue.capitalized)
                    .font(.caption2)
                    .foregroundColor(statusColor(session.status))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(statusColor(session.status).opacity(0.2))
                    .cornerRadius(4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func statusColor(_ status: FastingStatus) -> Color {
        switch status {
        case .active: return .green
        case .paused: return .orange
        case .completed: return .blue
        case .stopped: return .red
        }
    }
}

struct FoodEntryDetailRow: View {
    let entry: FoodEntry
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        HStack(spacing: 8) {
            if let imageData = entry.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("\(Int(entry.quantity)) \(entry.unit) • \(timeFormatter.string(from: entry.timestamp))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(entry.calories) cal")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    DateDetailView(date: Date())
        .modelContainer(for: [FastingSession.self, FoodEntry.self])
}
