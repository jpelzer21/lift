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
    
    @Published var userExercises: [Exercise] = []
    
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
//        
//        // Fetch stats data
//        statsRef.getDocument { [weak self] snapshot, error in
//            guard let self = self else { return }
//            
//            if let error = error {
//                print("❌ Error fetching stats: \(error.localizedDescription)")
//                return
//            }
//            
//            guard let data = snapshot?.data() else { return }
//            
//            DispatchQueue.main.async {
//                self.updateStats(from: data)
//            }
//        }
    }
    
    // MARK: - Realtime Updates
    private func setupRealtimeListener() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        listener = db.collection("users").document(userID)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Realtime listener error: \(error.localizedDescription)")
                    return
                }
                
                guard let data = snapshot?.data() else {
                    print("No data received from listener")
                    return
                }
                
                print("Received stats update: \(data)") // Debug print
                
                self.updateStats(from: data)
            }
    }
    
    
    func fetchExercises(completion: (() -> Void)? = nil) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("User not authenticated")
            completion?()
            return
        }
        
        db.collection("users").document(userID).collection("exercises")
            .order(by: "name") // Alphabetical ordering
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else {
                    completion?()
                    return
                }
                
                if let error = error {
                    print("❌ Error fetching exercises: \(error.localizedDescription)")
                    completion?()
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No exercises found")
                    completion?()
                    return
                }
                
                let fetchedExercises = documents.compactMap { doc -> Exercise? in
                    let data = doc.data()
                    return self.parseExerciseDocument(docID: doc.documentID, data: data)
                }
                
                DispatchQueue.main.async {
                    self.userExercises = fetchedExercises
                    completion?()
                }
            }
    }

    private func parseExerciseDocument(docID: String, data: [String: Any]) -> Exercise? {
        guard let name = data["name"] as? String else {
            print("Exercise missing name field")
            return nil
        }
        
        let muscleGroups = data["muscleGroups"] as? [String] ?? []
        let barType = data["barType"] as? String ?? "Barbell"
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        let setCount = data["setCount"] as? Int ?? 0
        
        // If you have exercise sets stored in Firestore
        var sets: [ExerciseSet] = []
        if let setsData = data["sets"] as? [[String: Any]] {
            sets = setsData.compactMap { setData in
                guard let number = setData["number"] as? Int,
                      let weight = setData["weight"] as? Double,
                      let reps = setData["reps"] as? Int else {
                    return nil
                }
                return ExerciseSet(number: number, weight: weight, reps: reps)
            }.sorted { $0.number < $1.number }
        }
        
        return Exercise(
            name: name,
            muscleGroups: muscleGroups,
            barType: barType,
            sets: sets,
            createdAt: createdAt,
            setCount: setCount
        )
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
        let newWorkoutCount = data["workoutCount"] as? Int ?? 0
        let newPrCount = data["prCount"] as? Int ?? 0
        let newDayStreak = data["dayStreak"] as? Int ?? 0
        
        // Only update if values changed to avoid unnecessary view refreshes
        if newWorkoutCount != workoutCount || newPrCount != prCount || newDayStreak != dayStreak {
            DispatchQueue.main.async { [weak self] in
                self?.workoutCount = newWorkoutCount
                self?.prCount = newPrCount
                self?.dayStreak = newDayStreak
                // No need to manually send objectWillChange as @Published properties do this automatically
            }
        }
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
    
    func fetchUserExercises() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userID).collection("exercises")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching exercises: \(error.localizedDescription)")
                    return
                }
                
                self.userExercises = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    let name = data["name"] as? String ?? ""
                    return Exercise(name: name, sets: [ExerciseSet(number: 1, weight: 0, reps: 0)])
                } ?? []
            }
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
