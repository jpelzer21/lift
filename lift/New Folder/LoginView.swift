//
//  LoginView.swift
//  lift
//
//  Created by Josh Pelzer on 3/13/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import GoogleSignInSwift
import FirebaseCore

struct LoginView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @State private var firstName = ""
    @State private var lastName = ""
//    @State private var weight = ""
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var isSignedIn: Bool = false
    @State private var isRegistering = false // Toggle between Login and Signup
    @State private var authListener: AuthStateDidChangeListenerHandle?
    
    var body: some View {
        if isSignedIn {
            ContentView()
        } else {
            content
        }
    }
    
    var isLoginDisabled: Bool {
        return email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
               password.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty
    }
    
    var content: some View {
        VStack {
            Text(isRegistering ? "Create an Account" : "Welcome Back!")
                .font(.largeTitle)
                .bold()
                .padding(.bottom, 20)
            
            if isRegistering {
                TextField("First Name", text: $firstName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.words)
                    .padding(.horizontal)
                TextField("Last Name", text: $lastName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.words)
                    .padding(.horizontal)
//                TextField("Weight", text: $weight)
//                    .textFieldStyle(RoundedBorderTextFieldStyle())
//                    .autocapitalization(.words)
//                    .padding(.horizontal)
            }
            
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
            
            Button(action: isRegistering ? register : signIn) {
                Text(isLoading ? (isRegistering ? "Creating Account..." : "Signing In...") : (isRegistering ? "Sign Up" : "Sign In"))
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isLoginDisabled ? Color.gray.opacity(0.5) : Color.pink)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            .disabled(isLoginDisabled)
            

            Button(action: { isRegistering.toggle() }) {
                Text(isRegistering ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                    .foregroundColor(.pink)
            }
            
            Divider()
                .padding(.vertical)

            // Google Sign-In Button
            Button(action: {
                Task {
                    if let error = await signInWithGoogle() {
                        errorMessage = error  // ✅ Correct because errorMessage is a String?
                    }
                }
            }) {
                HStack {
                    Image("Google")
                        .resizable()
                        .frame(width: 24, height: 24)
                    
                    Spacer()

                    Text("Sign in with Google")
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    Spacer()
                }
                .padding()
                .background(colorScheme != .dark ? .white : Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(radius: 3)
            }
            .buttonStyle(PlainButtonStyle())
            .frame(maxWidth: .infinity)
            
            // Apple Sign-In button
            Button(action: {
                Task {
//                    _ = await signInWithGoogle()
                }
            }) {
                HStack {
                    Image(systemName: "apple.logo")
                        .resizable()
                        .frame(width: 24, height: 24)
                    
                    Spacer()

                    Text("Sign in with Apple")
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    Spacer()
                }
                .padding()
                .background(colorScheme != .dark ? .white : Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(radius: 3)
            }
            .buttonStyle(PlainButtonStyle())
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            authListener = Auth.auth().addStateDidChangeListener { _, user in
                if user != nil {
                    isSignedIn = true
                }
            }
        }
        .onDisappear {
            if let authListener = authListener {
                Auth.auth().removeStateDidChangeListener(authListener)
            }
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .padding()
    }
    
    // MARK: - Sign In Function
    func signIn() {
        print("SIGN IN() CALLED")
        isLoading = true
        errorMessage = nil
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            self.isLoading = false
            if let error = error {
                self.errorMessage = error.localizedDescription
            } else if let user = result?.user {
                print("✅ User signed in: \(user.email ?? "")")

                // Reset and force fetch user data
                UserViewModel.shared.resetUserData()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    UserViewModel.shared.fetchUserData()
                }

                self.isSignedIn = true
            }
        }
    }
    
    // MARK: - Register Function (Stores User Info in Firestore)
    func register() {
        print("REGISTER() CALLED")
        isLoading = true
        errorMessage = nil
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            self.isLoading = false
            if let error = error {
                self.errorMessage = error.localizedDescription
            } else if let user = result?.user {
                self.saveUserData(user: user)
                print("✅ User registered: \(user.email ?? "")")

                // Reset and force fetch user data
                UserViewModel.shared.resetUserData()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    UserViewModel.shared.fetchUserData()
                }

                self.isSignedIn = true
            }
        }
    }
    
    // MARK: - Save User Info to Firestore
    func saveUserData(user: User) {
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).setData([
            "uid": user.uid,
            "firstName": firstName,
            "lastName": lastName,
//            "weight": weight,
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

@MainActor
func signInWithGoogle() async -> String? {
    guard let clientID = FirebaseApp.app()?.options.clientID else {
        return "No client ID found in Firebase configuration"
    }
    
    let config = GIDConfiguration(clientID: clientID)
    GIDSignIn.sharedInstance.configuration = config
    
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let window = windowScene.windows.first,
          let rootViewController = window.rootViewController else {
        return "No root view controller found"
    }

    do {
        let userAuthentication = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        let user = userAuthentication.user
        
        guard let idToken = user.idToken else {
            return "Google Sign-In Error: ID Token Missing"
        }
        
        let accessToken = user.accessToken
        let credential = GoogleAuthProvider.credential(withIDToken: idToken.tokenString, accessToken: accessToken.tokenString)
        let result = try await Auth.auth().signIn(with: credential)
        let firebaseUser = result.user
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(firebaseUser.uid)
        
        let document = try await userRef.getDocument()
        if !document.exists {
            let firstName = user.profile?.givenName ?? "Unknown"
            let lastName = user.profile?.familyName ?? "Unknown"
            
            let userData: [String: Any] = [
                "uid": firebaseUser.uid,
                "firstName": firstName,
                "lastName": lastName,
                "email": firebaseUser.email ?? "",
                "createdAt": Timestamp(date: Date())
            ]
            
            try await userRef.setData(userData)
        }
        
        return nil  // ✅ No error
    } catch {
        return error.localizedDescription  // ✅ Return error message
    }
}
