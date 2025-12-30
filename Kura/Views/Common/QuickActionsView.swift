//
//  QuickActionsView.swift
//  Kura
//
//  Created by Aaditya Shah on 8/6/25.
//

import SwiftUI
import SwiftData

struct QuickActionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var activeFastingSessions: [FastingSession]
    @State private var showingFastingStart = false
    @State private var showingFoodCamera = false
    @State private var selectedMealType: MealType = .breakfast
    @State private var showingWaterLog = false
    @State private var waterLogged = false
    @State private var waterAmount: Double = 250.0
    
    private var suggestedMealType: MealType {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<11:
            return .breakfast
        case 11..<16:
            return .lunch
        case 16..<22:
            return .dinner
        default:
            return .snack
        }
    }
    
    init() {
        // Only fetch active fasting sessions
        _activeFastingSessions = Query()
    }
    
    private var activeSessionsFiltered: [FastingSession] {
        activeFastingSessions.filter { $0.status == .active || $0.status == .paused }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                // Start/Resume Fasting
                QuickActionCard(
                    icon: activeSessionsFiltered.isEmpty ? "play.circle.fill" : "pause.circle.fill",
                    title: activeSessionsFiltered.isEmpty ? "Start Fast" : "Manage Fast",
                    subtitle: activeSessionsFiltered.isEmpty ? "Begin fasting" : "View progress",
                    color: .blue,
                    action: {
                        if activeSessionsFiltered.isEmpty {
                            showingFastingStart = true
                        } else {
                            // Navigate to active session
                        }
                    }
                )
                
                // Log Breakfast
                QuickActionCard(
                    icon: "sunrise.fill",
                    title: "Breakfast",
                    subtitle: suggestedMealType == .breakfast ? "Suggested" : "Log meal",
                    color: suggestedMealType == .breakfast ? .blue : .orange,
                    action: {
                        selectedMealType = .breakfast
                        showingFoodCamera = true
                    }
                )
                
                // Log Lunch
                QuickActionCard(
                    icon: "sun.max.fill",
                    title: "Lunch",
                    subtitle: suggestedMealType == .lunch ? "Suggested" : "Log meal",
                    color: suggestedMealType == .lunch ? .blue : .yellow,
                    action: {
                        selectedMealType = .lunch
                        showingFoodCamera = true
                    }
                )
                
                // Log Dinner
                QuickActionCard(
                    icon: "moon.fill",
                    title: "Dinner",
                    subtitle: suggestedMealType == .dinner ? "Suggested" : "Log meal",
                    color: suggestedMealType == .dinner ? .blue : .purple,
                    action: {
                        selectedMealType = .dinner
                        showingFoodCamera = true
                    }
                )
                
                // Log Snack
                QuickActionCard(
                    icon: "leaf.fill",
                    title: "Snack",
                    subtitle: suggestedMealType == .snack ? "Suggested" : "Log snack",
                    color: suggestedMealType == .snack ? .blue : .green,
                    action: {
                        selectedMealType = .snack
                        showingFoodCamera = true
                    }
                )
                
                // Water Reminder
                QuickActionCard(
                    icon: waterLogged ? "checkmark.circle.fill" : "drop.fill",
                    title: "Log Water",
                    subtitle: waterLogged ? "Logged!" : "Track intake",
                    color: waterLogged ? .green : .cyan,
                    action: {
                        showingWaterLog = true
                    }
                )
            }
        }
        .sheet(isPresented: $showingFastingStart) {
            StartFastingView()
        }
        .sheet(isPresented: $showingFoodCamera) {
            NativeCameraView(selectedMealType: selectedMealType)
        }
        .sheet(isPresented: $showingWaterLog) {
            WaterLogView(onLog: { amount in
                logWater(amount: amount)
            })
        }
    }
    
    private func logWater(amount: Double) {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Create water intake entry
        let waterEntry = WaterIntake(amount: amount)
        modelContext.insert(waterEntry)
        
        do {
            try modelContext.save()
            print("💧 Logged \(amount)ml of water")
            
            // Show success feedback
            withAnimation {
                waterLogged = true
            }
            
            // Reset after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    waterLogged = false
                }
            }
        } catch {
            print("❌ Failed to log water: \(error.localizedDescription)")
        }
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    QuickActionsView()
        .modelContainer(for: [FastingSession.self])
        .padding()
}
