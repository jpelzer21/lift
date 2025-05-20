struct UserOnboardingView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = UserOnboardingViewModel()
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Personal Information")) {
                    Picker("Gender", selection: $viewModel.gender) {
                        ForEach(Gender.allCases, id: \.self) { gender in
                            Text(gender.rawValue.capitalized)
                        }
                    }
                    
                    DatePicker("Date of Birth", selection: $viewModel.birthDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                    
                    HStack {
                        Text("Height")
                        Spacer()
                        TextField("cm", value: $viewModel.height, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("cm")
                    }
                    
                    HStack {
                        Text("Weight")
                        Spacer()
                        TextField("kg", value: $viewModel.weight, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("kg")
                    }
                }
                
                Section(header: Text("Activity Level")) {
                    Picker("Activity Level", selection: $viewModel.activityLevel) {
                        ForEach(ActivityLevel.allCases, id: \.self) { level in
                            Text(level.description)
                        }
                    }
                }
                
                Section(header: Text("Goal")) {
                    Picker("Primary Goal", selection: $viewModel.goal) {
                        ForEach(Goal.allCases, id: \.self) { goal in
                            Text(goal.rawValue.capitalized)
                        }
                    }
                }
                
                Section {
                    Button("Save Information") {
                        viewModel.saveUserData()
                        dismiss()
                    }
                    
                    Button("Skip for Now", role: .destructive) {
                        dismiss()
                    }
                }
            }
            .navigationTitle("Complete Your Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Supporting Enums and ViewModel
enum Gender: String, CaseIterable {
    case male, female, other, preferNotToSay
}

enum ActivityLevel: String, CaseIterable, Identifiable {
    case sedentary
    case lightlyActive
    case moderatelyActive
    case veryActive
    case extremelyActive
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .sedentary: return "Sedentary (little or no exercise)"
        case .lightlyActive: return "Lightly Active (light exercise 1-3 days/week)"
        case .moderatelyActive: return "Moderately Active (moderate exercise 3-5 days/week)"
        case .veryActive: return "Very Active (hard exercise 6-7 days/week)"
        case .extremelyActive: return "Extremely Active (very hard exercise & physical job)"
        }
    }
}

enum Goal: String, CaseIterable {
    case lose, maintain, gain
}

class UserOnboardingViewModel: ObservableObject {
    @Published var gender: Gender = .male
    @Published var birthDate: Date = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    @Published var height: Double?
    @Published var weight: Double?
    @Published var activityLevel: ActivityLevel = .moderatelyActive
    @Published var goal: Goal = .maintain
    
    func saveUserData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        
        var data: [String: Any] = [
            "gender": gender.rawValue,
            "birthDate": Timestamp(date: birthDate),
            "activityLevel": activityLevel.rawValue,
            "goal": goal.rawValue,
            "profileCompleted": true
        ]
        
        if let height = height {
            data["height"] = height
        }
        
        if let weight = weight {
            data["weight"] = weight
        }
        
        userRef.updateData(data) { error in
            if let error = error {
                print("Error updating user data: \(error.localizedDescription)")
            } else {
                print("User profile completed successfully")
                // Calculate and save target calories if needed
                self.calculateAndSaveTargetCalories()
            }
        }
    }
    
    private func calculateAndSaveTargetCalories() {
        // Implement your calorie calculation logic here
        // This is just a placeholder example
        var baseCalories: Double = 2000
        
        if let weight = weight {
            baseCalories += (weight * 10)
        }
        
        if let height = height {
            baseCalories += (height * 2)
        }
        
        // Adjust for activity level
        switch activityLevel {
        case .sedentary: baseCalories *= 1.2
        case .lightlyActive: baseCalories *= 1.375
        case .moderatelyActive: baseCalories *= 1.55
        case .veryActive: baseCalories *= 1.725
        case .extremelyActive: baseCalories *= 1.9
        }
        
        // Adjust for goal
        switch goal {
        case .lose: baseCalories -= 300
        case .maintain: break
        case .gain: baseCalories += 300
        }
        
        // Save to Firestore
        if let userId = Auth.auth().currentUser?.uid {
            let db = Firestore.firestore()
            db.collection("users").document(userId).updateData([
                "targetCalories": baseCalories,
                "proteinGoal": self.calculateProteinGoal()
            ])
        }
    }
    
    private func calculateProteinGoal() -> Double {
        // Example protein calculation (1.6-2.2g per kg of body weight)
        guard let weight = weight else { return 0 }
        let proteinPerKg: Double = goal == .gain ? 2.2 : 1.6
        return weight * proteinPerKg
    }
}