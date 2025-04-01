import SwiftUI

struct EditExerciseView: View {
    var body: some View {
        Text("")
    }
    
    private func toggleMuscleGroup(_ muscle: String) {
    }
    
    private func saveExercise() {
    }
    
}





//import SwiftUI
//import FirebaseFirestore
//import FirebaseAuth
//
//struct EditExerciseView: View {
//    @Environment(\.presentationMode) var presentationMode
//    @State private var exerciseName: String
//    @State private var selectedMuscleGroups: [String] = []
//    @State private var barType: String
//    @State private var isLoading = false
//    @State private var errorMessage: String?
    
//    let exerciseID: String
//    let muscleGroups = ["Chest", "Back", "Quads", "Hamstrings", "Glutes", "Shoulders", "Triceps", "Biceps", "Core", "Other"]
//    let barTypeOptions = ["Barbell", "Dumbbell", "EZ-Bar", "Hex-Bar", "Machine", "Kettlebell", "Other"]
//    
//    init(exerciseID: String, existingExerciseName: String, existingMuscleGroups: [String], existingBarType: String) {
//        self.exerciseID = exerciseID
//        _exerciseName = State(initialValue: existingExerciseName)
//        _selectedMuscleGroups = State(initialValue: existingMuscleGroups)
//        _barType = State(initialValue: existingBarType)
//    }
//    
//    var body: some View {
//        Text("hi")
//        NavigationView {
//            ScrollView {
//                VStack(alignment: .leading, spacing: 20) {
//                    VStack(alignment: .leading) {
//                        Text("Select Bar Type:")
//                            .font(.headline)
//                        
//                        Picker("Bar Type", selection: $barType) {
//                            ForEach(barTypeOptions, id: \.self) { type in
//                                Text(type)
//                            }
//                        }
//                        .pickerStyle(MenuPickerStyle())
//                    }
//                    .padding(.horizontal)
//                    
//                    Text("Select Muscle Groups:")
//                        .font(.headline)
//                        .padding(.horizontal)
//                    
//                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
//                        ForEach(muscleGroups, id: \.self) { muscle in
//                            Button(action: {
//                                toggleMuscleGroup(muscle)
//                            }) {
//                                HStack {
//                                    Image(systemName: selectedMuscleGroups.contains(muscle) ? "checkmark.square.fill" : "square")
//                                        .foregroundColor(.pink)
//                                    Text(muscle)
//                                        .foregroundColor(.primary)
//                                }
//                                .padding()
//                                .frame(maxWidth: .infinity)
//                                .background(Color.gray.opacity(0.1))
//                                .cornerRadius(8)
//                            }
//                        }
//                    }
//                    .padding(.horizontal)
//                    
//                    if let error = errorMessage {
//                        Text(error)
//                            .foregroundColor(.red)
//                            .font(.caption)
//                            .padding()
//                    }
//
//                    Button(action: updateExercise) {
//                        Text(isLoading ? "Saving..." : "Update Exercise")
//                            .bold()
//                            .frame(maxWidth: .infinity)
//                            .padding()
//                            .background(exerciseName.isEmpty ? Color.gray.opacity(0.5) : Color.pink)
//                            .foregroundColor(.white)
//                            .cornerRadius(10)
//                    }
//                    .disabled(exerciseName.isEmpty || selectedMuscleGroups.isEmpty)
//                    .padding()
//
//                    Spacer()
//                }
//                .padding(.bottom, 50)
//            }
//            .navigationTitle("Edit \(exerciseName)")
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button("Cancel") {
//                        presentationMode.wrappedValue.dismiss()
//                    }
//                }
//            }
//        }
//    }
//    
//    // Toggle muscle group selection
//    private func toggleMuscleGroup(_ muscle: String) {
//        if selectedMuscleGroups.contains(muscle) {
//            selectedMuscleGroups.removeAll { $0 == muscle }
//        } else {
//            selectedMuscleGroups.append(muscle)
//        }
//    }
//
//    // Update exercise in Firestore
//    private func updateExercise() {
//        isLoading = true
//        errorMessage = nil
//        guard let userID = Auth.auth().currentUser?.uid else {
//            errorMessage = "User not authenticated."
//            isLoading = false
//            return
//        }
//        
//        let db = Firestore.firestore()
//        let exerciseRef = db.collection("users").document(userID).collection("exercises").document(exerciseID)
//        
//        let updatedExercise = [
//            "name": exerciseName.capitalized,
//            "muscleGroups": selectedMuscleGroups,
//            "barType": barType,
//            "updatedAt": Timestamp(date: Date())
//        ] as [String : Any]
//        
//        exerciseRef.updateData(updatedExercise) { error in
//            isLoading = false
//            if let error = error {
//                print("🔥 Firestore Error: \(error.localizedDescription)")
//                errorMessage = "Error: \(error.localizedDescription)"
//            } else {
//                print("✅ Exercise updated successfully!")
//                presentationMode.wrappedValue.dismiss()
//            }
//        }
//    }
//}
