//
//  FinishWorkoutView.swift
//  lift
//
//  Created by Josh Pelzer on 4/11/25.
//

import SwiftUI

struct FinishWorkoutView: View {
    var completedExercises: [Exercise]
    @Binding var isPresented: Bool
    var onSaveWorkout: () -> Void
    var onSaveTemplate: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            if completedExercises.isEmpty {
                Text("You did not complete any exercises")
            } else {
                Text("Workout Complete 🎉")
                    .font(.title2).bold()
                
                Text("You completed \(completedExercises.count) exercises:")
                    .font(.subheadline)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        Spacer()
                        ForEach(completedExercises, id: \.name) { exercise in
                            Text("• \(exercise.name)")
                                .font(.body)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                .frame(maxHeight: 200)
                
                Text("What would you like to do?")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)
                
                VStack(spacing: 12) {
                    Button(action: {
                        onSaveWorkout()
                        isPresented = false
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle")
                            Text("Save Template and Update Values")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button(action: {
                        onSaveTemplate()
                        onSaveWorkout()
                        isPresented = false
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Update Values Only")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            Button(action: {
                isPresented = false
            }) {
                Text("Cancel")
                    .frame(maxWidth: .infinity)
            }
            .foregroundColor(.red)
            .padding(.top, 8)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .padding()
        .shadow(radius: 10)
    }
}
