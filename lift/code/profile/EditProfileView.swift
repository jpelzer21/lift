import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct EditProfileView: View {
    @ObservedObject var userViewModel: UserViewModel
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: EditProfileViewModel
    @State private var showImagePicker = false
    
    init(userViewModel: UserViewModel) {
        self.userViewModel = userViewModel
        _viewModel = StateObject(wrappedValue: EditProfileViewModel(userViewModel: userViewModel))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                profilePictureSection
                personalInformationSection
                physicalStatsSection
                activityGoalsSection
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    saveButton
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $viewModel.profileImage)
            }
        }
    }
    
    private var saveButton: some View {
        Button("Save") {
            guard !viewModel.firstName.isEmpty, !viewModel.lastName.isEmpty else {
                // Show error to user
                return
            }
            Task {
                await viewModel.saveChanges()
                presentationMode.wrappedValue.dismiss()
            }
        }
        .bold()
        .disabled(viewModel.isSaving || viewModel.firstName.isEmpty || viewModel.lastName.isEmpty)
    }
    
    // Subviews remain the same as in previous implementation...
    private var profilePictureSection: some View {
        Section {
            HStack {
                Spacer()
                VStack {
                    if let image = viewModel.profileImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                            .shadow(radius: 5)
                    } else if let base64String = viewModel.profileImageBase64,
                              let imageData = Data(base64Encoded: base64String),
                              let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                            .shadow(radius: 5)
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .foregroundColor(.gray)
                    }
                    
                    Button(action: { showImagePicker = true }) {
                        Text("Change Photo")
                            .font(.caption)
                    }
                }
                Spacer()
            }
        }
        .listRowBackground(Color.clear)
    }
    
    // Other sections remain the same...
    private var personalInformationSection: some View {
        Section(header: Text("Personal Information")) {
            TextField("First Name", text: $viewModel.firstName)
                .autocapitalization(.words)
            
            TextField("Last Name", text: $viewModel.lastName)
                .autocapitalization(.words)
            
            TextField("Email", text: $viewModel.email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            DatePicker("Date of Birth", selection: $viewModel.birthDate, displayedComponents: .date)
        }
    }
    
    private var physicalStatsSection: some View {
        Section(header: Text("Physical Stats")) {
            Picker("Gender", selection: $viewModel.gender) {
                ForEach(Gender.allCases, id: \.self) { gender in
                    Text(gender.rawValue.capitalized).tag(gender)
                }
            }
            
            HStack {
                Text("Height")
                Spacer()
                Picker("Feet", selection: $viewModel.heightFeet) {
                    ForEach(3..<8, id: \.self) { feet in
                        Text("\(feet) ft").tag(feet)
                    }
                }
                .pickerStyle(.menu)
                
                Picker("Inches", selection: $viewModel.heightInches) {
                    ForEach(0..<12, id: \.self) { inches in
                        Text("\(inches) in").tag(inches)
                    }
                }
                .pickerStyle(.menu)
            }
            
            HStack {
                Text("Weight")
                Spacer()
                TextField("lbs", text: $viewModel.weight)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                Text("lbs")
            }
        }
    }
    
    private var activityGoalsSection: some View {
        Section(header: Text("Activity & Goals")) {
            Picker("Activity Level", selection: $viewModel.activityLevel) {
                ForEach(ActivityLevel.allCases, id: \.self) { level in
                    Text(level.description).tag(level)
                }
            }
            
            Picker("Goal", selection: $viewModel.goal) {
                ForEach(Goal.allCases, id: \.self) { goal in
                    Text(goal.rawValue.capitalized).tag(goal)
                }
            }
        }
    }
}

// MARK: - Image Picker Implementation
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - ViewModel
@MainActor
class EditProfileViewModel: ObservableObject {
    @Published var firstName: String
    @Published var lastName: String
    @Published var email: String
    @Published var birthDate: Date
    @Published var gender: Gender
    @Published var weight: String
    @Published var heightFeet: Int
    @Published var heightInches: Int
    @Published var activityLevel: ActivityLevel
    @Published var goal: Goal
    @Published var profileImage: UIImage?
    @Published var profileImageBase64: String?
    @Published var isSaving = false
    
    let userViewModel: UserViewModel
    private let db = Firestore.firestore()
    
    init(userViewModel: UserViewModel) {
        self.userViewModel = userViewModel
        
        // Handle empty states
        let nameComponents = userViewModel.userName.components(separatedBy: " ")
        self.firstName = nameComponents.first?.isEmpty == true ? "" : nameComponents.first ?? ""
        self.lastName = nameComponents.dropFirst().joined(separator: " ").trimmingCharacters(in: .whitespaces)
        self.email = userViewModel.userEmail.isEmpty ? "" : userViewModel.userEmail
        self.birthDate = userViewModel.dob ?? Date()
        self.gender = Gender(rawValue: userViewModel.gender) ?? .male
        self.weight = userViewModel.weight
        
        let totalInches = Int(userViewModel.height) ?? 69
        self.heightFeet = totalInches / 12
        self.heightInches = totalInches % 12

        self.activityLevel = ActivityLevel(rawValue: userViewModel.activityLevel) ?? .moderatelyActive
        self.goal = Goal(rawValue: userViewModel.goal) ?? .maintain
        self.profileImageBase64 = userViewModel.profileURL
    }
    
    func saveChanges() async {
        isSaving = true
        
        do {
            // Compress image if changed
            var newProfileImageBase64 = profileImageBase64
            if let image = profileImage {
                newProfileImageBase64 = compressImageToBase64(image: image)
            }
            
            // Update UserViewModel
            let heightInInches = heightFeet * 12 + heightInches
            userViewModel.updateUserProfile(
                firstName: firstName,
                lastName: lastName,
                emailInput: email,
                dobInput: birthDate,
                genderInput: gender.rawValue,
                weightInput: weight,
                heightInput: String(heightInInches),
                activityLevelInput: activityLevel.rawValue,
                goalInput: goal.rawValue,
                profileImageBase64: newProfileImageBase64
            )
            
            // Update Firestore
            try await updateFirestoreProfile(heightInInches: heightInInches, profileImageBase64: newProfileImageBase64)
        } catch {
            print("Error saving profile: \(error.localizedDescription)")
        }
        
        isSaving = false
    }
    
    private func updateFirestoreProfile(heightInInches: Int, profileImageBase64: String?) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let profileData: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "email": email,
            "birthDate": Timestamp(date: birthDate),
            "gender": gender.rawValue,
            "weight": weight,
            "height": heightInInches,
            "activityLevel": activityLevel.rawValue,
            "goal": goal.rawValue,
            "profileImageBase64": profileImageBase64 as Any,
            "lastUpdated": FieldValue.serverTimestamp()
        ]
        
        try await db.collection("users").document(uid).setData(profileData, merge: true)
    }
    
    private func compressImageToBase64(image: UIImage) -> String? {
        let targetSize = CGSize(width: 300, height: 300)
        let compressedImage = image.resized(to: targetSize)
        return compressedImage?.jpegData(compressionQuality: 0.7)?.base64EncodedString()
    }
}

// MARK: - Image Resizing Extension
extension UIImage {
    func resized(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
