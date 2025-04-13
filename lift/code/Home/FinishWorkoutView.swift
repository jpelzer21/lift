struct FinishWorkoutView: View {
    var completedExercises: [Exercise]
    @Binding var isPresented: Bool
    var onSaveWorkout: () -> Void
    var onSaveTemplate: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Workout Complete 🎉")
                .font(.title2).bold()

            Text("You completed \(completedExercises.count) exercises:")
                .font(.subheadline)

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(completedExercises, id: \.name) { exercise in
                        Text("• \(exercise.name)")
                            .font(.body)
                    }
                }
                .padding(.horizontal)
            }
            .frame(maxHeight: 200)

            HStack(spacing: 15) {
                Button(action: {
                    onSaveTemplate()
                    onSaveWorkout()
                    isPresented = false
                }) {
                    Text("Save as Template")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button(action: {
                    onSaveWorkout()
                    isPresented = false
                }) {
                    Text("Save Workout")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            Button("Cancel") {
                isPresented = false
            }
            .foregroundColor(.red)
            .padding(.top)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .padding()
        .shadow(radius: 10)
    }
}