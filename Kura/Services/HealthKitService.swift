//
//  HealthKitService.swift
//  Kura
//
//  Apple Health integration for workout and activity data
//

import Foundation
import HealthKit

class HealthKitService: ObservableObject {
    private let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var workouts: [WorkoutData] = []
    @Published var todayCaloriesBurned: Double = 0
    @Published var todayActiveEnergy: Double = 0
    @Published var todaySteps: Int = 0
    
    // Check if HealthKit is available
    static var isHealthDataAvailable: Bool {
        return HKHealthStore.isHealthDataAvailable()
    }
    
    // Request HealthKit permissions
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, NSError(domain: "HealthKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device"]))
            return
        }
        
        // Define the data types we want to read
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isAuthorized = success
                completion(success, error)
            }
        }
    }
    
    // Fetch today's workouts
    func fetchTodayWorkouts(completion: @escaping ([WorkoutData]) -> Void) {
        guard isAuthorized else {
            print("❌ HealthKit not authorized")
            completion([])
            return
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: .workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { [weak self] query, samples, error in
            
            guard let workouts = samples as? [HKWorkout], error == nil else {
                print("❌ Error fetching workouts: \(error?.localizedDescription ?? "Unknown")")
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }
            
            let workoutData = workouts.map { workout in
                WorkoutData(
                    id: workout.uuid.uuidString,
                    activityType: workout.workoutActivityType,
                    startDate: workout.startDate,
                    endDate: workout.endDate,
                    duration: workout.duration,
                    caloriesBurned: workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0,
                    distance: workout.totalDistance?.doubleValue(for: .mile()) ?? 0
                )
            }
            
            DispatchQueue.main.async {
                self?.workouts = workoutData
                self?.todayCaloriesBurned = workoutData.reduce(0) { $0 + $1.caloriesBurned }
                completion(workoutData)
            }
        }
        
        healthStore.execute(query)
    }
    
    // Fetch workouts for a date range
    func fetchWorkouts(from startDate: Date, to endDate: Date, completion: @escaping ([WorkoutData]) -> Void) {
        guard isAuthorized else {
            completion([])
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: .workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { query, samples, error in
            
            guard let workouts = samples as? [HKWorkout], error == nil else {
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }
            
            let workoutData = workouts.map { workout in
                WorkoutData(
                    id: workout.uuid.uuidString,
                    activityType: workout.workoutActivityType,
                    startDate: workout.startDate,
                    endDate: workout.endDate,
                    duration: workout.duration,
                    caloriesBurned: workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0,
                    distance: workout.totalDistance?.doubleValue(for: .mile()) ?? 0
                )
            }
            
            DispatchQueue.main.async {
                completion(workoutData)
            }
        }
        
        healthStore.execute(query)
    }
    
    // Fetch today's active energy burned
    func fetchTodayActiveEnergy(completion: @escaping (Double) -> Void) {
        guard isAuthorized else {
            completion(0)
            return
        }
        
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            completion(0)
            return
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: energyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] query, statistics, error in
            
            guard let statistics = statistics, let sum = statistics.sumQuantity() else {
                DispatchQueue.main.async {
                    completion(0)
                }
                return
            }
            
            let energy = sum.doubleValue(for: .kilocalorie())
            
            DispatchQueue.main.async {
                self?.todayActiveEnergy = energy
                completion(energy)
            }
        }
        
        healthStore.execute(query)
    }
    
    // Fetch today's steps
    func fetchTodaySteps(completion: @escaping (Int) -> Void) {
        guard isAuthorized else {
            completion(0)
            return
        }
        
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion(0)
            return
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] query, statistics, error in
            
            guard let statistics = statistics, let sum = statistics.sumQuantity() else {
                DispatchQueue.main.async {
                    completion(0)
                }
                return
            }
            
            let steps = Int(sum.doubleValue(for: .count()))
            
            DispatchQueue.main.async {
                self?.todaySteps = steps
                completion(steps)
            }
        }
        
        healthStore.execute(query)
    }
    
    // Refresh all today's data
    func refreshTodayData() {
        fetchTodayWorkouts { _ in }
        fetchTodayActiveEnergy { _ in }
        fetchTodaySteps { _ in }
    }
}

// Workout Data Model
struct WorkoutData: Identifiable {
    let id: String
    let activityType: HKWorkoutActivityType
    let startDate: Date
    let endDate: Date
    let duration: TimeInterval
    let caloriesBurned: Double
    let distance: Double
    
    var activityName: String {
        switch activityType {
        case .running: return "Running"
        case .walking: return "Walking"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .yoga: return "Yoga"
        case .functionalStrengthTraining: return "Strength Training"
        case .traditionalStrengthTraining: return "Weight Lifting"
        case .elliptical: return "Elliptical"
        case .rowing: return "Rowing"
        case .stairs: return "Stairs"
        case .hiking: return "Hiking"
        case .dance: return "Dance"
        case .coreTraining: return "Core Training"
        case .flexibility: return "Flexibility"
        case .highIntensityIntervalTraining: return "HIIT"
        case .boxing: return "Boxing"
        case .pilates: return "Pilates"
        case .soccer: return "Soccer"
        case .basketball: return "Basketball"
        case .tennis: return "Tennis"
        case .golf: return "Golf"
        case .volleyball: return "Volleyball"
        case .baseball: return "Baseball"
        default: return "Workout"
        }
    }
    
    var activityIcon: String {
        switch activityType {
        case .running: return "figure.run"
        case .walking: return "figure.walk"
        case .cycling: return "bicycle"
        case .swimming: return "figure.pool.swim"
        case .yoga: return "figure.mind.and.body"
        case .functionalStrengthTraining, .traditionalStrengthTraining: return "dumbbell.fill"
        case .elliptical: return "figure.elliptical"
        case .rowing: return "figure.rower"
        case .stairs: return "figure.stairs"
        case .hiking: return "figure.hiking"
        case .dance: return "figure.dance"
        case .coreTraining: return "figure.core.training"
        case .flexibility: return "figure.flexibility"
        case .highIntensityIntervalTraining: return "flame.fill"
        case .boxing: return "figure.boxing"
        case .pilates: return "figure.pilates"
        case .soccer: return "figure.soccer"
        case .basketball: return "figure.basketball"
        case .tennis: return "figure.tennis"
        case .golf: return "figure.golf"
        case .volleyball: return "figure.volleyball"
        case .baseball: return "figure.baseball"
        default: return "figure.walk"
        }
    }
    
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var formattedDistance: String {
        if distance > 0 {
            return String(format: "%.2f mi", distance)
        }
        return ""
    }
}
