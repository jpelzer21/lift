import SwiftUI
 
struct HomePageView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var viewModel: UserViewModel
    
    @State private var showWorkoutView = false
    @State private var selectedExercises: [Exercise] = []
    @State private var selectedWorkoutTitle: String = "Empty Workout"
    @State private var showDeleteButton = false
    
    @State private var showJoinGroup = false
    @State private var showCreateGroup = false
    @State private var showGroupDetail = false
    
    @State private var selectedGroup: WorkoutGroup?
    @State private var isLoadingGroups = true
    
    @State private var inProgressWorkout: WorkoutSession? = nil
    
    let workedOutDates: [Date] = [Date().addingTimeInterval(-86400 * 2), Date()]


    var currentWeek: [Date] {
        let calendar = Calendar.current
        let today = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }
    
    
    var body: some View {
        ScrollView {
            VStack (spacing: 20) {
                
                // -----------------------------------------------------------------------------
                
                Button { // Quick Workout Button
                    let newSession = WorkoutSession(id: UUID(), title: "New Workout", exercises: [])
                    selectedWorkoutTitle = newSession.title
                    selectedExercises = newSession.exercises
                    showWorkoutView.toggle()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Quick Workout")
                                .font(.title3)
                                .foregroundColor(.white)
                            
                            Text("Start a fast training session")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.vertical, 2)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.pink)
                    .cornerRadius(16)
                    .shadow(color: Color.pink.opacity(0.3), radius: 6, x: 0, y: 4)
                }
                .padding(.top, 20)
                .padding()
                
                // -----------------------------------------------------------------------------
                
                if let workout = inProgressWorkout {
                    InProgressWorkoutView(
                        workout: workout,
                        onContinue: {
                            selectedWorkoutTitle = workout.title
                            selectedExercises = workout.exercises
                            showWorkoutView.toggle()
                        },
                        onCancel: {
                            withAnimation {
                                inProgressWorkout = nil
                            }
                        }
                    )
                }
                
                // -----------------------------------------------------------------------------
                
                MyTemplatesView(viewModel: viewModel, showDeleteButton: $showDeleteButton, showWorkoutView: $showWorkoutView, selectedWorkoutTitle: $selectedWorkoutTitle, selectedExercises: $selectedExercises)
                
                // ----------------------------------------------------------------------------------------------------
                
                MyGroupsView(viewModel: viewModel, selectedGroup: $selectedGroup, showJoinGroup: $showJoinGroup, showCreateGroup: $showCreateGroup)
                
                // ----------------------------------------------------------------------------------------------------
                
                WeeklyWorkoutView(currentWeek: currentWeek, workedOut: workedOut)
                
                // ----------------------------------------------------------------------------------------------------
                
//                Rectangle()
//                    .frame(width: UIScreen.main.bounds.width, height: 20)
            }
            
        }
        .navigationTitle("Home")
        .fullScreenCover(isPresented: $showWorkoutView, onDismiss: {
            inProgressWorkout = WorkoutSession(id: UUID(), title: selectedWorkoutTitle, exercises: selectedExercises)
            viewModel.fetchTemplatesRealtime()
        }) {
            WorkoutView(workoutTitle: $selectedWorkoutTitle, exercises: $selectedExercises)
        }
        .sheet(isPresented: $showJoinGroup) {
            JoinGroupView()
        }
        .sheet(isPresented: $showCreateGroup) {
            CreateGroupView()
        }
        .sheet(item: $selectedGroup) { group in
            GroupDetailView(group: group)
        }
        .frame(width: UIScreen.main.bounds.width)
    }
    
    func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        Calendar.current.isDate(date1, inSameDayAs: date2)
    }

    func workedOut(on day: Date) -> Bool {
        workedOutDates.contains(where: { isSameDay($0, day) })
    }
    
}
 

// MARK: - Date Formatter Helper
extension Date {
    var shortWeekday: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: self)
    }
}



 extension View {
     func homeButtonStyle() -> some View {
         self.modifier(HomeButtonStyle())
     }
 }


struct MyTemplatesView: View {
    @ObservedObject var viewModel: UserViewModel
    @Binding var showDeleteButton: Bool
    @Binding var showWorkoutView: Bool
    @Binding var selectedWorkoutTitle: String
    @Binding var selectedExercises: [Exercise]

    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            HStack {
                Text("My Templates:")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()

                if !viewModel.templates.isEmpty {
                    Button {
                        showDeleteButton.toggle()
                    } label: {
                        Image(systemName: showDeleteButton ? "ellipsis.rectangle.fill" : "ellipsis")
                            .imageScale(.large)
                            .foregroundColor(.pink)
                            .padding(10)
                    }
                }

                Button {
                    selectedWorkoutTitle = "New Template"
                    selectedExercises = []
                    showWorkoutView.toggle()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("New")
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.pink.opacity(0.1))
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal)

            if viewModel.isLoading {
                ProgressView("Loading templates...")
                    .padding()
            } else if viewModel.templates.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "dumbbell.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.gray)

                    Text("No Templates Yet!")
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text("Add a Template by pressing the + button")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(viewModel.templates) { template in
                            TemplateCard(
                                templateName: template.name,
                                exercises: template.exercises,
                                showDeleteButton: showDeleteButton,
                                onTap: {
                                    selectedWorkoutTitle = template.name
                                    selectedExercises = template.exercises
                                    showWorkoutView.toggle()
                                },
                                onDelete: {
                                    viewModel.deleteTemplate(templateID: template.id)
                                }
                            )
                        }
                    }
                    .padding(.leading)
                }
            }
        }
//        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}


struct MyGroupsView: View {
    @ObservedObject var viewModel: UserViewModel
    @Binding var selectedGroup: WorkoutGroup?
    @Binding var showJoinGroup: Bool
    @Binding var showCreateGroup: Bool

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            HStack {
                Text("My Groups:")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button {
                    showJoinGroup = true
                } label: {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("Join")
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.pink.opacity(0.1))
                    .cornerRadius(10)
                }

                Button {
                    showCreateGroup = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Create")
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.pink.opacity(0.1))
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal)

            if viewModel.isLoadingGroups {
                ProgressView("Loading groups...")
                    .padding()
            } else if viewModel.groups.isEmpty {
                VStack(spacing: 10) {
                    Text("No Groups Yet!")
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text("Join or create a group to get started")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                TabView {
                    ForEach(viewModel.groups) { group in
                        GroupCard(group: group, isAdmin: group.isAdmin)
                            .padding(.bottom, 30)
                            .onTapGesture {
                                selectedGroup = group
                            }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .frame(height: 200)
                .padding(.horizontal)
                .onAppear {
                    UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(
                        colorScheme == .dark ? Color.white : Color.black
                    )
                    UIPageControl.appearance().pageIndicatorTintColor = UIColor.gray
                }
            }
        }
//        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}


struct WeeklyWorkoutView: View {
    let currentWeek: [Date]
    let workedOut: (Date) -> Bool

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            HStack {
//                Text("Weekly Workouts:")
//                    .font(.title2)
//                    .fontWeight(.semibold)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                Spacer()
            }
            .padding(.horizontal, 24)

            VStack(spacing: 16) {
                // Count / Progress
                Text("\(currentWeek.filter { workedOut($0) }.count) Workouts")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.pink)

                // Optional: Streak or percentage
                Text("Current Streak: \(calculateStreak()) days")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                HStack {
                    ForEach(currentWeek, id: \.self) { day in
                        VStack(spacing: 8) {
                            if workedOut(day) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title3)
                            } else if day < Date() {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.title3)
                            } else {
                                Text("\(Calendar.current.component(.day, from: day))")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                            Text(day.shortWeekday)
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        .frame(width: 40)
                    }
                }
                .padding(.horizontal, 10)
            }
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(colorScheme == .dark ? .systemGray6 : .white))
                    .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 4)
            )
        }
        .padding(.bottom, 30)
    }
    
    func calculateStreak() -> Int {
        let today = Date()
        let sortedDays = currentWeek.sorted().reversed()
        var streak = 0
        for day in sortedDays {
            if Calendar.current.isDate(day, inSameDayAs: today) || day < today {
                if workedOut(day) {
                    streak += 1
                } else {
                    break
                }
            }
        }
        return streak
    }
}

struct InProgressWorkoutView: View {
    var workout: WorkoutSession
    var onContinue: () -> Void
    var onCancel: () -> Void

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("In-Progress Workout")
                .font(.title2)
                .bold()
                .padding(.horizontal, 24)

            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(workout.title)
                        .font(.headline)

                    Text("\(workout.exercises.count) Exercise\(workout.exercises.count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                Spacer()

                Button(action: onContinue) {
                    Text("Continue")
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.pink.opacity(0.2))
                        .foregroundColor(.pink)
                        .cornerRadius(8)
                }

                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.title3)
                }
                .padding(.leading, 5)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : .white)
                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
            )
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 10)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}


struct WorkoutSession: Identifiable, Codable {
    let id: UUID
    var title: String
    var exercises: [Exercise]
}



 
 
