struct ExerciseSelectionView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var userViewModel = UserViewModel.shared
    @Binding var selectedExercise: Exercise
    
    var body: some View {
        NavigationView {
            List(userViewModel.userExercises) { exercise in
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
            .navigationTitle("Select Exercise")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}