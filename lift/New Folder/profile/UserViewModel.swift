import FirebaseAuth
import FirebaseFirestore
import SwiftUI

class UserViewModel: ObservableObject {
    // Basic Info
    @Published var userName: String = "Loading..."
    @Published var userEmail: String = "Loading..."
    @Published var weight: String = "Loading..."
    @Published var dob: Date?
    @Published var gender: String = "Loading..."
    @Published var activityLevel: String = "Loading..."
    @Published var goal: String = "Loading..."
    
    // New Stats Fields
    @Published var workoutCount: Int = 0
    @Published var prCount: Int = 0
    @Published var dayStreak: Int = 0
    @Published var memberSince: Date = Date()
    
    // Profile Completion
    @Published var profileCompletion: Double = 0
    
    static let shared = UserViewModel()
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?

    deinit {
        listener?.remove()
    }

    init() {
        fetchUserData()
        setupRealtimeListener()
    }
    
    // MARK: - Data Fetching
    func fetchUserData() {
        guard let user = Auth.auth().currentUser else { return }
        
        let userRef = db.collection("users").document(user.uid)
        let statsRef = db.collection("userStats").document(user.uid)
        
        // Fetch basic user data
        userRef.getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Error fetching user data: \(error.localizedDescription)")
                return
            }
            
            guard let data = snapshot?.data() else { return }
            
            DispatchQueue.main.async {
                self.updateBasicInfo(from: data)
                self.calculateProfileCompletion()
            }
        }
        
        // Fetch stats data
        statsRef.getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Error fetching stats: \(error.localizedDescription)")
                return
            }
            
            guard let data = snapshot?.data() else { return }
            
            DispatchQueue.main.async {
                self.updateStats(from: data)
            }
        }
    }
    
    // MARK: - Realtime Updates
    private func setupRealtimeListener() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        listener = db.collection("userStats").document(userID)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Realtime listener error: \(error.localizedDescription)")
                    return
                }
                
                guard let data = snapshot?.data() else { return }
                
                DispatchQueue.main.async {
                    self.updateStats(from: data)
                }
            }
    }
    
    // MARK: - Data Processing
    private func updateBasicInfo(from data: [String: Any]) {
        self.userName = data["name"] as? String ?? "No Name"
        self.userEmail = data["email"] as? String ?? "No Email"
        self.weight = data["weight"] as? String ?? "0"
        self.gender = data["gender"] as? String ?? "Not Set"
        self.activityLevel = data["activityLevel"] as? String ?? "Not Set"
        self.goal = data["goal"] as? String ?? "Not Set"
        
        if let dobTimestamp = data["dob"] as? Timestamp {
            self.dob = dobTimestamp.dateValue()
        }
        
        if let createdTimestamp = data["createdAt"] as? Timestamp {
            self.memberSince = createdTimestamp.dateValue()
        } else {
            // Fallback to auth creation date
            if let authDate = Auth.auth().currentUser?.metadata.creationDate {
                self.memberSince = authDate
            }
        }
    }
    
    private func updateStats(from data: [String: Any]) {
        self.workoutCount = data["workoutCount"] as? Int ?? 0
        self.prCount = data["prCount"] as? Int ?? 0
        self.dayStreak = data["dayStreak"] as? Int ?? 0
        
        // Update streak if needed
        self.updateStreakIfNeeded()
    }
    
    private func updateStreakIfNeeded() {
        // Implement your streak logic here
        // Example: Check last workout date vs current date
    }
    
    private func calculateProfileCompletion() {
        var completedFields = 0
        let totalFields = 7 // name, email, weight, dob, gender, activity, goal
        
        if !userName.isEmpty && userName != "No Name" { completedFields += 1 }
        if !userEmail.isEmpty && userEmail != "No Email" { completedFields += 1 }
        if !weight.isEmpty && weight != "0" { completedFields += 1 }
        if dob != nil { completedFields += 1 }
        if gender != "Not Set" { completedFields += 1 }
        if activityLevel != "Not Set" { completedFields += 1 }
        if goal != "Not Set" { completedFields += 1 }
        
        self.profileCompletion = Double(completedFields) / Double(totalFields)
    }
    
    // MARK: - Update Methods
    func updateUserProfile(name: String, email: String, dob: Date, gender: String,
                         weight: String, activityLevel: String, goal: String) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let userData: [String: Any] = [
            "name": name,
            "email": email,
            "dob": Timestamp(date: dob),
            "gender": gender,
            "weight": weight,
            "activityLevel": activityLevel,
            "goal": goal
        ]
        
        db.collection("users").document(userID).setData(userData, merge: true) { error in
            if let error = error {
                print("❌ Profile update failed: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    self.updateBasicInfo(from: userData)
                    self.calculateProfileCompletion()
                }
            }
        }
    }
    
    func incrementWorkoutCount() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let statsRef = db.collection("userStats").document(userID)
        statsRef.setData([
            "workoutCount": FieldValue.increment(Int64(1)),
            "lastWorkoutDate": Timestamp(date: Date())
        ], merge: true)
    }
    
    // MARK: - Reset
    func resetUserData() {
        DispatchQueue.main.async {
            self.userName = "Loading..."
            self.userEmail = "Loading..."
            self.weight = "Loading..."
            self.dob = nil
            self.gender = "Loading..."
            self.activityLevel = "Loading..."
            self.goal = "Loading..."
            self.workoutCount = 0
            self.prCount = 0
            self.dayStreak = 0
            self.memberSince = Date()
            self.profileCompletion = 0
        }
    }
}
