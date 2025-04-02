//
//  ExerciseSelectionView.swift
//  lift
//
//  Created by Josh Pelzer on 4/1/25.
//

import SwiftUI

struct ExerciseSelectionView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var userViewModel = UserViewModel.shared
    @Binding var selectedExercise: Exercise
    @State private var showingAddExercise = false
    
    var body: some View {
        NavigationView {
            List {
                // Add new exercise button
                Button(action: {
                    showingAddExercise = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                        Text("Create New Exercise")
                            .foregroundColor(.primary)
                    }
                }
                .sheet(isPresented: $showingAddExercise, onDismiss: {
                    // This will trigger when the sheet dismisses
                    userViewModel.fetchExercises() // Refresh exercises
                }) {
                    AddExerciseView()
                }
                
                // Existing exercises section
                ForEach(userViewModel.userExercises) { exercise in
                    Button(action: {
                        selectedExercise.name = exercise.name
                        // Copy other properties if needed
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Text(exercise.name)
                            Spacer()
                            if exercise.name == selectedExercise.name {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Exercise")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .onAppear {
                userViewModel.fetchExercises() // Load exercises when view appears
            }
        }
    }
}
