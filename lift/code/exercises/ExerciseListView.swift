import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ExerciseListView: View {
    @StateObject private var viewModel = ExercisesViewModel()
    @State private var showSortOptions = false
    @State private var isDeleting = false
    @State private var exerciseToDelete: String?
    @State private var showDeleteConfirmation = false
    @State private var isAddingExercise = false

    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    showSortOptions.toggle()
                }) {
                    HStack {
                        Text("Sort: \(viewModel.selectedSortOption)")
                            .font(.headline)
                            .foregroundColor(.pink)
                    }
                    .padding()
                }
                .actionSheet(isPresented: $showSortOptions) {
                    ActionSheet(title: Text("Sort By"), buttons: [
                        .default(Text("A-Z")) { viewModel.selectedSortOption = "Alphabetical A-Z"; viewModel.fetchExercises() },
                        .default(Text("Z-A")) { viewModel.selectedSortOption = "Alphabetical Z-A"; viewModel.fetchExercises() },
                        .default(Text("Most Recent")) { viewModel.selectedSortOption = "Most Recent"; viewModel.fetchExercises() },
                        .default(Text("Most Sets")) { viewModel.selectedSortOption = "Most Sets"; viewModel.fetchExercises() },
                        .default(Text("lmuscle Group")) { viewModel.selectedSortOption = "Muscle Group"; viewModel.fetchExercises() },
                        .cancel()
                    ])
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 20)
                
                if !viewModel.exercises.isEmpty {
                    Button(action: { isDeleting.toggle() }) {
                        Image(systemName: isDeleting ? "ellipsis.rectangle.fill" : "ellipsis")
                            .imageScale(.large)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 10, height: 10)
                            .foregroundColor(.pink)
                            .padding(.vertical, 5)
                            .shadow(radius: 5)
                    }
                    .padding(.trailing, 30)
                }
                
                Button {
                    isAddingExercise = true
                } label: {
                    Image(systemName: "plus")
                        .imageScale(.large)
                        .frame(width: 10, height: 10)
                        .foregroundColor(.pink)
                        .padding()
                        .shadow(radius: 5)
                }
            }
            .padding(.horizontal, 10)

            if viewModel.isLoading {
                ProgressView("Loading...").padding()
            } else if viewModel.exercises.isEmpty {
                VStack {
                    Spacer()
                    Image(systemName: "dumbbell.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.gray)
                        .padding(.bottom, 10)

                    Text("No exercises yet!")
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text("Add an exercise by pressing +!")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Spacer()
                }
                .multilineTextAlignment(.center)
                .padding(.bottom, 100)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(viewModel.exercises, id: \.name) { exercise in
                            NavigationLink(destination: {
                                if !isDeleting {
                                    AnyView(GraphView(exerciseName: exercise.name))
                                } else {
                                    AnyView(EditExerciseView(exerciseName: exercise.name))
                                }
                            }) {
                                ExerciseCard(
                                    exerciseName: exercise.name,
                                    setCount: exercise.setCount,
                                    lastSetDate: exercise.lastSetDate,
                                    isDeleting: isDeleting,
                                    deleteAction: {
                                        exerciseToDelete = exercise.name
                                        showDeleteConfirmation = true
                                    }
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
            }
        }
        .padding(.top, 50)
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text("Delete Exercise"),
                message: Text("Are you sure you want to delete \"\(exerciseToDelete ?? "")\"? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    if let exercise = exerciseToDelete {
                        viewModel.deleteExercise(named: exercise)
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .navigationTitle("Exercises")
        .sheet(isPresented: $isAddingExercise) {
            AddExerciseView()
        }
    }
}
