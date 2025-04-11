import SwiftUI
//import FirebaseFirestore
//import FirebaseAuth
 
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
    
    
    var body: some View {
//        ScrollView {
            VStack {
                Text("Quick Workout:")
                    .font(.title2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 20).padding(.top, 30)
                
                Button {
                    selectedWorkoutTitle = "New Workout"
                    selectedExercises = []
                    showWorkoutView.toggle()
                } label: {
                    Text("Start New Workout")
                        .frame(width: UIScreen.main.bounds.width-60, height: 25, alignment: .center)
                }
                .buttonStyle(.borderedProminent)
                .homeButtonStyle()

                HStack {
                    Text("My Templates:")
                        .font(.title2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 20)
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
                            Text("New Template")
                        }
                        .font(.subheadline)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.pink.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
                .padding(.trailing, 20)

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
                            .padding(.vertical, 10)
                        }
                    }
                    
                    
                    // ----------------------------------------------------------------------------------------------------
                    
                    HStack {
                        Text("My Groups:")
                            .font(.title2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 20)

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
                        .padding(.trailing, 20)
                    }
                    .padding(.top, 10)

                
                    TabView {
                        ForEach(viewModel.groups) { group in
                            GroupCard(group: group, isAdmin: group.isAdmin)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    print("Tapped on group: \(group.name)")
                                    selectedGroup = group
                                }
                        }
                    }
                    .tabViewStyle(PageTabViewStyle())
                    .onAppear {
                        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(
                            colorScheme == .dark ? Color(.white) : Color(.black)
                        )
                        UIPageControl.appearance().pageIndicatorTintColor = UIColor(.gray)
                    }
                    
                    // ----------------------------------------------------------------------------------------------------
                    
                    
                    
                    Spacer()
                }
                Spacer()
            }
//        }
        .navigationTitle("Home")
        .fullScreenCover(isPresented: $showWorkoutView, onDismiss: {
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
 


 extension View {
     func homeButtonStyle() -> some View {
         self.modifier(HomeButtonStyle())
     }
 }

 
 
 //
 //struct HomePageView_Previews: PreviewProvider {
 //    static var previews: some View {
 //        HomePageView()
 //    }
 //}


//struct ExampleExercises: View {
//    var body: some View {
//        Text("Example Templates:")
//            .font(.title2)
//            .frame(maxWidth: .infinity, alignment: .leading)
//            .padding(.leading, 20)
//            .padding(.top, 20)
//        ScrollView (.horizontal, showsIndicators: false) {
//            HStack(spacing: 10){
//                ForEach(ExampleTemplates.templates) { template in
//                    TemplateCard(
//                        templateName: template.name,
//                        exercises: template.exercises,
//                        showDeleteButton: false,
//                        onTap: {
//                            selectedWorkoutTitle = template.name
//                            selectedExercises = template.exercises
//                            showWorkoutView.toggle()
//                        },
//                        onDelete: {}
//                    )
//                    .transition(.opacity) // Fade animation
////                                .animation(.easeInOut(duration: 0.3), value: template)
//                }
//            }.padding(.leading, 20).padding(.vertical, 10)
//        }
//    }
//}
