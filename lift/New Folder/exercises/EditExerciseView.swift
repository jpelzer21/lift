import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct EditExerciseView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var exerciseName: String
    @State private var selectedMuscleGroups: [String]
    @State private var barType: String
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    let muscleGroups = ["Chest", "Back", "Quads", "Hamstrings", "Glutes", "Shoulders", "Triceps", "Biceps", "Core", "Other"]
    let barTypeOptions = ["Barbell", "Dumbbell", "EZ-Bar", "Hex-Bar", "Machine", "Kettlebell", "Other"]
    
    init(exerciseName: String, muscleGroups: [String], barType: String) {
        _exerciseName = State(initialValue: exerciseName)
        _selectedMuscleGroups = State(initialValue: muscleGroups)
        _barType = State(initialValue: barType)
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
                    
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding()
                    }

                    Button(action: saveExercise) {
                        Text(isLoading ? "Saving..." : "Save Changes")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(exerciseName.isEmpty ? Color.gray.opacity(0.5) : Color.pink)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(exerciseName.isEmpty || selectedMuscleGroups.isEmpty)
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
    
    // Toggle muscle group selection
    private func toggleMuscleGroup(_ muscle: String) {
        if selectedMuscleGroups.contains(muscle) {
            selectedMuscleGroups.removeAll { $0 == muscle }
        } else {
            selectedMuscleGroups.append(muscle)
        }
    }

    // Save exercise to Firestore
    private func saveExercise() {
        isLoading = true
        errorMessage = nil
        guard let userID = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated."
            isLoading = false
            return
        }
        
        let db = Firestore.firestore()
        let exercisesRef = db.collection("users").document(userID).collection("exercises")
        
        // Check if exercise already exists
        exercisesRef.whereField("name", isEqualTo: exerciseName.capitalized).getDocuments { (snapshot, error) in
            if let error = error {
                print("🔥 Firestore Error: \(error.localizedDescription)")
                errorMessage = "Error: \(error.localizedDescription)"
                isLoading = false
                return
            }
            
            if let snapshot = snapshot, !snapshot.documents.isEmpty {
                // Exercise already exists, update it
                if let document = snapshot.documents.first {
                    let exerciseRef = exercisesRef.document(document.documentID)
                    exerciseRef.updateData([
                        "name": exerciseName.capitalized,
                        "muscleGroups": selectedMuscleGroups,
                        "barType": barType
                    ]) { error in
                        isLoading = false
                        if let error = error {
                            print("🔥 Firestore Error: \(error.localizedDescription)")
                            errorMessage = "Error: \(error.localizedDescription)"
                        } else {
                            print("✅ Exercise updated successfully!")
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            } else {
                // Exercise does not exist, create it
                let newExercise = [
                    "name": exerciseName.capitalized,
                    "muscleGroups": selectedMuscleGroups,
                    "barType": barType,
                    "createdBy": userID,
                    "createdAt": Timestamp(date: Date()),
                    "setCount": 0
                ] as [String : Any]

                exercisesRef.addDocument(data: newExercise) { error in
                    isLoading = false
                    if let error = error {
                        print("🔥 Firestore Error: \(error.localizedDescription)")
                        errorMessage = "Error: \(error.localizedDescription)"
                    } else {
                        print("✅ Exercise added successfully!")
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}