
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct EditExerciseView: View {
    @Environment(\.presentationMode) var presentationMode

    @State private var exerciseName: String = "Bench Press"
    @State private var selectedMuscleGroups: [String] = []
    @State private var barType: String = "Barbell"

    let muscleGroups = ["Chest", "Back", "Quads", "Hamstrings", "Glutes", "Shoulders", "Triceps", "Biceps", "Core", "Other"]
    let barTypeOptions = ["Other", "Barbell", "Dumbbells", "EZ-Bar", "Trap-Bar", "Kettlebell", "Machine", "BodyWeight"]

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
//                                toggleMuscleGroup(muscle)
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

                    Button(action: updateExercise) {
                        Text("Save Changes")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(exerciseName.isEmpty ? Color.gray.opacity(0.5) : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(exerciseName.isEmpty)
                    .padding(.horizontal)

                    Text("Delete Exercise")
                        .bold()
                        .frame(maxWidth: .infinity)
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
//        if selectedMuscleGroups.contains(muscle) {
//            selectedMuscleGroups.removeAll { $0 == muscle }
//        } else {
//            selectedMuscleGroups.append(muscle)
//        }
    }

    private func updateExercise() {
//        isLoading = true
//        errorMessage = nil
//
//        guard let userID = Auth.auth().currentUser?.uid else {
//            errorMessage = "User not authenticated."
//            isLoading = false
//            return
//        }
//
//        let db = Firestore.firestore()
//        let exerciseRef = db.collection("users").document(userID).collection("exercises").document(originalDocumentID)
//
//        let updatedFields: [String: Any] = [
//            "name": exerciseName.capitalized,
//            "muscleGroups": selectedMuscleGroups,
//            "barType": barType,
//            "updatedAt": Timestamp(date: Date())
//        ]
//
//        exerciseRef.updateData(updatedFields) { error in
//            isLoading = false
//            if let error = error {
//                errorMessage = "Error: \(error.localizedDescription)"
//                print("🔥 Update error: \(error)")
//            } else {
//                print("✅ Exercise updated")
//                presentationMode.wrappedValue.dismiss()
//            }
//        }
    }
}
