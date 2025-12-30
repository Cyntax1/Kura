//
//  WaterLogView.swift
//  Kura
//
//  Quick water logging interface
//

import SwiftUI

struct WaterLogView: View {
    @Environment(\.dismiss) private var dismiss
    let onLog: (Double) -> Void
    
    @State private var selectedAmount: Double = 250.0
    
    private let waterAmounts: [(name: String, amount: Double, icon: String)] = [
        ("Cup", 250.0, "cup.and.saucer.fill"),
        ("Glass", 350.0, "wineglass.fill"),
        ("Bottle", 500.0, "waterbottle.fill"),
        ("Large", 1000.0, "waterbottle.fill")
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.cyan)
                    
                    Text("Log Water Intake")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Stay hydrated! Tap to log")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Quick amount selection
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(waterAmounts, id: \.amount) { item in
                        WaterAmountCard(
                            name: item.name,
                            amount: item.amount,
                            icon: item.icon,
                            isSelected: selectedAmount == item.amount,
                            action: {
                                selectedAmount = item.amount
                            }
                        )
                    }
                }
                .padding(.horizontal)
                
                // Custom amount slider
                VStack(spacing: 12) {
                    Text("Custom Amount")
                        .font(.headline)
                    
                    HStack {
                        Text("\(Int(selectedAmount))ml")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.cyan)
                            .frame(width: 100)
                        
                        Slider(value: $selectedAmount, in: 100...2000, step: 50)
                            .tint(.cyan)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
                
                // Log button
                Button(action: {
                    onLog(selectedAmount)
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "drop.fill")
                        Text("Log \(Int(selectedAmount))ml")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.cyan, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: .cyan.opacity(0.3), radius: 8, y: 4)
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .navigationTitle("Water")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct WaterAmountCard: View {
    let name: String
    let amount: Double
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(isSelected ? .cyan : .secondary)
                
                Text(name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("\(Int(amount))ml")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.cyan.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.cyan : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    WaterLogView(onLog: { amount in
        print("Logged \(amount)ml")
    })
}
