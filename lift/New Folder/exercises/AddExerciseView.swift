import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AddExerciseView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var exerciseName = ""
    @State private var selectedMuscleGroups: [String] = []
    @State private var barType: String
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    let muscleGroups = ["Chest", "Back", "Quads", "Hamstrings", "Glutes", "Shoulders", "Triceps", "Biceps", "Core", "Other"]
    let barTypeOptions = ["Barbell", "Dumbbell", "EZ-Bar", "Hex-Bar", "Machine", "Kettlebell", "BodyWeight", "Other"]
    
    init(existingExerciseName: String? = nil, existingMuscleGroups: [String]? = nil, existingBarType: String? = nil) {
        _exerciseName = State(initialValue: existingExerciseName ?? "")
        _selectedMuscleGroups = State(initialValue: existingMuscleGroups ?? [])
        _barType = State(initialValue: existingBarType ?? "Barbell")
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    TextField("Exercise Name", text: $exerciseName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .padding(.top, 10) // Extra padding to avoid keyboard overlap
                    
                    VStack(alignment: .leading) {
                        Text("Select Bar Type:")
                            .font(.headline)
                        
                        Picker("Bar Type", selection: $barType) {
                            ForEach(barTypeOptions, id: \.self) { type in
                                Text(type)
                            }
                        }
                        .pickerStyle(MenuPickerStyle()) // ⬅️ This creates a dropdown menu
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
                        Text(isLoading ? "Saving..." : "Add Exercise")
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
                .padding(.bottom, 50) // 🔥 Extra padding at the bottom to prevent cutoff
            }
            .navigationTitle("Create New Exercise")
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
        
        // Create document ID from exercise name
        let documentID = exerciseName.lowercased().replacingOccurrences(of: " ", with: "_")
        
        // Check if exercise already exists
        exercisesRef.document(documentID).getDocument { (document, error) in
            if let error = error {
                print("🔥 Firestore Error: \(error.localizedDescription)")
                errorMessage = "Error: \(error.localizedDescription)"
                isLoading = false
                return
            }
            
            if let document = document, document.exists {
                // Exercise already exists
                errorMessage = "This exercise already exists."
                isLoading = false
            } else {
                // Exercise does not exist, proceed with adding it
                let newExercise = [
                    "name": exerciseName.capitalized,
                    "muscleGroups": selectedMuscleGroups,
                    "barType": barType,
                    "createdBy": userID,
                    "createdAt": Timestamp(date: Date()),
                    "setCount": 0
                ] as [String : Any]

                exercisesRef.document(documentID).setData(newExercise) { error in
                    isLoading = false
                    if let error = error {
                        print("🔥 Firestore Error: \(error.localizedDescription)")
                        errorMessage = "Error: \(error.localizedDescription)"
                    } else {
                        print("✅ Exercise added successfully with ID: \(documentID)")
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
