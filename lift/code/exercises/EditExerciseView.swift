import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct EditExerciseView: View {
    @Environment(\.presentationMode) var presentationMode

    let exerciseName: String

    @State private var selectedMuscleGroups: [String] = []
    @State private var barType: String = "Other"
    @State private var documentID: String = ""
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingAlert: Bool = false

    let muscleGroups = ["Chest", "Back", "Quads", "Hamstrings", "Glutes", "Shoulders", "Triceps", "Biceps", "Core", "Other"]
    let barTypeOptions = ["Other", "Barbell", "Dumbbells", "Cable", "EZ-Bar", "Trap-Bar", "Kettlebell", "Machine", "BodyWeight"]

    var body: some View {
        NavigationView {
            if isLoading {
                ProgressView("Loading exercise data...")
                    .onAppear(perform: loadExerciseData)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        TextField("Exercise Name", text: .constant(exerciseName)) // uneditable
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

                        Button(action: updateExercise) {
                            Text("Save Changes")
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
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
                .alert(isPresented: $showingAlert) {
                    Alert(title: Text("Error"), message: Text("message"), dismissButton: .default(Text("OK")))
                }
//                .alert(item: $errorMessage) { msg in
//                    Alert(title: Text("Error"), message: Text(msg), dismissButton: .default(Text("OK")))
//                }
            }
        }
    }

    private func toggleMuscleGroup(_ muscle: String) {
        if selectedMuscleGroups.contains(muscle) {
            selectedMuscleGroups.removeAll { $0 == muscle }
        } else {
            selectedMuscleGroups.append(muscle)
            print(selectedMuscleGroups)
        }
    }

    private func loadExerciseData() {
        guard let userID = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated."
            isLoading = false
            return
        }

        let db = Firestore.firestore()
        db.collection("users").document(userID).collection("exercises")
            .whereField("name", isEqualTo: exerciseName)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error = error {
                    errorMessage = "Error loading exercise: \(error.localizedDescription)"
                    isLoading = false
                    return
                }

                guard let document = snapshot?.documents.first else {
                    errorMessage = "Exercise not found."
                    isLoading = false
                    return
                }

                let data = document.data()
                self.documentID = document.documentID
                self.barType = data["barType"] as? String ?? "Other"
                self.selectedMuscleGroups = data["muscleGroups"] as? [String] ?? []
                self.isLoading = false
            }
    }

    private func updateExercise() {
        guard let userID = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated."
            return
        }

        let db = Firestore.firestore()
        let exerciseRef = db.collection("users").document(userID).collection("exercises").document(documentID)

        let updatedFields: [String: Any] = [
            "barType": barType,
            "muscleGroups": selectedMuscleGroups,
            "updatedAt": Timestamp(date: Date()),
            "test": "test"
        ]

        exerciseRef.updateData(updatedFields) { error in
            if let error = error {
                errorMessage = "Error updating: \(error.localizedDescription)"
            } else {
                print("✅ Exercise updated.")
                print("\(updatedFields)")
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
