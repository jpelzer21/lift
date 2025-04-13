import FirebaseAuth
import FirebaseFirestore
import SwiftUI

class UserViewModel: ObservableObject {
    
    // Template Info
    @Published var templates: [WorkoutTemplate] = []
    @Published var groups: [WorkoutGroup] = []
    @Published var isLoading = false
    @Published var isLoadingGroups: Bool = false
    
    // Basic Info
    @Published var userName: String = "Loading..."
    @Published var userEmail: String = "Loading..."
    @Published var weight: String = "Loading..."
    @Published var height: String = "Loading..."
    @Published var dob: Date?
    @Published var gender: String = "Loading..."
    @Published var activityLevel: String = "Loading..."
    @Published var goal: String = "Loading..."
    @Published var profileURL: String?
    
    // Calulated Nutrition Info
    @Published var goalCalories: Int = 0
    @Published var goalCarbs: Int = 0
    @Published var goalProtein: Int = 0
    @Published var goalFat: Int = 0
    @Published var goalSugars: Int = 0
    
    @Published var memberSince: Date = Date()
    
    // Profile Completion
    @Published var profileCompletion: Double = 0
    
    @Published var userExercises: [Exercise] = []
    @Published var customFoods: [FoodItem] = []
    
    
    static let shared = UserViewModel()
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
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
    }
    
    init() {
        setupAuthListener()
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
    
    // Call all of the function needed at start of runtime
    private func initializeForCurrentUser() {
        resetUserData()
        fetchUserData()
        setupRealtimeListener()
        fetchTemplatesRealtime()
        fetchUserGroups()
        fetchExercises()
        startListeningForCustomFoods()
    }
    
    // Reset User Data
    func resetUserData() {
        // Cancel any active listeners
        listener?.remove()
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
            self.memberSince = Date()
            self.profileCompletion = 0
            self.userExercises = []
        }
    }
}



// MARK: User Information Manegement
extension UserViewModel {
    
    // Getting the data about the user - name, age, gender, etc
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
    
    // Update the variables that hold the user's information
    private func updateBasicInfo(from data: [String: Any]) {
        self.userName = data["name"] as? String ?? "No Name"
        self.userEmail = data["email"] as? String ?? "No Email"
        self.weight = data["weight"] as? String ?? "0"
        self.height = data["height"] as? String ?? "0"
        self.gender = data["gender"] as? String ?? "Not Set"
        self.activityLevel = data["activityLevel"] as? String ?? "Not Set"
        self.goal = data["goal"] as? String ?? "Not Set"
        self.profileURL = data["profileURL"] as? String ?? ""
//        self.groups = data["groups"] as? [WorkoutGroup] ?? []
        
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
    
    private func calculateProfileCompletion() {
    }
    
    // Called on init()
    // Set up listener on user information - name, age, gender, etc
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
                self.updateStats(from: data)
            }
    }
    
    // Update the user's stats - workoutCount, prCount, streak
    private func updateStats(from data: [String: Any]) {
        let newProfileURL = data["profileURL"] as? String ?? ""

        DispatchQueue.main.async {
            self.userName = data["name"] as? String ?? self.userName
            self.userEmail = data["email"] as? String ?? self.userEmail
            self.memberSince = (data["createdAt"] as? Timestamp)?.dateValue() ?? self.memberSince
            self.dob = (data["dob"] as? Timestamp)?.dateValue() ?? self.dob
            self.gender = data["gender"] as? String ?? self.gender
            self.weight = data["weight"] as? String ?? self.weight
            self.height = data["height"] as? String ?? self.height
            self.activityLevel = data["activityLevel"] as? String ?? self.activityLevel
            self.goal = data["goal"] as? String ?? self.goal

            // 👇 Only overwrite profileURL if it changed
            if self.profileURL != newProfileURL && !newProfileURL.isEmpty {
                self.profileURL = newProfileURL
            }
        }
    }
    
    // Update Methods
    func updateUserProfile(nameInput: String, emailInput: String, dobInput: Date, genderInput: String,
                           weightInput: String, heightInput: String, activityLevelInput: String, goalInput: String, profileImageBase64: String?) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let userData: [String: Any] = [
            "name": nameInput,
            "email": emailInput,
            "dob": Timestamp(date: dobInput),
            "gender": genderInput,
            "weight": weightInput,
            "height": heightInput,
            "activityLevel": activityLevelInput,
            "goal": goalInput,
            "profileURL" : profileImageBase64 ?? ""
        ]
        
        userName = nameInput
        userEmail = emailInput
        weight = weightInput
        height = heightInput
        dob = dobInput
        gender = genderInput
        activityLevel = activityLevelInput
        goal = goalInput
        profileURL = profileImageBase64 ?? ""
        
        
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
        
        let statsRef = db.collection("users").document(userID)
        statsRef.setData([
            "workoutCount": FieldValue.increment(Int64(1)),
            "lastWorkoutDate": Timestamp(date: Date())
        ], merge: true)
    }
    
}






// MARK: Workout Information Manegement
extension UserViewModel {
    // Fetch templates from database
    func fetchTemplatesRealtime() {
        guard let userID = userID, !userID.isEmpty else {
            print("❌ Error: User ID is nil or empty")
            return
        }
        isLoading = true
        listener?.remove()
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
    
    // Called on init()
    // Fetch Exercises from Database
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
    
    
    // Save Exercises - called when workout is finished
    func saveExercises(exercises: [Exercise], completion: @escaping (Error?) -> Void) {
        guard let userID = userID else {
            completion(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"]))
            return
        }
        let batch = db.batch()
        for exercise in exercises {
            let exerciseRef = db.collection("users")
                .document(userID)
                .collection("exercises")
                .document(exercise.name.lowercased().replacingOccurrences(of: " ", with: "_"))
            let completedSets = exercise.sets.filter { $0.isCompleted }
            let exerciseData: [String: Any] = [
                "name": exercise.name.capitalized,
                "muscleGroups": exercise.muscleGroups,
                "barType": exercise.barType,
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
            }
        }
        batch.commit { error in
            DispatchQueue.main.async {
                completion(error)
            }
        }
    }
    
    // Save the Workout in Firestore
    func saveWorkout(title: String, exercises: [Exercise], completion: @escaping (Error?) -> Void) {
        guard let userID = userID else {
            completion(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"]))
            return
        }
        var exerciseDetails: [[String: Any]] = []
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
            }
        }
        guard !exerciseDetails.isEmpty else {
            completion(NSError(domain: "", code: -2, userInfo: [NSLocalizedDescriptionKey: "No exercises contain sets"]))
            return
        }
        let workoutRef = db.collection("users").document(userID).collection("workouts").document()
        let batch = db.batch()
        let workoutData: [String: Any] = [
            "title": title,
            "timestamp": Timestamp(date: Date()),
            "exercises": exerciseDetails
        ]
        batch.setData(workoutData, forDocument: workoutRef)
        let statsRef = db.collection("users").document(userID)
        let statsData: [String: Any] = [
            "lastWorkoutDate": Timestamp(date: Date())
        ]
        batch.setData(statsData, forDocument: statsRef, merge: true)
        
        batch.commit { error in
            DispatchQueue.main.async {
                completion(error)
            }
        }
    }
    
    // called on workout finish
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
    
//    func updateTemplate(title: String, exercises: [Exercise], completion: @escaping (Bool, Error?) -> Void) {
//        guard let userID = userID else {
//            completion(false, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"]))
//            return
//        }
//        
//        let templatesRef = db.collection("users").document(userID).collection("templates")
//        
//        templatesRef.whereField("title", isEqualTo: title).getDocuments { snapshot, error in
//            if let error = error {
//                completion(false, error)
//                return
//            }
//            
//            guard let doc = snapshot?.documents.first else {
//                completion(false, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Template not found"]))
//                return
//            }
//
//            var exercisesData: [[String: Any]] = []
//            for exercise in exercises {
//                var setsData: [[String: Any]] = []
//                for set in exercise.sets {
//                    setsData.append([
//                        "setNum": set.number,
//                        "weight": set.weight,
//                        "reps": set.reps
//                    ])
//                }
//                exercisesData.append([
//                    "name": exercise.name,
//                    "sets": setsData
//                ])
//            }
//
//            let updatedTemplate: [String: Any] = [
//                "title": title,
//                "exercises": exercisesData,
//                "lastEdited": Timestamp(date: Date())
//            ]
//            
//            templatesRef.document(doc.documentID).setData(updatedTemplate, merge: false) { error in
//                completion(error == nil, error)
//            }
//        }
//    }

    // called when WorkoutView appears
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
    
    func fetchUserGroups() {
        self.isLoadingGroups = true
        guard let userID = Auth.auth().currentUser?.uid else {
            print("User not authenticated")
            return
        }
        
        db.collection("users").document(userID).collection("groups")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error fetching user's groups: \(error.localizedDescription)")
                    return
                }
                
                let userGroups = snapshot?.documents.compactMap { doc -> (groupId: String, role: String)? in
                    let data = doc.data()
                    guard let groupId = data["groupId"] as? String else { return nil }
                    let role = data["role"] as? String ?? "member"
                    return (groupId, role)
                } ?? []
                
                guard !userGroups.isEmpty else {
                    self.groups = []
                    self.isLoadingGroups = false
                    return
                }
                
                let groupIds = userGroups.map { $0.groupId }
                
                self.db.collection("groups")
                    .whereField(FieldPath.documentID(), in: groupIds)
                    .getDocuments { [weak self] snapshot, error in
                        guard let self = self else { return }

                        if let error = error {
                            print("❌ Error fetching group details: \(error.localizedDescription)")
                            return
                        }

                        var fetchedGroups: [WorkoutGroup] = []

                        let dispatchGroup = DispatchGroup()

                        snapshot?.documents.forEach { doc in
                            let data = doc.data()
                            let groupId = doc.documentID

                            let userRole = userGroups.first { $0.groupId == groupId }?.role ?? "member"
                            let name = data["name"] as? String ?? "Unnamed Group"
                            let description = data["description"] as? String ?? ""
                            let memberCount = data["memberCount"] as? Int ?? 1
                            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()

                            var workoutGroup = WorkoutGroup(
                                id: groupId,
                                name: name,
                                description: description,
                                memberCount: memberCount,
                                createdAt: createdAt,
                                isAdmin: userRole == "admin",
                                templates: [],
                                members: []
                            )

                            dispatchGroup.enter()
                            self.fetchGroupTemplates(for: groupId) { templates in
                                workoutGroup.templates = templates
                                dispatchGroup.leave()
                            }

                            dispatchGroup.enter()
                            self.fetchGroupMembers(groupId: groupId) { members in
                                workoutGroup.members = members
                                fetchedGroups.append(workoutGroup)
                                dispatchGroup.leave()
                            }
                        }

                        dispatchGroup.notify(queue: .main) {
                            self.groups = fetchedGroups
                            self.isLoadingGroups = false
                        }
                    }
                
            }
    }
    
    func fetchGroupMembers(groupId: String, completion: @escaping ([Member]) -> Void) {
        let groupMembersRef = db.collection("groups").document(groupId).collection("members")
        
        groupMembersRef.getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                print("❌ Error fetching members for group \(groupId): \(error.localizedDescription)")
                completion([])
                return
            }

            let memberDocs = snapshot?.documents ?? []
            var members: [Member] = []
            let dispatchGroup = DispatchGroup()

            for doc in memberDocs {
                dispatchGroup.enter()
                
                let userId = doc.documentID
                let role = doc.data()["role"] as? String ?? "member" // Get role from group membership
                
                self.db.collection("users").document(userId).getDocument { userSnapshot, error in
                    defer { dispatchGroup.leave() }

                    guard let userData = userSnapshot?.data(), error == nil else {
                        print("⚠️ Error fetching user \(userId): \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }

                    let name = userData["name"] as? String ?? "Unknown"
                    let profileURLString = userData["profileURL"] as? String ?? ""
                    let profileURL = URL(string: profileURLString)

                    let member = Member(
                        id: userId,
                        name: name,
                        profileURL: profileURL,
                        role: role 
                    )

                    members.append(member)
                }
            }

            dispatchGroup.notify(queue: .main) {
                completion(members)
            }
        }
    }
    

    func fetchGroupTemplates(for groupId: String, completion: @escaping ([WorkoutTemplate]) -> Void) {
        db.collection("groups").document(groupId).collection("templates")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error fetching templates for group \(groupId): \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                let templates = snapshot?.documents.compactMap { doc -> WorkoutTemplate? in
                    let data = doc.data()
                    guard let name = data["name"] as? String,
                          let exercisesData = data["exercises"] as? [[String: Any]] else {
                        print("❌ Missing required fields in document \(doc.documentID)")
                        return nil
                    }
                    
                    let exercises = exercisesData.compactMap { exerciseDict -> Exercise? in
                        guard let exerciseName = exerciseDict["name"] as? String,
                              let setsData = exerciseDict["sets"] as? [[String: Any]] else {
                            print("❌ Missing exercise fields in document \(doc.documentID)")
                            return nil
                        }
                        
                        let sets = setsData.compactMap { setDict -> ExerciseSet? in
                            guard let reps = setDict["reps"] as? Int,
                                  let setNum = setDict["setNum"] as? Int,
                                  let weight = setDict["weight"] as? Double,
                                  let dateValue = setDict["date"] else {
                                return nil
                            }
                            
                            // Handle both Timestamp and direct date values
                            let date: Date
                            if let timestamp = dateValue as? Timestamp {  // Firestore's Timestamp type
                                date = timestamp.dateValue()
                            } else if let seconds = dateValue as? Double {  // Unix timestamp
                                date = Date(timeIntervalSince1970: seconds)
                            } else if let dateString = dateValue as? String {  // ISO string
                                date = ISO8601DateFormatter().date(from: dateString) ?? Date()
                            } else {
                                date = Date()  // Fallback
                            }
                            
                            return ExerciseSet(
                                id: UUID(),
                                number: setNum,
                                weight: weight,
                                reps: reps,
                                date: date,
                                isCompleted: false
                            )
                        }
                        
                        return Exercise(name: exerciseName, sets: sets)
                    }
                    
                    return WorkoutTemplate(
                        id: doc.documentID,
                        name: name,
                        exercises: exercises
                    )
                } ?? []
                
                completion(templates)
            }
    }
    
    func deleteGroup(_ group: WorkoutGroup) {
        let groupId = group.id
        let groupRef = db.collection("groups").document(groupId)
        let membersRef = groupRef.collection("members")
        
        // Step 1: Get all members in the group
        membersRef.getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                print("❌ Failed to fetch members: \(error.localizedDescription)")
                return
            }

            let memberDocs = snapshot?.documents ?? []
            let batch = self.db.batch()

            // Step 2: Remove the group reference from each user's path
            for doc in memberDocs {
                let userId = doc.documentID
                let userGroupRef = self.db.collection("users").document(userId).collection("groups").document(groupId)
                batch.deleteDocument(userGroupRef)

                // Optional: delete member record from group
                let groupMemberRef = membersRef.document(userId)
                batch.deleteDocument(groupMemberRef)
            }

            // Step 3: Optionally delete group templates
            self.db.collection("groups").document(groupId).collection("templates").getDocuments { templateSnap, err in
                if let err = err {
                    print("⚠️ Couldn't fetch templates: \(err.localizedDescription)")
                } else {
                    for templateDoc in templateSnap?.documents ?? [] {
                        let templateRef = groupRef.collection("templates").document(templateDoc.documentID)
                        batch.deleteDocument(templateRef)
                    }
                }

                // Step 4: Delete the group document itself
                batch.deleteDocument(groupRef)

                // Step 5: Commit the batch
                batch.commit { error in
                    if let error = error {
                        print("❌ Failed to delete group: \(error.localizedDescription)")
                    } else {
                        print("✅ Group \(groupId) and all references deleted.")
                        DispatchQueue.main.async {
                            self.groups.removeAll { $0.id == groupId }
                        }
                    }
                }
            }
        }
    }
    
}







// MARK: - Food Management
extension UserViewModel {
    func calculateCaloricIntake() {
        guard let dob = dob,
              let age = calculateAge(from: dob)  else {
            return
        }
        let weightKg = (Double(weight) ?? 160)*0.45359237
        let heightCm: Double = (Double(height) ?? 70)/0.3937
        let bmr: Double // basil metabolic rate
        if gender.lowercased() == "male" {
            bmr = 66 + (13.7 * weightKg) + (5 * heightCm) - (6.8 * Double(age))
        } else {
            bmr = 655 + (9.6 * weightKg) + (1.8 * heightCm) - (4.7 * Double(age))
        }
        let activityMultiplier: Double = {
            switch activityLevel.lowercased() {
                case "sedentary": return 1
                case "light exercise": return 1.1
                case "moderate exercise": return 1.2
                case "heavy exercise": return 1.3
                case "athlete": return 1.5
                default: return 1
            }
        }()
        var tdee = bmr * activityMultiplier
        switch goal.lowercased() {
            case "lose weight": tdee -= 300
            case "maintain weight": break
            case "gain muscle": tdee += 300
            default: break
        }
        // Update goal variables
        goalCalories = Int(tdee)
        goalProtein = Int((Double(weight) ?? 160)*1)
        goalCarbs = Int((tdee * 0.50) / 4)
        goalFat = Int((tdee * 0.50) / 9)
        goalSugars = Int((tdee * 0.10) / 4)  // 10% of carbs allocated to sugar
    }
    
    private func calculateAge(from birthDate: Date) -> Int? {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
        return ageComponents.year
    }
    
    func saveCustomFood(_ food: FoodItem, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userID = userID else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        do {
            try db.collection("users").document(userID)
                .collection("customFoods").document(food.id.uuidString)
                .setData(from: food) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
        } catch {
            completion(.failure(error))
        }
    }
    // Firestore Listener for Real-time Custom Food Updates
    func startListeningForCustomFoods() {
        guard let userID = userID else { return }
        
        db.collection("users").document(userID)
            .collection("customFoods")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching custom foods: \(error.localizedDescription)")
                    return
                }
                guard let documents = snapshot?.documents else {
                    self.customFoods = []
                    return
                }
                self.customFoods = documents.compactMap { doc -> FoodItem? in
                    try? doc.data(as: FoodItem.self)
                }
            }
    }
    
    // Manually fetches once (if needed)
    func fetchCustomFoods(completion: @escaping (Result<[FoodItem], Error>) -> Void) {
        guard let userID = userID else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        db.collection("users").document(userID)
            .collection("customFoods")
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                let foods = snapshot?.documents.compactMap { document -> FoodItem? in
                    try? document.data(as: FoodItem.self)
                } ?? []
                completion(.success(foods))
            }
    }
}








// TODO: Create EditExerciseView() for this function
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
