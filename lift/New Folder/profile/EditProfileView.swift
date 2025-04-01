import SwiftUI

import SwiftUI

struct EditProfileView: View {
    @ObservedObject var userViewModel: UserViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var name: String
    @State private var email: String
    @State private var dob: Date
    @State private var gender: String
    @State private var weight: Int
    @State private var activityLevel: String
    @State private var goal: String

    let genderOptions = ["Not Set", "Male", "Female", "Other"]
    let activityOptions = ["Not Set", "Sedentary", "Lightly Active", "Moderately Active", "Very Active"]
    let goalOptions = ["Not Set", "Lose Weight", "Maintain Weight", "Gain Muscle"]
    
    let ageOptions = Array(5...100)
    let weightOptions = Array(stride(from: 50, to: 400, by: 5))

    init(userViewModel: UserViewModel) {
        self.userViewModel = userViewModel
        _name = State(initialValue: userViewModel.userName)
        _email = State(initialValue: userViewModel.userEmail)
        _dob = State(initialValue: userViewModel.dob ?? Date()) // Default to today if nil
        _gender = State(initialValue: genderOptions.contains(userViewModel.gender) ? userViewModel.gender : "Not Set")
        _weight = State(initialValue: Int(userViewModel.weight) ?? 150)
        _activityLevel = State(initialValue: activityOptions.contains(userViewModel.activityLevel) ? userViewModel.activityLevel : "Not Set")
        _goal = State(initialValue: goalOptions.contains(userViewModel.goal) ? userViewModel.goal : "Not Set")
    }
    
    private var age: Int {
            let calendar = Calendar.current
            let now = Date()
            let ageComponents = calendar.dateComponents([.year], from: dob, to: now)
            return ageComponents.year ?? 0
        }

    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("Personal Info")) {
                        HStack {
                            Text("Name")
                            Spacer()
                            TextField("Full Name", text: $name)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        HStack {
                            Text("Email")
                            Spacer()
                            TextField("Email", text: $email)
                                .keyboardType(.emailAddress)
                                .multilineTextAlignment(.trailing)
                        }
                    }

                    Section(header: Text("Health & Fitness Info")) {
                        HStack {
                            Text("Date of Birth")
                            Spacer()
                            DatePicker("", selection: $dob, displayedComponents: .date)
                                .labelsHidden()
                        }

                        // Display Calculated Age
                        HStack {
                            Text("Age")
                            Spacer()
                            Text("\(age) years old")
                                .foregroundColor(.gray)
                        }

                        HStack {
                            Picker("Weight", selection: $weight) {
                                ForEach(weightOptions, id: \.self) { weight in
                                    Text("\(weight) lbs")
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }

                        Picker("Gender", selection: $gender) {
                            ForEach(genderOptions, id: \.self) { option in
                                Text(option)
                            }
                        }

                        Picker("Activity Level", selection: $activityLevel) {
                            ForEach(activityOptions, id: \.self) { option in
                                Text(option)
                            }
                        }

                        Picker("Goal", selection: $goal) {
                            ForEach(goalOptions, id: \.self) { option in
                                Text(option)
                            }
                        }
                    }
                }

                // Move the button outside the Form
                Button(action: {
                    saveChanges()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Save Changes")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding() // Add padding for spacing
                }
            }
            .navigationTitle("Edit Profile")
        }
        .onTapGesture { // Dismiss the keyboard when tapping anywhere on the screen
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }

    private func saveChanges() {
        userViewModel.updateUserProfile(
            name: name,
            email: email,
            dob: dob,
            gender: gender,
            weight: String(weight),
            activityLevel: activityLevel,
            goal: goal
        )
        presentationMode.wrappedValue.dismiss()
    }
}
