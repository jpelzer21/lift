import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Charts

struct ProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    @StateObject private var userViewModel = UserViewModel.shared
    
    @State private var showingAlert = false
    @State private var newWeight: String = ""
    @State private var isUpdatingWeight = false
    @State private var updateError: String?
    @State private var existingWeightDocID: String?
    @State private var showReplaceAlert = false
    @State private var weightEntries: [WeightEntry] = []

    var body: some View {
        VStack(spacing: 20) {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Card
                    NavigationLink(destination: EditProfileView(userViewModel: userViewModel)) {
                        VStack {
                            // Profile Image
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.gray)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.primary.opacity(0.2), lineWidth: 2))

                            // User Info
                            Text(userViewModel.userName)
                                .font(.title)
                                .fontWeight(.bold)

                            Text(userViewModel.userEmail)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 15)
                            .fill(colorScheme == .dark ? Color(.systemGray6) : .white))
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Navigation Buttons
                    VStack(spacing: 12) {
                        NavigationLink(destination: MeasurementsView()) {
                            CustomButton(title: "Measurements", color: .blue)
                        }
                        NavigationLink(destination: CalendarView()) {
                            CustomButton(title: "View Calendar", color: .blue)
                        }
                        NavigationLink(destination: HistoryView()) {
                            CustomButton(title: "Workout History", color: .blue)
                        }
                    }
                    .padding(.horizontal, 20)

                    // Logout Button
                    Button {
                        showingAlert = true
                    } label: {
                        CustomButton(title: "Log Out", color: .red)
                    }
                    .alert(isPresented: $showingAlert) {
                        Alert(
                            title: Text("Log Out?"),
                            message: Text("Are you sure you want to sign out?"),
                            primaryButton: .destructive(Text("Yes")) {
                                signOut()
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
            }
            Spacer()
        }
        .padding()
        .refreshable {
            userViewModel.fetchUserData()
        }
    }
    
    // Sign Out Function
    private func signOut() {
        do {
            try Auth.auth().signOut()
            UserViewModel.shared.resetUserData()
            
            presentationMode.wrappedValue.dismiss()
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = scene.windows.first {
                window.rootViewController = UIHostingController(rootView: LoginView())
                window.makeKeyAndVisible()
            }
        } catch {
            print("❌ Error signing out: \(error.localizedDescription)")
        }
    }
}

// **Weight Entry Model**
struct WeightEntry: Identifiable {
    let id = UUID()
    let weight: Double
    let date: Date
}

// Custom Button Modifier
struct CustomButton: View {
    var title: String
    var color: Color
    
    var body: some View {
        Text(title)
            .frame(maxWidth: .infinity)
            .padding()
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(radius: 5)
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
