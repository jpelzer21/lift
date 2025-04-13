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
        ZStack {
            ScrollView {
                VStack {
                    
                    // -----------------------------------------------------------------------------
                    
                    Button { // Quick Workout Button
                        let newSession = WorkoutSession(id: UUID(), title: "New Workout", exercises: [])
//                        inProgressWorkout = newSession
                        selectedWorkoutTitle = newSession.title
                        selectedExercises = newSession.exercises
                        showWorkoutView.toggle()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Quick Workout")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text("Start a fast training session")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
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
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 20)
                    .padding()
                    
                    
                    // -----------------------------------------------------------------------------
                    
                    
                    VStack { // In progress workout
                        if let workout = inProgressWorkout {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("In-Progress Workout")
                                    .font(.title2)
                                    .bold()
                                    .padding(.horizontal, 20)
                                
                                HStack {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(workout.title)
                                            .font(.headline)
                                        
                                        Text("\(workout.exercises.count) Exercise\(workout.exercises.count == 1 ? "" : "s")")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        selectedWorkoutTitle = workout.title
                                        selectedExercises = workout.exercises
                                        showWorkoutView.toggle()
                                    }) {
                                        Text("Continue")
                                            .font(.subheadline)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.pink.opacity(0.2))
                                            .foregroundColor(.pink)
                                            .cornerRadius(8)
                                    }
                                    
                                    Button(action: {
                                        withAnimation {
                                            inProgressWorkout = nil
                                        }
                                    }) {
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
                                .padding(.horizontal, 20)
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        
                    }
                    .padding()
                    
                    
                    // -----------------------------------------------------------------------------
                    
                    
                    VStack (spacing: 5) { // My Templates
                        HStack {
                            Text("My Templates:")
                                .font(.title2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .minimumScaleFactor(0.8)
                                .lineLimit(1)
                            Spacer()
                            if !viewModel.templates.isEmpty {
                                Button {
                                    showDeleteButton.toggle()
                                } label: {
                                    Image(systemName: showDeleteButton ? "ellipsis.rectangle.fill" :"ellipsis")
                                        .imageScale(.large)
                                        .frame(width: 10, height: 10)
                                        .foregroundColor(.pink)
                                        .padding()
                                        .shadow(radius: 5)
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
                        .padding(.horizontal, 20)
                        .padding()
                        
                        if viewModel.isLoading {
                            ProgressView("Loading templates...")
                                .padding()
                        } else {
                            if viewModel.templates.isEmpty {
                                VStack {
                                    Spacer()
                                    Image(systemName: "dumbbell.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 80, height: 80)
                                        .foregroundColor(.gray)
                                        .padding(.bottom, 10)
                                    
                                    Text("No Templates Yet!")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                    
                                    Text("Add a Template by pressing the + button")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    Spacer()
                                }
                                .frame(maxHeight: 150)
                                .multilineTextAlignment(.center)
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
                                    .padding(.leading, 20)
//                                    .padding(.vertical, 10)
                                }
                            }
                        }
                    }
                    .padding()
                    
                    
                    
                    // ----------------------------------------------------------------------------------------------------
                    
                    
                    
                    VStack (spacing: 5) { // My Groups
                        HStack {
                            Text("My Groups:")
                                .font(.title2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
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
                        .padding(.horizontal, 20)
                        .padding()
                        
                        if viewModel.isLoadingGroups {
                            ProgressView("Loading groups...")
                                .padding()
                        } else if viewModel.groups.isEmpty {
                            VStack {
                                Spacer()
                                
                                Text("No Groups Yet!")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                
                                Text("Join or create a group to get started")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                Spacer()
                            }
                            .frame(maxHeight: 150)
                            .multilineTextAlignment(.center)
                            .padding()
                        } else {
                            TabView {
                                ForEach(viewModel.groups) { group in
                                    GroupCard(group: group, isAdmin: group.isAdmin)
                                        .padding(.bottom, 50)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            selectedGroup = group
                                        }
                                }
                            }
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                            .frame(height: 200)
                            .padding()
                            .onAppear {
                                UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(
                                    colorScheme == .dark ? Color.white : Color.black
                                )
                                UIPageControl.appearance().pageIndicatorTintColor = UIColor.gray
                            }
                        }
                    }
                    .padding()
                    
                    // ----------------------------------------------------------------------------------------------------
                    
                    // Weekly Workouts
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Workouts This Week:")
                                .font(.title2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 20)
                        }

                        HStack(spacing: 16) {
                            ForEach(currentWeek, id: \.self) { day in
                                VStack(spacing: 6) {
                                    Text(day.shortWeekday)
                                        .font(.caption)
                                        .foregroundColor(.gray)

                                    if workedOut(on: day) {
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
                                }
                                .frame(width: 40)
                            }
                        }
                        .padding()
                        
                    }
                    .padding()
                    
                    // ----------------------------------------------------------------------------------------------------
                    
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
        }
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

struct WorkoutSession: Identifiable, Codable {
    let id: UUID
    var title: String
    var exercises: [Exercise]
}



 
 
