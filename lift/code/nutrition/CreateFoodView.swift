//
//  CreateFoodView.swift
//  lift
//
//  Created by Josh Pelzer on 4/2/25.
//


import SwiftUI
import FirebaseFirestore
import FirebaseAuth


struct CreateFoodView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: UserViewModel
    
    @State private var errorMessage: String = ""
    @State private var name: String = ""
    @State private var calories: String = ""
    @State private var protein: String = ""
    @State private var fats: String = ""
    @State private var carbs: String = ""
    @State private var sugars: String = ""
    @State private var servingSize: String = ""
    
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
                Section(header: Text("Extra Details")) {
                    TextField("Serving Size", text: $servingSize)
                    Button("Add Image") {
                    }
                    
                }
                
                Button(action: saveFood) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Save Food")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(name.isEmpty)
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("Create Food")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func saveFood() {
        guard !name.isEmpty else {
            errorMessage = "Food name must not be empty."
            return
        }
        
        let newFood = FoodItem(
            servingSize: servingSize,
            name: name,
            calories: Double(calories) ?? 0,
            protein: Double(protein) ?? 0,
            fats: Double(fats) ?? 0,
            carbs: Double(carbs) ?? 0,
            sugars: Double(sugars) ?? 0,
            imageUrl: nil
        )
        
        viewModel.saveCustomFood(newFood) { result in
            switch result {
            case .success:
                presentationMode.wrappedValue.dismiss()
            case .failure(let error):
                errorMessage = "Error saving food: \(error.localizedDescription)"
            }
        }
    }
}
