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
import AuthenticationServices
import CryptoKit

struct LoginView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var userViewModel: UserViewModel
        
    @State private var email = ""
    @State private var password = ""
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var isSignedIn: Bool = false
    @State private var authListener: AuthStateDidChangeListenerHandle?
    @State private var currentNonce: String?
    @State private var showingRegistration = false
    
    var isLoginDisabled: Bool {
        return email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
               password.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        if isSignedIn {
            ContentView()
        } else {
            NavigationStack {
                content
                    .navigationDestination(isPresented: $showingRegistration) {
                        RegisterView()
                    }
            }
        }
    }
    
    var content: some View {
        VStack {
            Text("Welcome Back!")
                .font(.largeTitle)
                .bold()
                .padding(.bottom, 20)
            
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
            
            Button(action: signIn) {
                Text(isLoading ? "Signing In..." : "Sign In")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isLoginDisabled ? Color.gray.opacity(0.5) : Color.pink)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            .disabled(isLoginDisabled)
            
            Divider()
                .padding(.vertical)

            // Google Sign-In Button
            Button(action: {
                Task {
                    if let error = await signInWithGoogle() {
                        errorMessage = error
                    }
                }
            }) {
                HStack {
                    Image("Google")
                        .resizable()
                        .frame(width: 24, height: 24)
                    
                    Spacer()

                    Text("Sign in with Google")
                        .foregroundColor(colorScheme != .dark ? .white : .black)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    Spacer()
                }
                .padding()
                .background(colorScheme == .dark ? .white : .black)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(radius: 3)
            }
            .buttonStyle(PlainButtonStyle())
            .frame(maxWidth: .infinity)
            .frame(height: 45)
            .cornerRadius(10)
            
            SignInWithAppleButton(
                onRequest: { request in
                    handleSignInWithAppleRequest(request)
                },
                onCompletion: { result in
                    handleSignInWithAppleCompletion(result)
                }
            )
            .frame(height: 45)
            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
            .cornerRadius(10)
            
            Button(action: { showingRegistration = true }) {
                Text("Don't have an account? Sign Up")
                    .foregroundColor(.pink)
            }
            .padding()
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
        .padding()
    }
    
    func handleSignInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
        let nonce = randomNonceString()
        currentNonce = nonce
        request.nonce = sha256(nonce)
    }
    func handleSignInWithAppleCompletion(_ request: Result<ASAuthorization, Error>) {
        print("🟡 Apple sign-in completion handler called")
        if case.failure(let failure) = request {
            errorMessage = failure.localizedDescription
        } else if case .success(let success) = request {
            if let appleIDCredential = success.credential as? ASAuthorizationAppleIDCredential {
                guard let nonce = currentNonce else {
                    fatalError("Invalid state: a login callback was recievedr ")
                }
                guard let appleIDToken = appleIDCredential.identityToken else {
                    print("unable to fetch identity token")
                    return
                }
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                    return
                }
                let credential = OAuthProvider.credential(
                    providerID: .apple,
                    idToken: idTokenString,
                    rawNonce: nonce
                )
                
                Task {
                    do {
                        let result = try await Auth.auth().signIn(with: credential)
                        let user = result.user

                        // Update display name
                        await updateDisplayName(for: user, with: appleIDCredential)

                        // Save user data in Firestore
                        let db = Firestore.firestore()
                        let userRef = db.collection("users").document(user.uid)
                        let document = try? await userRef.getDocument()

                        if document == nil || !(document?.exists ?? false) {
                            let firstName = appleIDCredential.fullName?.givenName ?? "Unknown"
                            let lastName = appleIDCredential.fullName?.familyName ?? "User"

                            try await userRef.setData([
                                "uid": user.uid,
                                "firstName": firstName,
                                "lastName": lastName,
                                "email": user.email ?? "",
                                "createdAt": Timestamp(date: Date())
                            ])
                            print("✅ Apple Sign-In user saved to Firestore.")
                        }
                    } catch {
                        print("Error authenticating: \(error.localizedDescription)")
                        errorMessage = error.localizedDescription
                    }
                }
                
            }
        }
    }
    
    func updateDisplayName(for user: User, with appleIDCredential: ASAuthorizationAppleIDCredential, force: Bool = false) async {
        let fullName = appleIDCredential.fullName
        let displayName = [fullName?.givenName, fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        
        if !displayName.isEmpty || force {
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            do {
                try await changeRequest.commitChanges()
                self.firstName = displayName
            } catch {
                print("Unable to update display name: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func randomNonceString(length: Int = 32) -> String {
        let charset: Array<Character> =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                _ = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 { return }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
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
    
    // MARK: - Save User Info to Firestore
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
