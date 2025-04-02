import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Charts

struct ProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
//    @StateObject private var userViewModel = UserViewModel.shared
    @EnvironmentObject private var userViewModel: UserViewModel
    
    // State variables
    @State private var showingLogoutAlert = false
    @State private var weightEntries: [WeightEntry] = []
    
    // UI Constants
    private let cardPadding: CGFloat = 20
    private let cardCornerRadius: CGFloat = 16
    private let sectionSpacing: CGFloat = 24
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: sectionSpacing) {
                    // Profile Header
                    profileHeaderSection
                    
                    // Quick Stats
                    quickStatsSection
                    
                    // Navigation Grid
                    navigationGridSection
                    
                    // Account Section
                    accountSection
                }
                .padding(.vertical)
            }
//            .background(Color(.systemGroupedBackground))
            
//            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
        .navigationTitle("Profile")
    }
    
    // MARK: - Profile Header Section
    private var profileHeaderSection: some View {
        NavigationLink(destination: EditProfileView(userViewModel: userViewModel)) {
            HStack(spacing: 16) {
                // Profile Image
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .foregroundColor(.blue)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.blue.opacity(0.2), lineWidth: 2))
                
                // User Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(userViewModel.userName)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(userViewModel.userEmail)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Member since \(userViewModel.memberSince.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: cardCornerRadius)
                    .fill(Color(.secondarySystemBackground))
            )
            .padding(.horizontal, cardPadding)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Quick Stats Section
    private var quickStatsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Stats")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
                Button("See All") {}
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, cardPadding)
            
            HStack(spacing: 12) {
                // Workouts This Week
                statCard(value: "\(userViewModel.workoutCount)", label: "Workouts", icon: "flame.fill", color: .orange)
                
                // PRs This Month
                statCard(value: "\(userViewModel.prCount)", label: "PRs", icon: "trophy.fill", color: .yellow)
                
                // Current Streak
                statCard(value: "\(userViewModel.dayStreak)", label: "Day Streak", icon: "bolt.fill", color: .green)
            }
            
            .padding(.horizontal, cardPadding)
        }
    }
    
    // MARK: - Navigation Grid Section
    private var navigationGridSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Quick Access")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, cardPadding)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                NavigationLink(destination: MeasurementsView()) {
                    gridButton(title: "Measurements", icon: "ruler.fill", color: .purple)
                }
                
                NavigationLink(destination: ExerciseListView()) {
                    gridButton(title: "Exercises", icon: "dumbbell.fill", color: .blue)
                }
                
                NavigationLink(destination: CalendarView()) {
                    gridButton(title: "Calendar", icon: "calendar", color: .green)
                }
                
                NavigationLink(destination: HistoryView()) {
                    gridButton(title: "History", icon: "clock.fill", color: .orange)
                }
            }
            .padding(.horizontal, cardPadding)
        }
    }
    
    // MARK: - Account Section
    private var accountSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Account")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, cardPadding)
            
            VStack(spacing: 0) {
                // Help & Support
                NavigationLink(destination: CalendarView()) {
                    settingsRow(title: "Help & Support", icon: "questionmark.circle.fill", color: .gray)
                }
                
                Divider()
                    .padding(.leading, 52)
                
                // Notifications
                NavigationLink(destination: CalendarView()) {
                    settingsRow(title: "Notifications", icon: "bell.badge.fill", color: .red)
                }
                
                Divider()
                    .padding(.leading, 52)
                
                // Logout Button
                Button(action: { showingLogoutAlert = true }) {
                    settingsRow(title: "Log Out", icon: "arrow.left.circle.fill", color: .red)
                }
                .alert(isPresented: $showingLogoutAlert) {
                    Alert(
                        title: Text("Log Out?"),
                        message: Text("Are you sure you want to sign out?"),
                        primaryButton: .destructive(Text("Yes"), action: signOut),
                        secondaryButton: .cancel()
                    )
                }
            }
            .background(
                RoundedRectangle(cornerRadius: cardCornerRadius)
                    .fill(Color(colorScheme == .dark ? Color(.systemGray6) : .white))
            )
            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
            .padding(.horizontal, cardPadding)
        }
    }
    
    // MARK: - Component Builders
    private func statCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: cardCornerRadius)
                .fill(Color(colorScheme == .dark ? Color(.systemGray6) : .white))
        )
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
    }
    
    private func gridButton(title: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color(colorScheme == .dark ? .white : .black))
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .background(
                RoundedRectangle(cornerRadius: cardCornerRadius)
                    .fill(Color(colorScheme == .dark ? .systemGray6 : .white))
                    .overlay(
                        RoundedRectangle(cornerRadius: cardCornerRadius)
                            .stroke(color.opacity(0.5), lineWidth: 2) // Border with slight transparency
                    )
            )
    }
    
    private func settingsRow(title: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(title == "Log Out" ? .red : .primary)
            
            Spacer()
            
            if title != "Log Out" {
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray.opacity(0.5))
            }
        }
        .padding()
    }
    
    // MARK: - Actions
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

// MARK: - Preview
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}

// MARK: - Models
struct WeightEntry: Identifiable {
    let id = UUID()
    let weight: Double
    let date: Date
}
