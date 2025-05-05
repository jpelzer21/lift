import SwiftUI
import UIKit

struct EditProfileView: View {
    @ObservedObject var userViewModel: UserViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var name: String
    @State private var email: String
    @State private var dob: Date
    @State private var gender: String
    @State private var weight: Int
    @State private var height: Int
    @State private var activityLevel: String
    @State private var goal: String
    
    @State private var profileImage: UIImage?
    @State private var showImagePicker = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary

    let genderOptions = ["Not Set", "Male", "Female", "Other"]
    let activityOptions = ["Not Set", "Sedentary", "Light Exercise", "Moderate Exercise", "Heavy Exercise", "Athlete"]
    let goalOptions = ["Not Set", "Lose Weight", "Maintain Weight", "Gain Muscle"]
    
    let ageOptions = Array(5...100)
    let weightOptions = Array(stride(from: 50, to: 400, by: 5))
    let heightOptions = Array(48...90)

    init(userViewModel: UserViewModel) {
        self.userViewModel = userViewModel
        _name = State(initialValue: userViewModel.userName)
        _email = State(initialValue: userViewModel.userEmail)
        _dob = State(initialValue: userViewModel.dob ?? Date()) // Default to today if nil
        _gender = State(initialValue: genderOptions.contains(userViewModel.gender) ? userViewModel.gender : "Not Set")
        _weight = State(initialValue: Int(userViewModel.weight) ?? 150)
        _activityLevel = State(initialValue: activityOptions.contains(userViewModel.activityLevel) ? userViewModel.activityLevel : "Not Set")
        _goal = State(initialValue: goalOptions.contains(userViewModel.goal) ? userViewModel.goal : "Not Set")
        _height = State(initialValue: Int(userViewModel.height) ?? 65)
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
                HStack {
                    Spacer()
                    VStack{
                        if let image = profileImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                                .shadow(radius: 5)
                                .padding(.top)
                        } else {
                            if let base64String = userViewModel.profileURL,
                               let imageData = Data(base64Encoded: base64String),
                               let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(.blue)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.blue.opacity(0.2), lineWidth: 2))
                            }
                        }
                        Button("Choose Photo") {
                            imagePickerSource = .photoLibrary
                            showImagePicker = true
                        }
                    }
                    Spacer()
                }
                
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

                    Section(header: Text("Calculate Nutrition Info")) {
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
                        
                        HStack {
                            Picker("Height", selection: $height) {
                                ForEach(heightOptions, id: \.self) { height in
                                    Text("\(height) in")
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }

                        HStack {
                            Picker("Gender", selection: $gender) {
                                ForEach(genderOptions, id: \.self) { option in
                                    Text(option)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }

                        HStack {
                            Picker("Activity Level", selection: $activityLevel) {
                                ForEach(activityOptions, id: \.self) { option in
                                    Text(option)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }

                        HStack {
                            Picker("Goal", selection: $goal) {
                                ForEach(goalOptions, id: \.self) { option in
                                    Text(option)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                    }
                }

                ZStack {
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
                    }
                    .contentShape(Rectangle())
                    .background(Color.clear)
                }
                .padding()
            }
            .navigationTitle("Edit Profile")
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $profileImage, sourceType: imagePickerSource)
        }
    }

    private func saveChanges() {
        print("SAVE CHANGES() CALLED")
        var base64String: String? = nil
        
        if let image = profileImage,
           let imageData = image.jpegData(compressionQuality: 0.01) {
            base64String = imageData.base64EncodedString()
        }

        // Save everything including the base64 string (or nil if not provided)
        userViewModel.updateUserProfile(
            nameInput: name,
            emailInput: email,
            dobInput: dob,
            genderInput: gender,
            weightInput: String(weight),
            heightInput: String(height),
            activityLevelInput: activityLevel,
            goalInput: goal,
            profileImageBase64: base64String
        )
        
        presentationMode.wrappedValue.dismiss()
        }
}


struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType = .photoLibrary

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
