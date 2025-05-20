//
//  RegistrationView.swift
//  Stat Lab
//
//  Created by Josh Pelzer on 5/18/25.
//


struct RegistrationView: View {
    @Environment(\.dismiss) var dismiss
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    
    var isSignUpDisabled: Bool {
        return firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
               lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
               email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
               password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        VStack {
            Text("Create an Account")
                .font(.largeTitle)
                .bold()
                .padding(.bottom, 20)
            
            TextField("First Name", text: $firstName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.words)
                .padding(.horizontal)
            
            TextField("Last Name", text: $lastName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.words)
                .padding(.horizontal)
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .padding(.horizontal)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
            }
            
            Button(action: register) {
                Text(isLoading ? "Creating Account..." : "Sign Up")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isSignUpDisabled ? Color.gray.opacity(0.5) : Color.pink)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            .disabled(isSignUpDisabled)
            
            Button(action: { dismiss() }) {
                Text("Already have an account? Sign In")
                    .foregroundColor(.pink)
            }
        }
        .padding()
    }
    
    func register() {
        isLoading = true
        errorMessage = nil
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            self.isLoading = false
            if let error = error {
                self.errorMessage = error.localizedDescription
            } else if let user = result?.user {
                self.saveUserData(user: user)
                dismiss()
            }
        }
    }
    
    func saveUserData(user: User) {
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).setData([
            "uid": user.uid,
            "firstName": firstName,
            "lastName": lastName,
            "email": user.email ?? "",
            "createdAt": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("❌ Error saving user data: \(error.localizedDescription)")
            } else {
                print("✅ User data successfully saved in Firestore!")
            }
        }
    }
}