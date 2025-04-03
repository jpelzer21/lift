//
//  CreateFoodView.swift
//  lift
//
//  Created by Josh Pelzer on 4/2/25.
//


import SwiftUI

struct CreateFoodView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name: String = ""
    @State private var calories: String = ""
    @State private var protein: String = ""
    @State private var fats: String = ""
    @State private var carbs: String = ""
    @State private var sugars: String = ""
    
//    var onFoodAdded: (FoodItem) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Food Details")) {
                    TextField("Food Name", text: $name)
                    TextField("Calories", text: $calories)
                        .keyboardType(.decimalPad)
                    TextField("Protein (g)", text: $protein)
                        .keyboardType(.decimalPad)
                    TextField("Fats (g)", text: $fats)
                        .keyboardType(.decimalPad)
                    TextField("Carbs (g)", text: $carbs)
                        .keyboardType(.decimalPad)
                    TextField("Sugars (g)", text: $sugars)
                        .keyboardType(.decimalPad)
                }
                
                Button(action: saveFood) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Save Food")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .navigationTitle("Create Food")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func saveFood() {
        guard !name.isEmpty else { return }
        
        let newFood = FoodItem(
            servingSize: "Custom",
            name: name,
            calories: Double(calories) ?? 0,
            protein: Double(protein) ?? 0,
            fats: Double(fats) ?? 0,
            carbs: Double(carbs) ?? 0,
            sugars: Double(sugars) ?? 0,
            imageUrl: nil
        )
        
//        onFoodAdded(newFood)
        presentationMode.wrappedValue.dismiss()
    }
}
