import SwiftUI
 
struct HomePageView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var viewModel: UserViewModel
    
    @State private var didFinishWorkout = false
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
                }
                .shadow(color: Color.pink.opacity(0.3), radius: 6, x: 0, y: 4)
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
                
                MyTemplatesView(
                    viewModel: viewModel,
                    showDeleteButton: $showDeleteButton,
                    showWorkoutView: $showWorkoutView,
                    selectedWorkoutTitle: $selectedWorkoutTitle,
                    selectedExercises: $selectedExercises
                )
                
                // ----------------------------------------------------------------------------------------------------
                
                MyGroupsView(
                    viewModel: viewModel,
                    selectedGroup: $selectedGroup,
                    showJoinGroup: $showJoinGroup,
                    showCreateGroup: $showCreateGroup
                )
                
                // ----------------------------------------------------------------------------------------------------
                
                WeeklyWorkoutView(
                    currentWeek: currentWeek,
                    workedOut: { date in
                        viewModel.workedOutDates.contains {
                            Calendar.current.isDate($0, inSameDayAs: date)
                        }
                    }
                )
                .padding(.bottom, 10)
                
                // ----------------------------------------------------------------------------------------------------
                
            }
            
        }
        .navigationTitle("Home")
        .fullScreenCover(isPresented: $showWorkoutView, onDismiss: {
            if !didFinishWorkout && inProgressWorkout == nil {
                inProgressWorkout = WorkoutSession(id: UUID(), title: selectedWorkoutTitle, exercises: selectedExercises)
            }
            viewModel.fetchTemplatesRealtime()
            didFinishWorkout = false
        }) {
            WorkoutView(
                workoutTitle: $selectedWorkoutTitle,
                exercises: $selectedExercises,
                onFinish: {
                    inProgressWorkout = nil
                    didFinishWorkout = true
                    showWorkoutView = false
                }
            )
        }
        .sheet(isPresented: $showJoinGroup) {
            JoinGroupView(name: viewModel.userName)
        }
        .sheet(isPresented: $showCreateGroup) {
            CreateGroupView(name: viewModel.userName)
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
        viewModel.workedOutDates.contains(where: { isSameDay($0, day) })
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
    
    @State var showTemplateAlert: Bool = false

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
                    if viewModel.templates.count < 5 {
                        selectedWorkoutTitle = "New Template"
                        selectedExercises = []
                        showWorkoutView.toggle()
                    } else {
                        showTemplateAlert = true
                    }
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
                .alert("Template Limit Reached", isPresented: $showTemplateAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("You can only join up to 5 tempalte. Please delete an existing template before making a new one.")
                }
            }
            .padding(.horizontal)

            if viewModel.isLoadingTemplates {
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
                    .padding(.vertical, 10)
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
    
    @State private var showGroupLimitAlert = false


    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            HStack {
                Text("My Groups:")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button {
                    print(viewModel.groups.count)
                    if viewModel.groups.count < 2 {
                        showJoinGroup = true
                    } else {
                        showGroupLimitAlert = true
                    }
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
                .alert("Group Limit Reached", isPresented: $showGroupLimitAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("You can only join up to 2 groups. Please leave an existing group before joining a new one.")
                }

                Button {
                    if viewModel.groups.count < 2 {
                        showCreateGroup = true
                    } else {
                        showGroupLimitAlert = true
                    }
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
                .alert("Group Limit Reached", isPresented: $showGroupLimitAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("You can only join up to 2 groups. Please leave an existing group before joining a new one.")
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
    @Environment(\.colorScheme) var colorScheme
    let currentWeek: [Date]
    let workedOut: (Date) -> Bool

    var body: some View {
        VStack {
            // Total Count
            let workoutText = currentWeek.filter { workedOut($0) }.count == 1 ? "Workout" : "Workouts"
            Text("\(currentWeek.filter { workedOut($0) }.count) \(workoutText)")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.pink)
            
            // Progress Bar or Streak
            Text("Current Streak: \(calculateStreak()) days")
                .foregroundColor(.gray)

            // Week Days Grid
            HStack {
                ForEach(currentWeek, id: \.self) { day in
                    VStack {
                        if workedOut(day) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else if day < Date() {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        } else {
                            Text("\(Calendar.current.component(.day, from: day))")
                                .foregroundColor(.primary)
                        }
                        Text(day.shortWeekday)
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .frame(width: 40)
                }
            }
            .padding(.vertical, 5)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(colorScheme == .dark ? .systemGray6 : .white))
                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
        )
    }

    func calculateStreak() -> Int {
        let today = Date()
        let sorted = currentWeek.sorted().reversed()
        var streak = 0
        for day in sorted {
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



 
 

extension AnyTransition {
    static var slideAndFade: AnyTransition {
        .move(edge: .bottom).combined(with: .opacity)
    }
}
