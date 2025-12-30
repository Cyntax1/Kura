//
//  DietMainView.swift
//  Kura
//
//  Created by Rishith Chennupati on 8/6/25.
//

import SwiftUI
import SwiftData

struct DietMainView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var dietPlans: [DietPlan]
    @Query private var foodEntries: [FoodEntry]
    @Query private var streakData: [StreakData]
    @Query private var userProfiles: [UserProfile]
    
    @State private var showingStartDiet = false
    @State private var showingFoodLog = false
    @State private var showingCamera = false
    @State private var showingProfile = false
    @State private var showingQuickLog = false
    @State private var selectedMealType: MealType = .breakfast
    
    private var activeDietPlan: DietPlan? {
        dietPlans.first { $0.isActive }
    }
    
    private var dietStreak: StreakData? {
        streakData.first { $0.type == .dieting }
    }
    
    private var todayEntries: [FoodEntry] {
        let calendar = Calendar.current
        return foodEntries.filter { calendar.isDate($0.timestamp, inSameDayAs: Date()) }
    }
    
    private var todayCalories: Int {
        todayEntries.reduce(0) { $0 + $1.calories }
    }
    
    private var todayProtein: Double {
        todayEntries.reduce(0) { $0 + $1.protein }
    }
    
    private var todayCarbs: Double {
        todayEntries.reduce(0) { $0 + $1.carbs }
    }
    
    private var todayFat: Double {
        todayEntries.reduce(0) { $0 + $1.fat }
    }
    
    private var userProfile: UserProfile? {
        userProfiles.first
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Calorie Balance (Consumed vs Burned)
                    CalorieBalanceCard()
                    
                    // Active Diet Plan or Start New Diet
                    if let activeDiet = activeDietPlan {
                        activeDietSection(activeDiet)
                    } else {
                        startDietSection
                    }
                    
                    // Today's Progress
                    todaysProgressSection
                    
                    // Quick Food Logging
                    quickFoodLoggingSection
                    
                    // Meal Breakdown
                    mealBreakdownSection
                    
                    // Diet Types Quick Access
                    dietTypesSection
                    
                    // Nutrition Insights
                    nutritionInsightsSection
                }
                .padding()
            }
            .navigationTitle("Diet & Nutrition")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button(action: { showingQuickLog = true }) {
                            Label("Quick Log (Text)", systemImage: "text.bubble")
                        }
                        
                        Button(action: { showingCamera = true }) {
                            Label("Scan Food (Camera)", systemImage: "camera")
                        }
                        
                        Divider()
                        
                        Button(action: { showingFoodLog = true }) {
                            Label("Manual Entry", systemImage: "list.bullet")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingProfile = true }) {
                        if let imageData = userProfile?.profileImageData,
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingStartDiet) {
            StartDietView()
        }
        .sheet(isPresented: $showingFoodLog) {
            FoodLogView()
        }
        .sheet(isPresented: $showingCamera) {
            NativeCameraView(selectedMealType: selectedMealType)
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView()
        }
        .sheet(isPresented: $showingQuickLog) {
            QuickFoodLogView(selectedMealType: selectedMealType)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Your Nutrition Journey")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if let streak = dietStreak {
                Text("\(streak.currentStreak) day streak 🥗")
                    .font(.headline)
                    .foregroundColor(.green)
            }
        }
    }
    
    private func activeDietSection(_ diet: DietPlan) -> some View {
        VStack(spacing: 16) {
            // Diet Header
            HStack {
                Image(systemName: diet.type.systemImage)
                    .font(.title)
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(diet.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(diet.type.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let daysRemaining = diet.daysRemaining {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(daysRemaining)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        
                        Text("days left")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Calorie Progress Ring
            CalorieProgressRing(
                current: todayCalories,
                goal: diet.dailyCalorieGoal,
                protein: Int(todayProtein),
                proteinGoal: diet.proteinGoal,
                carbs: Int(todayCarbs),
                carbGoal: diet.carbGoal,
                fat: Int(todayFat),
                fatGoal: diet.fatGoal
            )
            
            // Quick Actions
            HStack(spacing: 12) {
                Button(action: { showingCamera = true }) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Scan Food")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                NavigationLink(destination: DietDetailView(dietPlan: diet)) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                        Text("View Details")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.green.opacity(0.1), Color.mint.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    private var startDietSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "leaf.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Start Your Diet Journey")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Choose from 15+ diet types and track your nutrition goals with precision.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: { showingStartDiet = true }) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Choose Diet Plan")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private var todaysProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Progress")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 12) {
                NutritionCard(
                    title: "Calories",
                    current: todayCalories,
                    goal: activeDietPlan?.dailyCalorieGoal ?? 2000,
                    unit: "cal",
                    color: .red,
                    icon: "flame.fill"
                )
                
                NutritionCard(
                    title: "Protein",
                    current: Int(todayProtein),
                    goal: activeDietPlan?.proteinGoal ?? 150,
                    unit: "g",
                    color: .blue,
                    icon: "dumbbell.fill"
                )
            }
            
            HStack(spacing: 12) {
                NutritionCard(
                    title: "Carbs",
                    current: Int(todayCarbs),
                    goal: activeDietPlan?.carbGoal ?? 200,
                    unit: "g",
                    color: .orange,
                    icon: "leaf.fill"
                )
                
                NutritionCard(
                    title: "Fat",
                    current: Int(todayFat),
                    goal: activeDietPlan?.fatGoal ?? 100,
                    unit: "g",
                    color: .yellow,
                    icon: "drop.fill"
                )
            }
        }
    }
    
    private var quickFoodLoggingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Food Logging")
                .font(.headline)
                .fontWeight(.semibold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(MealType.allCases, id: \.self) { mealType in
                        MealTypeCard(mealType: mealType) {
                            selectedMealType = mealType
                            showingCamera = true
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var mealBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Meals")
                .font(.headline)
                .fontWeight(.semibold)
            
            if todayEntries.isEmpty {
                Text("No meals logged today. Start by scanning or adding your first meal!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .italic()
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            } else {
                VStack(spacing: 8) {
                    ForEach(MealType.allCases, id: \.self) { mealType in
                        let mealEntries = todayEntries.filter { $0.mealType == mealType }
                        if !mealEntries.isEmpty {
                            MealSummaryRow(
                                mealType: mealType,
                                entries: mealEntries
                            )
                        }
                    }
                }
            }
        }
    }
    
    private var dietTypesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Popular Diet Types")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("See All") {
                    showingStartDiet = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach([DietType.keto, .paleo, .mediterranean, .vegan, .lowCarb], id: \.self) { type in
                        DietTypeQuickCard(type: type) {
                            // Quick start this diet type
                            startQuickDiet(type: type)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var nutritionInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Nutrition Insights")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                InsightCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Weekly Average",
                    value: "\(weeklyAverageCalories) cal/day",
                    color: .blue
                )
                
                InsightCard(
                    icon: "target",
                    title: "Goal Achievement",
                    value: "\(goalAchievementRate)% this week",
                    color: goalAchievementRate >= 80 ? .green : .orange
                )
                
                InsightCard(
                    icon: "fork.knife",
                    title: "Meals Logged",
                    value: "\(todayEntries.count) today",
                    color: .purple
                )
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
    
    // MARK: - Computed Properties
    
    private var weeklyAverageCalories: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let weekEntries = foodEntries.filter { $0.timestamp >= weekAgo }
        
        guard !weekEntries.isEmpty else { return 0 }
        
        let totalCalories = weekEntries.reduce(0) { $0 + $1.calories }
        return totalCalories / 7
    }
    
    private var goalAchievementRate: Int {
        guard let goal = activeDietPlan?.dailyCalorieGoal else { return 0 }
        
        let calendar = Calendar.current
        let _ = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        var daysWithGoalMet = 0
        for i in 0..<7 {
            let day = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            let dayEntries = foodEntries.filter { calendar.isDate($0.timestamp, inSameDayAs: day) }
            let dayCalories = dayEntries.reduce(0) { $0 + $1.calories }
            
            if dayCalories >= Int(Double(goal) * 0.8) { // 80% of goal counts as achievement
                daysWithGoalMet += 1
            }
        }
        
        return Int((Double(daysWithGoalMet) / 7.0) * 100)
    }
    
    // MARK: - Methods
    
    private func startQuickDiet(type: DietType) {
        let dietPlan = DietPlan(
            type: type,
            name: "\(type.rawValue) Plan",
            dietDescription: type.description,
            dailyCalorieGoal: 2000,
            proteinGoal: 150,
            carbGoal: type == .keto ? 25 : 200,
            fatGoal: type == .keto ? 150 : 100
        )
        
        // Deactivate other diets
        for plan in dietPlans {
            plan.isActive = false
        }
        
        modelContext.insert(dietPlan)
        
        // Update streak
        if let streak = dietStreak {
            streak.updateStreak()
        } else {
            let newStreak = StreakData(type: .dieting)
            newStreak.updateStreak()
            modelContext.insert(newStreak)
        }
        
        try? modelContext.save()
    }
}

// MARK: - Supporting Views

struct CalorieProgressRing: View {
    let current: Int
    let goal: Int
    let protein: Int
    let proteinGoal: Int
    let carbs: Int
    let carbGoal: Int
    let fat: Int
    let fatGoal: Int
    
    private var progress: Double {
        min(1.0, Double(current) / Double(goal))
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 12)
                    .frame(width: 160, height: 160)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: current > goal ? [.red, .orange] : [.green, .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1), value: progress)
                
                // Center content
                VStack(spacing: 4) {
                    Text("\(current)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(current > goal ? .red : .primary)
                    
                    Text("/ \(goal) cal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(progress * 100))%")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(current > goal ? .red : .green)
                }
            }
            
            // Macro breakdown
            HStack(spacing: 20) {
                MacroIndicator(
                    title: "P",
                    current: protein,
                    goal: proteinGoal,
                    color: .blue
                )
                
                MacroIndicator(
                    title: "C",
                    current: carbs,
                    goal: carbGoal,
                    color: .orange
                )
                
                MacroIndicator(
                    title: "F",
                    current: fat,
                    goal: fatGoal,
                    color: .yellow
                )
            }
        }
    }
}

struct MacroIndicator: View {
    let title: String
    let current: Int
    let goal: Int
    let color: Color
    
    private var progress: Double {
        min(1.0, Double(current) / Double(goal))
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            ZStack {
                Circle()
                    .stroke(color.opacity(0.3), lineWidth: 4)
                    .frame(width: 40, height: 40)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                
                Text("\(current)")
                    .font(.caption2)
                    .fontWeight(.bold)
            }
            
            Text("\(goal)g")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct NutritionCard: View {
    let title: String
    let current: Int
    let goal: Int
    let unit: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Spacer()
            }
            
            HStack {
                Text("\(current)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(current > goal ? .red : color)
                
                Text("/ \(goal)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            ProgressView(value: Double(current), total: Double(goal))
                .progressViewStyle(LinearProgressViewStyle(tint: current > goal ? .red : color))
                .scaleEffect(x: 1, y: 1.5, anchor: .center)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct MealTypeCard: View {
    let mealType: MealType
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: mealType.systemImage)
                    .font(.title2)
                    .foregroundColor(.green)
                
                Text(mealType.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(width: 80, height: 70)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MealSummaryRow: View {
    let mealType: MealType
    let entries: [FoodEntry]
    
    private var totalCalories: Int {
        entries.reduce(0) { $0 + $1.calories }
    }
    
    var body: some View {
        HStack {
            Image(systemName: mealType.systemImage)
                .foregroundColor(.green)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(mealType.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(entries.count) item\(entries.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(totalCalories) cal")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.green)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct DietTypeQuickCard: View {
    let type: DietType
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type.systemImage)
                    .font(.title2)
                    .foregroundColor(.green)
                
                Text(type.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 100, height: 80)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InsightCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(value)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    DietMainView()
        .modelContainer(for: [DietPlan.self, FoodEntry.self, StreakData.self, UserProfile.self])
}
