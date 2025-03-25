import SwiftUI

struct EditProfileView: View {
    @ObservedObject var userViewModel: UserViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var name: String
    @State private var email: String

    init(userViewModel: UserViewModel) {
        self.userViewModel = userViewModel
        _name = State(initialValue: userViewModel.userName)
        _email = State(initialValue: userViewModel.userEmail)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Info")) {
                    TextField("First Name", text: $name)
                    TextField("Last Name", text: $name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                }
                
                Button(action: {
                    userViewModel.updateUserProfile(name: name, email: email)
                    presentationMode.wrappedValue.dismiss() // Corrected line
                }) {
                    Text("Save Changes")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss() // Corrected line
            })
        }
    }
}
