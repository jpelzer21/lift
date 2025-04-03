import FirebaseAuth
import FirebaseFirestore
import SwiftUI

class UserViewModel: ObservableObject {
    
    // Template Info
    @Published var templates: [WorkoutTemplate] = []
    @Published var isLoading = false
    
    
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
    @Published var lastWorkoutDate: Date?
    @Published var memberSince: Date = Date()
    
    // Profile Completion
    @Published var profileCompletion: Double = 0
    
    @Published var userExercises: [Exercise] = []
    
    static let shared = UserViewModel()
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var statsListener: ListenerRegistration?
    private var userID: String? {
        Auth.auth().currentUser?.uid
    }
    private var authStateListener: AuthStateDidChangeListenerHandle?

    deinit {
        // Remove auth listener
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
        listener?.remove()
        statsListener?.remove()
    }
    
    init() {
        setupAuthListener()
    }
//    init() {
//        fetchUserData()
//        setupRealtimeListener()
//        fetchTemplatesRealtime()
//        setupStatsListener()
//    }
    
    func saveExercises(exercises: [Exercise], completion: @escaping (Error?) -> Void) {
        guard let userID = userID else {
            completion(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"]))
            return
        }
        
        let batch = db.batch()
        var prCountIncrement = 0
        
        for exercise in exercises {
            let exerciseRef = db.collection("users")
                .document(userID)
                .collection("exercises")
                .document(exercise.name.lowercased().replacingOccurrences(of: " ", with: "_"))
            
            let completedSets = exercise.sets.filter { $0.isCompleted }
            
            let exerciseData: [String: Any] = [
                "name": exercise.name.capitalized,
                "muscleGroups": [],
                "barType": "",
                "createdBy": userID,
                "createdAt": Timestamp(date: Date()),
                "lastSetDate": Timestamp(date: Date()),
                "setCount": FieldValue.increment(Int64(completedSets.count))
            ]
            
            batch.setData(exerciseData, forDocument: exerciseRef, merge: true)
            
            // Add completed sets and check for PRs
            for set in completedSets {
                let newSetRef = exerciseRef.collection("sets").document()
                let setData: [String: Any] = [
                    "date": Timestamp(date: Date()),
                    "setNum": set.number,
                    "weight": set.weight,
                    "reps": set.reps
                ]
                batch.setData(setData, forDocument: newSetRef)
                
                if isPersonalRecord(exercise: exercise, set: set) {
                    prCountIncrement += 1
                }
            }
        }
        
        // Update PR count if needed
        if prCountIncrement > 0 {
            let statsRef = db.collection("userStats").document(userID)
            batch.updateData([
                "prCount": FieldValue.increment(Int64(prCountIncrement))
            ], forDocument: statsRef)
        }
        
        batch.commit { error in
            DispatchQueue.main.async {
                completion(error)
            }
        }
    }
    
//    func updateExercise(oldName: String, newName: String, muscleGroups: [String], barType: String, completion: @escaping (Bool) -> Void) {
//        guard let userID = userID else {
//            completion(false)
//            return
//        }
//        
//        let db = Firestore.firestore()
//        let oldRef = db.collection("users").document(userID)
//            .collection("exercises")
//            .document(oldName.lowercased().replacingOccurrences(of: " ", with: "_"))
//        
//        // If name changed, we need to create a new document and delete the old one
//        if oldName.lowercased() != newName.lowercased() {
//            let newRef = db.collection("users").document(userID)
//                .collection("exercises")
//                .document(newName.lowercased().replacingOccurrences(of: " ", with: "_"))
//            
//            // Get all sets from old document
//            oldRef.collection("sets").getDocuments { snapshot, error in
//                if let error = error {
//                    print("Error fetching sets: \(error.localizedDescription)")
//                    completion(false)
//                    return
//                }
//                
//                let batch = db.batch()
//                
//                // Copy sets to new document
//                if let documents = snapshot?.documents {
//                    for document in documents {
//                        let newSetRef = newRef.collection("sets").document(document.documentID)
//                        batch.setData(document.data(), forDocument: newSetRef)
//                    }
//                }
//                
//                // Create new exercise document
//                let exerciseData: [String: Any] = [
//                    "name": newName,
//                    "muscleGroups": muscleGroups,
//                    "barType": barType,
//                    "lastEdited": FieldValue.serverTimestamp()
//                ]
//                batch.setData(exerciseData, forDocument: newRef)
//                
//                // Delete old exercise document
//                batch.deleteDocument(oldRef)
//                
//                batch.commit { error in
//                    if let error = error {
//                        print("Error updating exercise: \(error.localizedDescription)")
//                        completion(false)
//                    } else {
//                        // Update local data
//                        DispatchQueue.main.async {
//                            if let index = self.userExercises.firstIndex(where: { $0.name == oldName }) {
//                                self.userExercises[index].name = newName
//                                self.userExercises[index].muscleGroups = muscleGroups
//                                self.userExercises[index].barType = barType
//                            }
//                        }
//                        completion(true)
//                    }
//                }
//            }
//        } else {
//            // Just update the existing document
//            let exerciseData: [String: Any] = [
//                "muscleGroups": muscleGroups,
//                "barType": barType,
//                "lastEdited": FieldValue.serverTimestamp()
//            ]
//            
//            oldRef.updateData(exerciseData) { error in
//                if let error = error {
//                    print("Error updating exercise: \(error.localizedDescription)")
//                    completion(false)
//                } else {
//                    // Update local data
//                    DispatchQueue.main.async {
//                        if let index = self.userExercises.firstIndex(where: { $0.name == oldName }) {
//                            self.userExercises[index].muscleGroups = muscleGroups
//                            self.userExercises[index].barType = barType
//                        }
//                    }
//                    completion(true)
//                }
//            }
//        }
//    }

    func saveWorkout(title: String, exercises: [Exercise], completion: @escaping (Error?) -> Void) {
        guard let userID = userID else {
            completion(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"]))
            return
        }

        var exerciseDetails: [[String: Any]] = []
        var prCountIncrement = 0
        
        for exercise in exercises {
            guard !exercise.sets.isEmpty else { continue }
            
            if let maxRepSet = exercise.sets.max(by: { $0.reps < $1.reps }) {
                let exerciseData: [String: Any] = [
                    "name": exercise.name,
                    "sets": exercise.sets.count,
                    "reps": maxRepSet.reps,
                    "weight": maxRepSet.weight
                ]
                exerciseDetails.append(exerciseData)
                
                // Check if this is a PR (personal record)
                if isPersonalRecord(exercise: exercise, set: maxRepSet) {
                    prCountIncrement += 1
                }
            }
        }
        
        guard !exerciseDetails.isEmpty else {
            completion(NSError(domain: "", code: -2, userInfo: [NSLocalizedDescriptionKey: "No exercises contain sets"]))
            return
        }

        let workoutRef = db.collection("users").document(userID).collection("workouts").document()
        let batch = db.batch()
        
        // Add workout data
        let workoutData: [String: Any] = [
            "title": title,
            "timestamp": Timestamp(date: Date()),
            "exercises": exerciseDetails
        ]
        batch.setData(workoutData, forDocument: workoutRef)
        
        // Update stats
        let statsRef = db.collection("userStats").document(userID)
        var statsData: [String: Any] = [
            "workoutCount": FieldValue.increment(Int64(1)),
            "lastWorkoutDate": Timestamp(date: Date())
        ]
        
        if prCountIncrement > 0 {
            statsData["prCount"] = FieldValue.increment(Int64(prCountIncrement))
        }
        
        batch.setData(statsData, forDocument: statsRef, merge: true)
        
        batch.commit { error in
            DispatchQueue.main.async {
                completion(error)
            }
        }
    }

    private func isPersonalRecord(exercise: Exercise, set: ExerciseSet) -> Bool {
        // Get all previous sets for this exercise
        let previousSets = userExercises
            .first { $0.name == exercise.name }?
            .sets ?? []
        
        // Check if this set is heavier or has more reps than any previous set
        return !previousSets.contains { previousSet in
            (previousSet.weight > set.weight) ||
            (previousSet.weight == set.weight && previousSet.reps > set.reps)
        }
    }

    func saveWorkoutAsTemplate(title: String, exercises: [Exercise], completion: @escaping (Bool, Error?) -> Void) {
        guard let userID = userID else {
            completion(false, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"]))
            return
        }

        let templatesRef = db.collection("users").document(userID).collection("templates")
        
        // Check for existing template
        templatesRef.whereField("title", isEqualTo: title).getDocuments { snapshot, error in
            if let error = error {
                completion(false, error)
                return
            }
            
            var exercisesData: [[String: Any]] = []
            for exercise in exercises {
                var setsData: [[String: Any]] = []
                for set in exercise.sets {
                    setsData.append([
                        "setNum": set.number,
                        "weight": set.weight,
                        "reps": set.reps
                    ])
                }
                
                exercisesData.append([
                    "name": exercise.name,
                    "lastSetCompleted": Timestamp(date: Date()),
                    "sets": setsData
                ])
            }
            
            let workoutData: [String: Any] = [
                "title": title,
                "exercises": exercisesData,
                "lastEdited": Timestamp(date: Date())
            ]
            
            if let existingDoc = snapshot?.documents.first {
                // Update existing template
                templatesRef.document(existingDoc.documentID).setData(workoutData, merge: true) { error in
                    completion(true, error)
                }
            } else {
                // Create new template
                templatesRef.document().setData(workoutData) { error in
                    completion(false, error)
                }
            }
        }
    }

    func loadWorkoutTemplate(title: String, completion: @escaping ([Exercise]?, Error?) -> Void) {
        guard let userID = userID else {
            completion(nil, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"]))
            return
        }
        
        let workoutRef = db.collection("users").document(userID)
            .collection("templates")
            .document(title.replacingOccurrences(of: "_", with: " ").capitalized(with: .autoupdatingCurrent))
        
        workoutRef.getDocument { document, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let document = document, document.exists,
                  let data = document.data(),
                  let exercisesData = data["exercises"] as? [[String: Any]] else {
                completion(nil, nil)
                return
            }
            
            let exercises = exercisesData.compactMap { exerciseDict -> Exercise? in
                guard let name = exerciseDict["name"] as? String,
                      let setsData = exerciseDict["sets"] as? [[String: Any]] else { return nil }
                
                let sets = setsData.compactMap { setDict -> ExerciseSet? in
                    guard let setNum = setDict["setNum"] as? Int,
                          let weight = setDict["weight"] as? Double,
                          let reps = setDict["reps"] as? Int else { return nil }
                    return ExerciseSet(number: setNum, weight: weight, reps: reps)
                }
                
                return Exercise(name: name, sets: sets)
            }
            
            completion(exercises, nil)
        }
    }
    
    func fetchTemplatesRealtime() {
        guard let userID = userID, !userID.isEmpty else {
            print("❌ Error: User ID is nil or empty")
            return
        }
        
        isLoading = true

        listener = db.collection("users").document(userID).collection("templates")
            .order(by: "lastEdited", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false

                if let error = error {
                    print("❌ Error fetching templates: \(error.localizedDescription)")
                    self.templates = []
                    return
                }

                self.templates = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    let name = data["title"] as? String ?? ""
                    let exercises = (data["exercises"] as? [[String: Any]])?.compactMap { exerciseDict -> Exercise? in
                        guard let name = exerciseDict["name"] as? String else { return nil }
                        let sets = (exerciseDict["sets"] as? [[String: Any]])?.compactMap { setDict -> ExerciseSet? in
                            let setNum = setDict["setNum"] as? Int ?? 0
                            let weight = setDict["weight"] as? Double ?? 0.0
                            let reps = setDict["reps"] as? Int ?? 0
                            return ExerciseSet(number: setNum, weight: weight, reps: reps)
                        } ?? []
                        
                        return Exercise(name: name, sets: sets)
                    } ?? []
                    return WorkoutTemplate(id: doc.documentID, name: name, exercises: exercises)
                } ?? []
            }
    }
    
    // Delete a template from Firestore
    func deleteTemplate(templateID: String) {
        guard let userID = userID, !userID.isEmpty else {
            print("❌ Error: User ID is nil or empty")
            return
        }
        db.collection("users").document(userID).collection("templates").document(templateID)
            .delete { [weak self] error in
                if let error = error {
                    print("❌ Error deleting template: \(error.localizedDescription)")
                } else {
                    DispatchQueue.main.async {
                        self?.templates.removeAll { $0.id == templateID }
                    }
                }
            }
    }
    
    
    
    
    // Above: workoutView functions
    //-----------------------------------------------------------------
    //
    //-----------------------------------------------------------------
    // Below: profileView functions
    
    
    private func setupStatsListener() {
        guard let userID = userID else { return }
        
        statsListener = db.collection("userStats").document(userID)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Stats listener error: \(error.localizedDescription)")
                    return
                }
                
                guard let data = snapshot?.data() else {
                    print("No stats data received")
                    return
                }
                
                self.updateStats(from: data)
            }
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
    }
    
    private func calculateProfileCompletion() {
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
        let newLastWorkoutDate = (data["lastWorkoutDate"] as? Timestamp)?.dateValue()
        
        DispatchQueue.main.async {
            self.workoutCount = newWorkoutCount
            self.prCount = newPrCount
            self.dayStreak = newDayStreak
            self.lastWorkoutDate = newLastWorkoutDate
        }
        
        // Recalculate streak if needed
        if let lastWorkoutDate = newLastWorkoutDate {
            self.calculateStreak(lastWorkoutDate: lastWorkoutDate)
        }
    }

    private func calculateStreak(lastWorkoutDate: Date) {
        let calendar = Calendar.current
        let today = Date()
        
        // Reset streak if last workout was more than 2 days ago
        if let daysSinceLastWorkout = calendar.dateComponents([.day], from: lastWorkoutDate, to: today).day, daysSinceLastWorkout > 1 {
            if self.dayStreak > 0 {
                resetStreak()
            }
            return
        }
        
        // Increment streak if last workout was yesterday
        if calendar.isDateInYesterday(lastWorkoutDate) {
            incrementStreak()
        }
    }

    private func incrementStreak() {
        guard let userID = userID else { return }
        
        let statsRef = db.collection("userStats").document(userID)
        statsRef.setData([
            "dayStreak": FieldValue.increment(Int64(1))
        ], merge: true)
    }

    private func resetStreak() {
        guard let userID = userID else { return }
        
        let statsRef = db.collection("userStats").document(userID)
        statsRef.setData([
            "dayStreak": 0
        ], merge: true)
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
    
    
    
    private func setupAuthListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            guard let self = self else { return }
            
            if user != nil {
                // User signed in or already signed in
                self.initializeForCurrentUser()
            } else {
                // User signed out
                self.resetUserData()
            }
        }
    }
    
    private func initializeForCurrentUser() {
        resetUserData() // Clear any previous user's data first
        fetchUserData()
        setupRealtimeListener()
        fetchTemplatesRealtime()
        setupStatsListener()
        fetchExercises()
    }
    
    // MARK: - Reset
    func resetUserData() {
            // Cancel any active listeners
            listener?.remove()
            statsListener?.remove()
            
            // Reset all published properties
            DispatchQueue.main.async {
                self.templates = []
                self.isLoading = false
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
                self.userExercises = []
                self.lastWorkoutDate = nil
            }
        }
}
