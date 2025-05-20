struct UserDetailsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var userViewModel: UserViewModel
    
    @State private var weight: String = ""
    @State private var height: String = ""
    @State private var dateOfBirth = Date()
    @State private var gender: String = "Male"
    @State private var activityLevel: String = "Moderate"
    @State private var goal: String = "Maintain"
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    let genders = ["Male", "Female", "Other"]
    let activityLevels = ["Sedentary", "Light Exercise", "Moderate Exercise", "Heavy Exercise", "Athlete"]
    let goals = ["Lose Weight", "Maintain", "Gain Muscle"]
    
    var userId: String
    
    var body: some View {
        Form {
            Section(header: Text("Personal Information")) {
                TextField("Weight (lbs)", text: $weight)
                    .keyboardType(.decimalPad)
                
                TextField("Height (inches)", text: $height)
                    .keyboardType(.decimalPad)
                
                DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                    .datePickerStyle(.compact)
                
                Picker("Gender", selection: $gender) {
                    ForEach(genders, id: \.self) {
                        Text($0)
                    }
                }
            }
            
            Section(header: Text("Activity Level")) {
                Picker("Activity Level", selection: $activityLevel) {
                    ForEach(activityLevels, id: \.self) {
                        Text($0)
                    }
                }
            }
            
            Section(header: Text("Goal")) {
                Picker("Goal", selection: $goal) {
                    ForEach(goals, id: \.self) {
                        Text($0)
                    }
                }
            }
            
            if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                }
            }
            
            Section {
                Button(action: saveUserDetails) {
                    HStack {
                        Spacer()
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Complete Registration")
                                .bold()
                        }
                        Spacer()
                    }
                }
                .disabled(isLoading || weight.isEmpty || height.isEmpty)
            }
        }
        .navigationTitle("Additional Information")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func saveUserDetails() {
        isLoading = true
        errorMessage = nil
        
        guard let weightValue = Double(weight),
              let heightValue = Double(height) else {
            errorMessage = "Please enter valid weight and height"
            isLoading = false
            return
        }
        
        // Update UserViewModel with the collected data
        userViewModel.weight = String(weightValue)
        userViewModel.height = String(heightValue)
        userViewModel.dob = dateOfBirth
        userViewModel.gender = gender
        userViewModel.activityLevel = activityLevel
        userViewModel.goal = goal
        
        // Calculate nutrition goals using your existing method
        userViewModel.calculateCaloricIntake()
        
        // Prepare data for Firestore
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        
        let updateData: [String: Any] = [
            "weight": weightValue,
            "height": heightValue,
            "dateOfBirth": Timestamp(date: dateOfBirth),
            "gender": gender,
            "activityLevel": activityLevel,
            "goal": goal,
            "dailyCalories": userViewModel.goalCalories,
            "dailyProtein": userViewModel.goalProtein,
            "dailyCarbs": userViewModel.goalCarbs,
            "dailyFat": userViewModel.goalFat,
            "dailySugars": userViewModel.goalSugars,
            "updatedAt": Timestamp(date: Date())
        ]
        
        userRef.updateData(updateData) { error in
            isLoading = false
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                dismiss()
            }
        }
    }
}