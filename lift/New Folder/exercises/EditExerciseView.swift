
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct EditExerciseView: View {
    @State private var exerciseName: String
    @State private var barType: String = "barbell"
    @State private var selectedMuscleGroups: [String] = []
    
    let muscleGroups = ["Chest", "Back", "Quads", "Hamstrings", "Glutes", "Shoulders", "Triceps", "Biceps", "Core", "Other"]
    let barTypeOptions = ["Barbell", "Dumbbell", "EZ-Bar", "Hex-Bar", "Machine", "Kettlebell", "BodyWeight", "Other"]
    
    @Environment(\.presentationMode) var presentationMode
    
    init(exerciseName: String, barType: String, selectedMuscleGroups: [String]) {
        _exerciseName = State(initialValue: exerciseName)
//        _barType = State(initialValue: barType)
//        _selectedMuscleGroups = State(initialValue: selectedMuscleGroups)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    TextField("Exercise Name", text: $exerciseName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    VStack(alignment: .leading) {
                        Text("Select Bar Type:")
                            .font(.headline)
                        
                        Picker("Bar Type", selection: $barType) {
                            ForEach(barTypeOptions, id: \.self) { type in
                                Text(type)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    .padding(.horizontal)
                    
                    Text("Select Muscle Groups:")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(muscleGroups, id: \.self) { muscle in
                            Button(action: {
                                toggleMuscleGroup(muscle)
                            }) {
                                HStack {
                                    Image(systemName: selectedMuscleGroups.contains(muscle) ? "checkmark.square.fill" : "square")
                                        .foregroundColor(.pink)
                                    Text(muscle)
                                        .foregroundColor(.primary)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Button(action: saveExercise) {
                        Text("Save Changes")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(exerciseName.isEmpty ? Color.gray.opacity(0.5) : Color.pink)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(exerciseName.isEmpty)
                    .padding()
                    
                    Spacer()
                }
                .padding(.bottom, 50)
            }
            .navigationTitle("Edit Exercise")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func toggleMuscleGroup(_ muscle: String) {
        if selectedMuscleGroups.contains(muscle) {
            selectedMuscleGroups.removeAll { $0 == muscle }
        } else {
            selectedMuscleGroups.append(muscle)
        }
    }
    
    private func saveExercise() {
        // Functionality to save the edited exercise will be implemented later
    }
}
