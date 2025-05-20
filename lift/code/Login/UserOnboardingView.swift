import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct UserOnboardingView: View {
    @Environment(\.dismiss) var dismiss
    
    // Personal Information
    @State private var gender: Gender = .male
    @State private var birthDateString: String = ""
    @State private var heightFeet: Int = 0
    @State private var heightInches: Int = 0
    @State private var weight: String = ""
    @State private var dobError: String?
    
    // Activity Level
    @State private var activityLevel: ActivityLevel = .moderatelyActive
    
    // Goal
    @State private var goal: Goal = .maintain
    
    // UI Options
    let feetOptions = Array(3...7)
    let inchesOptions = Array(0...11)
    
    var onComplete: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Personal Information")) {
                    Picker("Gender", selection: $gender) {
                        ForEach(Gender.allCases, id: \.self) { gender in
                            Text(gender.rawValue.capitalized)
                        }
                    }
                    
                    TextField("Date of Birth (MM/DD/YYYY)", text: $birthDateString)
                        .foregroundColor(dobError != nil ? .red : .primary)
                        .onChange(of: birthDateString) { oldValue, newValue in
                            formatBirthDateInput()
                            _ = parseBirthDate()
                        }

                    if let dobError = dobError {
                        Text(dobError)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    HStack {
                        Text("Height")
                        Spacer()
                        Picker("Feet", selection: $heightFeet) {
                            ForEach(feetOptions, id: \.self) { feet in
                                Text("\(feet) ft")
                            }
                        }
                        .pickerStyle(.menu)
                        
                        Picker("Inches", selection: $heightInches) {
                            ForEach(inchesOptions, id: \.self) { inches in
                                Text("\(inches) in")
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    TextField("Weight (lbs)", text: $weight)
                        .keyboardType(.decimalPad)
                        .onChange(of: weight) { oldValue, newValue in
                            formatWeightInput()
                        }
                }
                
                Section(header: Text("Activity Level")) {
                    Picker("Activity Level", selection: $activityLevel) {
                        ForEach(ActivityLevel.allCases, id: \.self) { level in
                            Text(level.description)
                        }
                    }
                }
                
                Section(header: Text("Goal")) {
                    Picker("Primary Goal", selection: $goal) {
                        ForEach(Goal.allCases, id: \.self) { goal in
                            Text(goal.rawValue.capitalized)
                        }
                    }
                }
                
                Section {
                    Button("Save Information") {
                        saveUserData { success, error in
                            if success {
                                dismiss()
                                onComplete()
                            } else {
                                // Show error to user
                                print("Error saving: \(error?.localizedDescription ?? "Unknown error")")
                            }
                        }
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
                        onComplete()
                    }
                }
            }
        }
    }
    
    
    
    // MARK: - Data Saving
    private func saveUserData(completion: @escaping (Bool, Error?) -> Void) {
        // Validate date first
        guard parseBirthDate() != nil else {
            completion(false, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: dobError ?? "Invalid date"]))
            return
        }
        
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(false, nil)
            return
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        
        // Calculate total height in inches
        let totalHeightInInches = (heightFeet * 12) + heightInches
        
        // Prepare data dictionary
        var data: [String: Any] = [
            "profileCompleted": true,
            "lastUpdated": Timestamp(date: Date()),
            "gender": gender.rawValue,
            "height": String(totalHeightInInches),
            "activityLevel": activityLevel.rawValue,
            "goal": goal.rawValue
        ]
        
        // Add weight if valid
        if let weightValue = Double(weight) {
            data["weight"] = String(weightValue)
        }
        
        // Add birth date if valid
        if let birthDate = parseBirthDate() {
            data["birthDate"] = Timestamp(date: birthDate)
            data["age"] = calculateAge(birthDate: birthDate)
        }
        
        // Merge rather than overwrite entire document
        userRef.setData(data, merge: true) { error in
            if let error = error {
                print("Error updating user data: \(error.localizedDescription)")
                completion(false, error)
            } else {
                print("User profile updated successfully")
                
                // Update UserViewModel with the new data
                DispatchQueue.main.async {
                    let userViewModel = UserViewModel.shared
                    userViewModel.gender = self.gender.rawValue
                    userViewModel.height = String(totalHeightInInches)
                    userViewModel.activityLevel = self.activityLevel.rawValue
                    userViewModel.goal = self.goal.rawValue
                    userViewModel.weight = self.weight
                    userViewModel.dob = self.parseBirthDate()
                    userViewModel.profileCompletion = 1.0
                    
                    // Trigger any necessary recalculations
                    userViewModel.calculateProfileCompletion()
                    userViewModel.calculateCaloricIntake()
                }
                
                completion(true, nil)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func parseBirthDate() -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        
        guard let date = formatter.date(from: birthDateString) else {
            dobError = "Invalid date format"
            return nil
        }
        
        // Check if date is in the future
        if date > Date() {
            dobError = "Date must be in the past"
            return nil
        }
        
        dobError = nil
        return date
    }
    
    private func calculateAge(birthDate: Date) -> Int {
        Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
    }
    
    private func formatBirthDateInput() {
        // Remove non-numeric characters
        var cleaned = birthDateString.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        // Add slashes for MM/DD/YYYY format
        if cleaned.count > 2 {
            cleaned.insert("/", at: cleaned.index(cleaned.startIndex, offsetBy: 2))
        }
        if cleaned.count > 5 {
            cleaned.insert("/", at: cleaned.index(cleaned.startIndex, offsetBy: 5))
        }
        
        // Limit to 10 characters
        birthDateString = String(cleaned.prefix(10))
    }
    
    private func formatWeightInput() {
        weight = weight.filter { $0.isNumber || $0 == "." }
    }
}

// Supporting Enums
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
