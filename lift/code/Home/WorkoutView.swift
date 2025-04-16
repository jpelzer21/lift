import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct WorkoutView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var userViewModel: UserViewModel
    
    @Binding var workoutTitle: String
    @Binding var exercises: [Exercise]
    
    @State private var isLoading = false
    @State private var error: Error?
    @State private var showingAlert = false
    @State private var showingFinishWorkout = false
    @State private var showingErrorAlert: Bool = false
    @State private var isEditingTitle: Bool = false
    @State private var showToast = false
    
    @State private var isReordering = false
    @State private var draggedExercise: Exercise?
    @State private var dragOverIndex: Int?

    private let db = Firestore.firestore()
    var onFinish: (() -> Void)? = nil
    
    var body: some View {
        ZStack {
            NavigationView {
                ScrollViewReader { scrollProxy in
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
                                .multilineTextAlignment(.center)
                                .customTextFieldStyle()
                            } else {
                                Text(workoutTitle)
                                    .font(.largeTitle)
                                    .fontWeight(.medium)
                                    .multilineTextAlignment(.center)
                                    .onTapGesture {
                                        isEditingTitle = true
                                    }
                            }
                            
                            VStack {
                                ForEach(exercises.indices, id: \.self) { index in
                                    if isReordering {
                                        if dragOverIndex == index {
                                            // Highlight the space between exercises
                                            Rectangle()
                                                .fill(Color.blue.opacity(0.5))
                                                .frame(height: 8)
                                                .transition(.opacity)
                                        }
                                        
                                        Text(exercises[index].name)
                                            .font(.headline)
                                            .padding()
                                            .frame(maxWidth: .infinity)
                                            .background(Color.gray.opacity(0.2))
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .onDrag {
                                                self.draggedExercise = exercises[index]
                                                return NSItemProvider(object: exercises[index].name as NSString)
                                            }
                                            .onDrop(of: [.plainText], delegate: ExerciseDropDelegate(
                                                targetIndex: index,
                                                exercises: $exercises,
                                                draggedExercise: $draggedExercise,
                                                dragOverIndex: $dragOverIndex
                                            ))
                                    } else {
                                        ExerciseView(exercise: Binding(
                                            get: { exercises[index] },
                                            set: { newExercise in
                                                exercises[index] = newExercise
                                            }
                                        ), deleteAction: {
                                            exercises.remove(at: index)
                                        })
                                        .onLongPressGesture {
                                            withAnimation {
                                                isReordering = true
                                            }
                                        }
                                    }
                                }
                            }
                            if !isReordering {
                                HStack {
                                    Spacer()
                                    Button("Add Exercise") {
                                        let generator = UIImpactFeedbackGenerator(style: .medium)
                                        generator.impactOccurred()
                                        
                                        // Add the new exercise and get its index
                                        let newIndex = exercises.count
                                        exercises.append(Exercise(name: "New Exercise", sets: [
                                            ExerciseSet(number: 1, weight: 0, reps: 0)
                                        ]))
                                        
                                        // Scroll to the new exercise after a tiny delay
                                        DispatchQueue.main.async {
                                            withAnimation {
                                                scrollProxy.scrollTo(newIndex, anchor: .bottom)
                                            }
                                        }
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
                            } else {
                                Button("Done") {
                                    withAnimation {
                                        isReordering.toggle()
                                    }
                                }
                                .padding()
                                .background(isReordering ? Color.green.opacity(0.3) : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            
                            
                        }
                        .onAppear {
                            if workoutTitle == "New Template" || workoutTitle == "New Workout" {
                                isEditingTitle = true
                            }
                            loadWorkoutTemplate()
                        }
                        .ignoresSafeArea(.all)
                    }
                    .overlay(
                        toastMessage()
                            .opacity(showToast ? 1 : 0) // Show when needed
                            .animation(.easeInOut(duration: 0.3), value: showToast)
                    )
                }
                
                .onTapGesture { // Dismiss the keyboard when tapping anywhere on the screen
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .toolbarBackgroundVisibility(.hidden)
                .navigationBarItems(trailing: Button("Finish Workout") {
                    for i in exercises.indices {
                        let sets = exercises[i].sets
                        exercises[i].allSetsCompleted = sets.allSatisfy { $0.isCompleted }
                    }
                    showingFinishWorkout = true
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
                UserViewModel.shared.fetchUserExercises()
            }
            .onDisappear {
                UIApplication.shared.isIdleTimerDisabled = false
            }
            
            
            
            if showingFinishWorkout {
                ZStack {
                    Rectangle()
                        .background(.ultraThinMaterial)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea(.all)
                    FinishWorkoutView(
                        completedExercises: exercises.filter { $0.allSetsCompleted },
                        isPresented: $showingFinishWorkout,
                        onSaveWorkout: {
                            saveWorkout()
                            saveExercises()
                            onFinish?()
                            presentationMode.wrappedValue.dismiss()
                        },
                        onSaveTemplate: {
                            onFinish?()
                            saveWorkoutAsTemplate()
                        }
                    )
                }
            }
            
            
        }
        
    }
    
    private func toastMessage() -> some View {
        VStack {
            Spacer()
            Text("Template Saved ✅")
                .padding()
                .background(Color.green.opacity(0.8))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.bottom, 50)
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
            isLoading = true
            userViewModel.saveExercises(exercises: exercises) { error in
                isLoading = false
                if let error = error {
                    self.error = error
                    print("Error saving exercises: \(error.localizedDescription)")
                } else {
                    print("Exercises saved successfully")
                }
            }
        }
        
        private func saveWorkout() {
            userViewModel.workedOutDates.append(Date())
            print("Workout Date: \(userViewModel.workedOutDates)")
            isLoading = true
            userViewModel.saveWorkout(title: workoutTitle, exercises: exercises) { error in
                isLoading = false
                if let error = error {
                    self.error = error
                    print("Error saving workout: \(error.localizedDescription)")
                } else {
                    print("Workout saved successfully")
                }
            }
        }
        
        private func saveWorkoutAsTemplate() {
            isLoading = true
            userViewModel.saveWorkoutAsTemplate(title: workoutTitle, exercises: exercises) { isUpdate, error in
                isLoading = false
                if let error = error {
                    self.error = error
                    print("Error saving template: \(error.localizedDescription)")
                } else {
                    showToast = true
                    print("Template \(isUpdate ? "updated" : "saved") successfully")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showToast = false
                    }
                }
            }
        }
        
        private func loadWorkoutTemplate() {
            isLoading = true
            userViewModel.loadWorkoutTemplate(title: workoutTitle) { exercises, error in
                isLoading = false
                if let error = error {
                    self.error = error
                    print("Error loading template: \(error.localizedDescription)")
                } else if let exercises = exercises {
                    self.exercises = exercises
                    print("Template loaded successfully")
                }
            }
        }
}




struct ExerciseView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var exercise: Exercise
    @State private var showingExerciseSelection = false
    @State private var showingDeleteAlert = false
    var deleteAction: () -> Void

    let generator = UIImpactFeedbackGenerator(style: .medium)
    
    private let doubleFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        return numberFormatter
    }()
    
    private let intFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .none
        return numberFormatter
    }()

    var body: some View {
        VStack(spacing: 10) {
            // Exercise Title and Delete Button
            HStack {
                
                Button(action: {
                    showingExerciseSelection = true
                }) {
                    HStack {
                        Text(exercise.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                    )
                }
                .sheet(isPresented: $showingExerciseSelection) {
                    ExerciseSelectionView(selectedExercise: $exercise)
                }

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
                        
                        TextField("0", value: $set.reps, formatter: intFormatter)
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
                    .background(Color.clear)
                    .saturation(0.8)
                    .cornerRadius(10)
                    .animation(.easeInOut, value: set.isCompleted)
                }
            }

            HStack { // add and remove sets
                Button(action: {
                    if let lastSet = exercise.sets.last {
                        let newSet = ExerciseSet(
                            number: exercise.sets.count + 1,
                            weight: lastSet.weight,
                            reps: lastSet.reps
                        )
                        withAnimation {
                            exercise.sets.append(newSet)
                        }
                    } else {
                        let newSet = ExerciseSet(number: 1, weight: 0, reps: 0)
                        withAnimation {
                            exercise.sets.append(newSet)
                        }
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
                            _ = exercise.sets.removeLast()
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
                .disabled(exercise.sets.isEmpty)
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

struct Exercise: Identifiable, Codable {
    var id = UUID()
    var name: String
    var muscleGroups: [String] = []
    var barType: String = "Other"
    var sets: [ExerciseSet] = [ExerciseSet(number: 1, weight: 0, reps: 0)]
    var createdAt: Date = Date()
    var setCount: Int = 0
    var allSetsCompleted: Bool = false
}


struct ExerciseSet: Identifiable, Codable {
    var id = UUID()
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


struct ExerciseDropDelegate: DropDelegate {
    let targetIndex: Int
    @Binding var exercises: [Exercise]
    @Binding var draggedExercise: Exercise?
    @Binding var dragOverIndex: Int?

    func dropEntered(info: DropInfo) {
        if let draggedExercise = draggedExercise,
           let fromIndex = exercises.firstIndex(where: { $0.id == draggedExercise.id }),
           fromIndex != targetIndex {
            dragOverIndex = targetIndex  // Highlight the space between exercises
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        guard let draggedExercise = draggedExercise,
              let fromIndex = exercises.firstIndex(where: { $0.id == draggedExercise.id }) else {
            return false
        }

        if fromIndex != targetIndex {
            withAnimation {
                let movedExercise = exercises.remove(at: fromIndex)
                let adjustedIndex = fromIndex < targetIndex ? targetIndex - 1 : targetIndex
                exercises.insert(movedExercise, at: adjustedIndex)
            }
        }
        
        dragOverIndex = nil
        self.draggedExercise = nil
        return true
    }

    func dropExited(info: DropInfo) {
        dragOverIndex = nil
    }
}



