import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct WorkoutView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @Binding var workoutTitle: String
    @Binding var exercises: [Exercise]
    
    @State private var showingAlert = false
    @State private var showingErrorAlert: Bool = false
    @State private var isEditingTitle: Bool = false

    private let db = Firestore.firestore()
    

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .center) {
                    if isEditingTitle {
                        TextField("Enter Title:", text: $workoutTitle, onCommit: {
                            if !workoutTitle.trimmingCharacters(in: .whitespaces).isEmpty {
                                isEditingTitle = false
                            }
                        })
                        .font(.largeTitle)
                        .fontWeight(.medium)
                        .customTextFieldStyle()
                    } else {
                        Text(workoutTitle)
                            .font(.largeTitle)
                            .fontWeight(.medium)
                            .onTapGesture {
                                isEditingTitle = true
                            }
                    }
                    
                    VStack {
                        ForEach($exercises, id: \.id) { $exercise in
                            ExerciseView(exercise: $exercise, deleteAction: {
                                if let index = exercises.firstIndex(where: { $0.id == exercise.id }) {
                                    exercises.remove(at: index)
                                }
                            })
                        }
                        .listRowBackground(Color(UIColor.systemBackground))
                        .listRowSeparator(.hidden)
                        HStack {
                            Spacer()
                            Button("Add Exercise") {
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                exercises.append(Exercise(name: "New Exercise", sets: [
                                    ExerciseSet(number: 1, weight: 0, reps: 0)
                                ]))
                            }
                            .buttonStyle(.borderedProminent)
                            .buttonBorderShape(.roundedRectangle)
                            .tint(.blue)
                            .saturation(0.9)
                            .padding()
                            Button("Save Template") {
                                saveWorkoutAsTemplate()
                            }
                            Spacer()
                        }
                        .listRowBackground(Color(UIColor.systemBackground))
                        .listRowSeparator(.hidden)
                    }
                    .edgesIgnoringSafeArea(.all)
                    .listStyle(GroupedListStyle())
                    
                }
                .onAppear {
                    if workoutTitle == "New Template" || workoutTitle == "New Workout" {
                        isEditingTitle = true
                    }
                    loadWorkoutTemplate()
                }
                .ignoresSafeArea(.all)
            }
            
            .onTapGesture { // Dismiss the keyboard when tapping anywhere on the screen
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .toolbarBackgroundVisibility(.hidden)
            .navigationBarItems(trailing: Button("Finish Workout") {
                showingAlert = true
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("You have completed \(completedSets()) exercises"),
                    primaryButton: .default(Text("Finish")) {
                        print("Workout Finished")
                        saveWorkoutAsTemplate()
                        saveWorkout()
                        saveExercises()
                        presentationMode.wrappedValue.dismiss()
                    },
                    secondaryButton: .cancel(Text("Stay"))
                )
            }
            .buttonStyle(.borderedProminent).tint(.green).saturation(0.85))
            .toolbar{
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                        print("workout cancelled")
                    }) {
                        Label("Back", systemImage: "arrow.left")
                            .foregroundStyle(.red)
                    }
                }
            }
        }.padding()
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
    
    private func completedSets() -> Int {
        var result = 0
        for exercise in exercises {
            var allSetsComplete = true
            for set in exercise.sets {
                if !set.isCompleted {
                    allSetsComplete = false
                }
            }
            if allSetsComplete {
                result += 1
            } else if exercise.allSetsCompleted {
                result += 1
            }
        }
        return result
    }
    
    
    private func saveExercises() {
        print("SAVE EXERCISES() CALLED")
        
        
        
        guard let userID = Auth.auth().currentUser?.uid else {
            print("User not authenticated")
            return
        }
        
        for exercise in exercises {
            // Define the document reference for the exercise
            let exerciseRef = db.collection("users")
                                .document(userID)
                                .collection("exercises")
                                .document(exercise.name.lowercased().replacingOccurrences(of: " ", with: "_"))
                        
                        // Check if the exercise document exists
            exerciseRef.getDocument { (document, error) in
                if let error = error {
                    print("Error checking exercise document: \(error.localizedDescription)")
                    return
                }
                
                if let document = document, document.exists {
                    // If document exists, we don't need to add the name field
                    print("\(exercise.name) already exists in the database.")
                }
                let exerciseData: [String: Any] = [
                    "name": exercise.name.capitalized,
                    "lastSetDate": Timestamp(date: Date()),
                    "setCount": FieldValue.increment(Int64(exercise.sets.filter { $0.isCompleted }.count)) // only increase if set is completed
                ]
                            
                
                exerciseRef.setData(exerciseData, merge: true) { error in
                    if let error = error {
                        print("Error adding name for \(exercise.name): \(error.localizedDescription)")
                    } else {
                        print("Name added for \(exercise.name)!")
                    }
                }
                
            }
            
            // Add the sets data as before
            for set in exercise.sets {
                if set.isCompleted {
                    let newSetRef = exerciseRef.collection("sets").document() // Generates a random ID
                    
                    let setData: [String: Any] = [
                        "date": Timestamp(date: Date()),
                        "setNum": set.number,
                        "weight": set.weight,
                        "reps": set.reps
                    ]
                    
                    newSetRef.setData(setData) { error in
                        if let error = error {
                            print("Error writing \(exercise.name) set: \(error.localizedDescription)")
                        } else {
                            print("Set added for \(exercise.name): \(setData)")
                        }
                    }
                }
            }
        }
    }
    
    private func saveWorkout() {
        print("SAVE WORKOUTS() CALLED")
        guard let user = Auth.auth().currentUser else {
            print("User not authenticated")
            return
        }

        let workoutRef = db.collection("users").document(user.uid).collection("workouts").document() // Generates a random ID

        print("Saving workout with title: \(workoutTitle)")

        var exerciseDetails: [[String: Any]] = []

        for exercise in exercises {
            guard !exercise.sets.isEmpty else { continue }

            // Find the set with the largest rep count
            if let maxRepSet = exercise.sets.max(by: { $0.reps < $1.reps }) {
                let exerciseData: [String: Any] = [
                    "name": exercise.name,
                    "sets": exercise.sets.count,  // Total number of sets
                    "reps": maxRepSet.reps        // Maximum reps in a single set
                ]
                exerciseDetails.append(exerciseData)
            }
        }

        // If no exercises have sets, don't save the workout
        guard !exerciseDetails.isEmpty else {
            print("Workout not saved because no exercises contain sets.")
            return
        }

        let workoutData: [String: Any] = [
            "title": workoutTitle,
            "timestamp": Timestamp(date: Date()),
            "exercises": exerciseDetails
        ]

        workoutRef.setData(workoutData) { error in
            if let error = error {
                print("Error saving workout: \(error.localizedDescription)")
            } else {
                print("Workout saved successfully with ID: \(workoutRef.documentID)")
            }
        }
    }
    
    private func saveWorkoutAsTemplate() {
        print("SAVE WORKOUT AS TEMPLATE() CALLED")
        guard let userID = Auth.auth().currentUser?.uid else {
            print("Error: User not logged in")
            return
        }
        let workoutRef = db.collection("users").document(userID)
            .collection("templates").document() // Generates a random ID
        var exercisesData: [[String: Any]] = []
        
        for exercise in exercises {
            var setsData: [[String: Any]] = []
            for set in exercise.sets {
                setsData.append([
                    "setNum": set.number,
                    "weight": set.weight,
                    "reps": set.reps
                ])
            }
            let exerciseData: [String: Any] = [
                "name": exercise.name,
                "lastSetCompleted": Timestamp(date: Date()),
                "sets": setsData
            ]
            exercisesData.append(exerciseData)
        }
        
        workoutRef.setData([
            "title": workoutTitle,
            "exercises": exercisesData,
            "lastEdited": Timestamp(date: Date())
        ], merge: true) { error in
            if let error = error {
                print("Error saving template: \(error.localizedDescription)")
            } else {
                print("Workout template saved successfully!")
            }
        }
    }
    
    private func loadWorkoutTemplate() {
        print("LOAD WORKOUT TEMPLATE() CALLED")
        guard let userID = Auth.auth().currentUser?.uid else {
            print("Error: User not logged in")
            return
        }
        let workoutRef = db.collection("users").document(userID)
            .collection("templates").document(workoutTitle.replacingOccurrences(of: "_", with: " ").capitalized(with: .autoupdatingCurrent))
        
        workoutRef.getDocument { (document, error) in
            if let error = error {
                print("Error loading template: \(error.localizedDescription)")
                return
            }

            if let document = document, document.exists, let data = document.data(),
               let exercisesData = data["exercises"] as? [[String: Any]] {
                
                exercises = exercisesData.compactMap { exerciseDict in
                    guard let name = exerciseDict["name"] as? String,
                          let setsData = exerciseDict["sets"] as? [[String: Any]] else { return nil }
                    
                    let sets = setsData.compactMap { setDict -> ExerciseSet? in
                        guard let setNum = setDict["setNum"] as? Int,
                              let weight = setDict["weight"] as? Double,
                              let reps = setDict["reps"] as? Int else { return nil }
                        return ExerciseSet(number: setNum, weight: weight, reps: reps)
                    }

                    return Exercise(name: name, sets: sets)
                }
            }
        }
    }
}




struct ExerciseView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var exercise: Exercise
    @State private var showingDeleteAlert = false
    var deleteAction: () -> Void

    let generator = UIImpactFeedbackGenerator(style: .medium)
    
    private let doubleFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        return numberFormatter
    }()

    var body: some View {
        VStack(spacing: 10) {
            // Exercise Title and Delete Button
            HStack {
                TextField("Exercise Name", text: $exercise.name)
                    .font(.headline)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6)))
                    .multilineTextAlignment(.leading)

                Button {
                    showingDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .padding()
                        .background(Circle().fill(Color(UIColor.systemGray6)))
                }
                .alert(isPresented: $showingDeleteAlert) {
                    Alert(
                        title: Text("Delete \(exercise.name)?"),
                        message: Text("Remove \(exercise.name) from this template?"),
                        primaryButton: .destructive(Text("Delete")) {
                            withAnimation {
                                deleteAction()
                            }
                        },
                        secondaryButton: .cancel()
                    )
                }
            }

            Divider()

            
            // Set Headers
            HStack {
                Text("Set")
                    .frame(width: 50)
                Spacer()
                Text("Weight")
                    .frame(width: 80)
                Spacer()
                Text("Reps")
                    .frame(width: 60)
                Spacer()
                Text("✔️")
                    .frame(width: 30)
            }
            .font(.subheadline)
            .foregroundColor(.gray)
                
            VStack (spacing: 0) {
                // Set List
                ForEach($exercise.sets) { $set in
                    HStack {
                        Text("\(set.number)")
                            .frame(width: 50)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        TextField("0", value: $set.weight, formatter: doubleFormatter)
                            .customTextFieldStyle()
                            .frame(width: 80)
                            .keyboardType(.decimalPad)
                        
                        Spacer()
                        
                        TextField("0", value: $set.reps, formatter: NumberFormatter())
                            .customTextFieldStyle()
                            .frame(width: 60)
                            .keyboardType(.numberPad)
                        
                        Spacer()
                        
                        Button {
                            generator.impactOccurred()
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            set.isCompleted.toggle()
                        } label: {
                            Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(set.isCompleted ? .green : .gray)
                                .font(.title3)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .frame(width: 30)
                    }
                    .padding(.vertical, 5)
                    .background(/*set.isCompleted ? Color("androidGreen") : */Color.clear)
                    .saturation(0.8)
                    .cornerRadius(10)
                    .animation(.easeInOut, value: set.isCompleted)
                }
//                .padding(.vertical, 10)
            }

            HStack { // add and remove sets
                Button(action: {
                    let newSet = ExerciseSet(
                        number: exercise.sets.count + 1,
                        weight: exercise.sets[exercise.sets.count-1].weight,
                        reps: exercise.sets[exercise.sets.count-1].reps
                    )
                    withAnimation {
                        exercise.sets.append(newSet)
                    }
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Set")
                    }
                    .foregroundColor(.blue)
                    .font(.body)
                    .padding(.vertical, 5)
                }
                Spacer()
                Button(action: {
                    if !exercise.sets.isEmpty {
                        withAnimation {
                            _ = exercise.sets.removeLast() // Explicitly discard result
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "minus.circle.fill")
                        Text("Remove Set")
                    }
                    .foregroundColor(exercise.sets.isEmpty ? .gray : .red)
                    .font(.body)
                    .padding(.vertical, 5)
                }
                .disabled(exercise.sets.isEmpty) // Disable when no sets exist
            }
            .padding(.leading, 15)
            
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
}

struct Exercise: Identifiable {
    let id = UUID()
    var name: String
    var sets: [ExerciseSet] = [ExerciseSet(number: 1, weight: 0, reps: 0)]
    var allSetsCompleted: Bool = false
}


struct ExerciseSet: Identifiable {
    let id = UUID()
    var number: Int
    var weight: Double
    var reps: Int
    var date: Date = Date()
    var isCompleted: Bool = false
}


extension View {
    func customTextFieldStyle() -> some View {
        self.modifier(CustomTextFieldStyle())
    }
}
extension View {
    func customButtonStyle() -> some View {
        self.modifier(CustomButtonStyle())
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

//struct WorkoutView_Previews: PreviewProvider {
//    static var previews: some View {
//        WorkoutView(workoutTitle: .constant(""), exercises: .constant([]))
//    }
//}

