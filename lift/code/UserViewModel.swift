import FirebaseAuth
import FirebaseFirestore
import SwiftUI

class UserViewModel: ObservableObject {
    
    // Template Info
    @Published var templates: [WorkoutTemplate] = []
    @Published var groups: [WorkoutGroup] = []
    @Published var isLoading = false
    @Published var isLoadingGroups: Bool = false
    @Published var isLoadingTemplates: Bool = false
    
    // Basic Info
    @Published var userId: String = ""
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var userName: String = ""
    @Published var userEmail: String = ""
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
    @Published var profileCompletion: Double = 0
    
    @Published var userExercises: [Exercise] = []
    @Published var customFoods: [FoodItem] = []
    
    @Published var workedOutDates: [Date] = []
    
    
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
//        fetchUserData()
//        setupRealtimeListener()
//        fetchTemplatesRealtime()
//        fetchWorkedOutDates()
//        fetchUserGroups()
//        fetchExercises()
//        startListeningForCustomFoods()
        batchFetchInitialData { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                print("Initial load error: \(error.localizedDescription)")
                return
            }
            // Update UI state
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
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


// Initialize all important variables
extension UserViewModel {
    func batchFetchInitialData(completion: @escaping (Error?) -> Void) {
        guard let userID = userID else {
            completion(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"]))
            return
        }
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.isLoadingGroups = true
            self.isLoadingTemplates = true
        }
        
        // 1. Create references to all documents/collections needed
        let userRef = db.collection("users").document(userID)
        let templatesRef = userRef.collection("templates").limit(to: 20)
        let workoutsRef = userRef.collection("workouts").limit(to: 30)
        let exercisesRef = userRef.collection("exercises").limit(to: 100)
//        let customFoodsRef = userRef.collection("customFoods").limit(to: 50)
//        let userGroupsRef = userRef.collection("groups").limit(to: 10)
        
        // 2. Create batch get request
        let dispatchGroup = DispatchGroup()
        var userData: [String: Any]?
        var templates: [WorkoutTemplate] = []
        var workedOutDates: [Date] = []
        var exercises: [Exercise] = []
//        var customFoods: [FoodItem] = []
//        var groupIDs: [(id: String, role: String)] = []
        var lastError: Error?
        
        // 3. Fetch user document and critical collections
        dispatchGroup.enter()
        userRef.getDocument { snapshot, error in
            if let error = error {
                lastError = error
            } else {
                userData = snapshot?.data()
            }
            dispatchGroup.leave()
        }
        
        // 4. Fetch templates
        dispatchGroup.enter()
        templatesRef.getDocuments { snapshot, error in
            if let error = error {
                lastError = error
            } else {
                templates = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    return WorkoutTemplate(
                        id: doc.documentID,
                        name: data["title"] as? String ?? "",
                        exercises: data["exercises"] as? [Exercise] ?? []
                    )
                } ?? []
            }
            dispatchGroup.leave()
        }
        
        // 5. Fetch workout dates
        dispatchGroup.enter()
        workoutsRef.order(by: "timestamp", descending: true).limit(to: 7).getDocuments { snapshot, error in
            if let error = error {
                lastError = error
            } else {
                workedOutDates = snapshot?.documents.compactMap { doc in
                    (doc.data()["timestamp"] as? Timestamp)?.dateValue()
                } ?? []
            }
            dispatchGroup.leave()
        }
        
        // 6. Fetch exercises
        dispatchGroup.enter()
        exercisesRef.getDocuments { snapshot, error in
            if let error = error {
                lastError = error
            } else {
                exercises = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    return Exercise(
                        name: data["name"] as? String ?? "",
                        sets: []
                    )
                } ?? []
            }
            dispatchGroup.leave()
        }
        
        // 7. Fetch custom foods
//        dispatchGroup.enter()
//        customFoodsRef.order(by: "name").limit(to: 20).getDocuments { snapshot, error in
//            if let error = error {
//                lastError = error
//            } else {
//                customFoods = snapshot?.documents.compactMap { doc in
//                    try? doc.data(as: FoodItem.self)
//                } ?? []
//            }
//            dispatchGroup.leave()
//        }
        
        // 8. Fetch user's group IDs and group deatils
        dispatchGroup.enter()
        fetchUserGroups()
        dispatchGroup.leave()
        
        
        // 9. Process all results when complete
        dispatchGroup.notify(queue: .main) {
            self.isLoading = false
            self.isLoadingGroups = false
            self.isLoadingTemplates = false
            
            if let lastError = lastError {
                completion(lastError)
                return
            }
            
            // Update all view model properties
            if let userData = userData {
                self.updateBasicInfo(from: userData)
                self.calculateProfileCompletion()
            }
            
            self.templates = templates
            self.workedOutDates = workedOutDates
            self.userExercises = exercises
//            self.customFoods = self.customFoods
            
            // Now setup realtime listeners for updates
            self.setupRealtimeListener()
            self.fetchTemplatesRealtime()
            self.startListeningForCustomFoods()
            
            completion(nil)
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
        DispatchQueue.main.async {
            self.firstName = data["firstName"] as? String ?? ""
            self.lastName = data["lastName"] as? String ?? ""
            self.userName = "\(self.firstName) \(self.lastName)"
            self.userEmail = data["email"] as? String ?? ""
            
            // Handle height - both Int and String cases
            if let heightNumber = data["height"] as? Int {
                self.height = String(heightNumber)
            } else if let heightString = data["height"] as? String {
                self.height = heightString
            } else {
                self.height = "0"
            }
            
            if let createdAt = data["createdAt"] as? Timestamp {
                self.memberSince = createdAt.dateValue()
            }
            
            // Handle weight - both Double and String cases
            if let weightNumber = data["weight"] as? Double {
                self.weight = String(weightNumber)
            } else if let weightString = data["weight"] as? String {
                self.weight = weightString
            }
            
            self.gender = data["gender"] as? String ?? self.gender
            self.activityLevel = data["activityLevel"] as? String ?? self.activityLevel
            self.goal = data["goal"] as? String ?? self.goal
            
            if let dobTimestamp = data["birthDate"] as? Timestamp {
                self.dob = dobTimestamp.dateValue()
            }
            
            self.profileCompletion = (data["profileCompleted"] as? Bool ?? false) ? 1.0 : 0.0
        }
    }
    
    func calculateProfileCompletion() {
        let requiredFields: [Any?] = [weight, height, dob, gender, activityLevel, goal]
        let totalFields = requiredFields.count
        var completedFields = 0
        
        for field in requiredFields {
            if let stringField = field as? String {
                if !stringField.isEmpty && stringField != "Loading..." {
                    completedFields += 1
                }
            } else if let dateField = field as? Date?, dateField != nil {
                completedFields += 1
            }
        }
        
        profileCompletion = Double(completedFields) / Double(totalFields)
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
                
                // Make sure all properties are being updated
                self.updateBasicInfo(from: data)
                self.calculateProfileCompletion()
            }
    }
    
    // Update the user's stats - workoutCount, prCount, streak
    private func updateStats(from data: [String: Any]) {
        let newProfileURL = data["profileURL"] as? String ?? ""

        DispatchQueue.main.async {
            self.userName = data["name"] as? String ?? self.userName
//            self.firstName = data["firstName"] as? String ?? "-"
//            self.lastName = data["lastName"] as? String ?? "-"
            self.userName = "\(self.firstName) \(self.lastName)"
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
    func updateUserProfile(
        firstName: String,
        lastName: String,
        emailInput: String,
        dobInput: Date,
        genderInput: String,
        weightInput: String,
        heightInput: String,
        activityLevelInput: String,
        goalInput: String,
        profileImageBase64: String?
    ) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let userData: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "name": "\(firstName) \(lastName)", // Store combined name if needed
            "email": emailInput,
            "dob": Timestamp(date: dobInput),
            "gender": genderInput,
            "weight": weightInput,
            "height": heightInput,
            "activityLevel": activityLevelInput,
            "goal": goalInput,
            "profileURL": profileImageBase64 ?? ""
        ]
        
        // Update local properties
        DispatchQueue.main.async {
            self.firstName = firstName
            self.lastName = lastName
            self.userName = "\(firstName) \(lastName)"
            self.userEmail = emailInput
            self.weight = weightInput
            self.height = heightInput
            self.dob = dobInput
            self.gender = genderInput
            self.activityLevel = activityLevelInput
            self.goal = goalInput
            self.profileURL = profileImageBase64 ?? ""
        }
        
        db.collection("users").document(userID).setData(userData, merge: true) { error in
            if let error = error {
                print("❌ Profile update failed: \(error.localizedDescription)")
            } else {
                print("✅ Profile updated successfully")
            }
        }
    }
    
    func fetchWorkedOutDates() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(userID).collection("workouts")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching workouts: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else { return }
                                
                let formatter = ISO8601DateFormatter()
                
                DispatchQueue.main.async {
                    self.workedOutDates = documents.compactMap { doc in
                        if let timestamp = doc.data()["timestamp"] as? Timestamp {
                            return timestamp.dateValue()
                        }
                        if let isoString = doc.data()["timestamp"] as? String {
                            return formatter.date(from: isoString)
                        }
                        return nil
                    }
                    print(self.workedOutDates)
                }
            }
    }
    
    
    func saveUserData(
        userId: String? = nil,
        userName: String? = nil,
        userEmail: String? = nil,
        weight: String? = nil,
        height: String? = nil,
        dob: Date? = nil,
        gender: String? = nil,
        activityLevel: String? = nil,
        goal: String? = nil,
        profileURL: String? = nil,
        completion: @escaping (Bool, Error?) -> Void
    ) {
        // First update the local published properties with any new values
        if let userId = userId { self.userId = userId }
        if let userName = userName { self.userName = userName }
        if let userEmail = userEmail { self.userEmail = userEmail }
        if let weight = weight { self.weight = weight }
        if let height = height { self.height = height }
        if let dob = dob { self.dob = dob }
        if let gender = gender { self.gender = gender }
        if let activityLevel = activityLevel { self.activityLevel = activityLevel }
        if let goal = goal { self.goal = goal }
        if let profileURL = profileURL { self.profileURL = profileURL }
        
        // Get the actual user ID to use (either passed in or from the current property)
        let actualUserId = userId ?? self.userId
        
        guard !actualUserId.isEmpty else {
            completion(false, NSError(domain: "UserViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user ID available"]))
            return
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(actualUserId)
        
        // Prepare the data dictionary with non-nil values
        var data: [String: Any] = [:]
        if userName != nil { data["userName"] = self.userName }
        if userEmail != nil { data["userEmail"] = self.userEmail }
        if weight != nil { data["weight"] = self.weight }
        if height != nil { data["height"] = self.height }
        if dob != nil { data["dob"] = Timestamp(date: self.dob ?? Date()) }
        if gender != nil { data["gender"] = self.gender }
        if activityLevel != nil { data["activityLevel"] = self.activityLevel }
        if goal != nil { data["goal"] = self.goal }
        if profileURL != nil { data["profileURL"] = self.profileURL }
        
        // Add last updated timestamp
        data["lastUpdated"] = Timestamp(date: Date())
        
        userRef.updateData(data) { error in
            if let error = error {
                print("Error updating user data: \(error.localizedDescription)")
                completion(false, error)
            } else {
                print("User data updated successfully")
                completion(true, nil)
            }
        }
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
            
            print("Saving exercise: \(exercise.name)")
            print("Bar type: \(exercise.barType)")
            print("Muscle groups: \(exercise.muscleGroups)")
            
            // Create base update data with mandatory fields
            var exerciseData: [String: Any] = [
                "name": exercise.name.capitalized,
                "lastSetDate": Timestamp(date: Date()),
                "setCount": FieldValue.increment(Int64(completedSets.count))
            ]
            
            // Only include optional fields if they have values
            if exercise.barType != "Other" {
                exerciseData["barType"] = exercise.barType
            }
            if !exercise.muscleGroups.isEmpty {
                exerciseData["muscleGroups"] = exercise.barType
            }
            
            // Only include createdBy/createdAt for new documents
            if exercise.sets.isEmpty {
                exerciseData["createdBy"] = userID
                exerciseData["createdAt"] = Timestamp(date: Date())
            }
            
            // Use updateData instead of setData to only modify specified fields
            batch.updateData(exerciseData, forDocument: exerciseRef)
            
            // Add completed sets
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
            
            let db = Firestore.firestore()
            let batch = db.batch()
            
            // 1. Save workout under user
            let workoutRef = db.collection("users").document(userID).collection("workouts").document()
            let workoutData: [String: Any] = [
                "title": title,
                "timestamp": Timestamp(date: Date()),
                "exercises": exerciseDetails
            ]
            batch.setData(workoutData, forDocument: workoutRef)
            
            // 2. Update user stats
            let statsRef = db.collection("users").document(userID)
            let statsData: [String: Any] = [
                "lastWorkoutDate": Timestamp(date: Date())
            ]
            batch.setData(statsData, forDocument: statsRef, merge: true)
            
            // 3. Save to each group’s workout history
            for group in groups {
                let groupWorkoutRef = db.collection("groups").document(group.id).collection("workouts").document(workoutRef.documentID)
                var groupWorkoutData = workoutData
                groupWorkoutData["userId"] = userID
                groupWorkoutData["groupId"] = group.id
                batch.setData(groupWorkoutData, forDocument: groupWorkoutRef)
            }
            
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
                            let code = data["code"] as? String ?? ""
                            let memberCount = data["memberCount"] as? Int ?? 1
                            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                            let everyoneCanEdit = data["everyoneCanEdit"] as? Bool ?? false
                            

                            var workoutGroup = WorkoutGroup(
                                id: groupId,
                                name: name,
                                description: description,
                                code: code,
                                memberCount: memberCount,
                                createdAt: createdAt,
                                isAdmin: userRole == "admin",
                                templates: [],
                                members: [],
                                everyoneCanEdit: everyoneCanEdit,
                                history: []
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

        groupMembersRef.getDocuments { snapshot, error in
            if let error = error {
                print("❌ Error fetching members for group \(groupId): \(error.localizedDescription)")
                completion([])
                return
            }

            let memberDocs = snapshot?.documents ?? []

            let members: [Member] = memberDocs.compactMap { doc in
                let data = doc.data()
                
                let id = data["userId"] as? String ?? doc.documentID
                let name = data["name"] as? String ?? "Unknown"
                let role = data["role"] as? String ?? "member"
                let profileURLString = data["profileURL"] as? String ?? ""
                let profileURL = URL(string: profileURLString)

                return Member(id: id, name: name, profileURL: profileURL, role: role)
            }

            completion(members)
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
        // Check if all required profile fields are present
        guard let dob = dob,
              let age = calculateAge(from: dob),
              !weight.isEmpty,
              !height.isEmpty,
              !gender.isEmpty,
              !activityLevel.isEmpty,
              !goal.isEmpty else {
            // Default values if any field is missing
            goalCalories = 2000
            goalProtein = 150
            goalCarbs = 200
            goalFat = 67
            return
        }
        
        // Convert inputs to proper units
        let weightKg = (Double(weight) ?? 70) * 0.45359237 // lbs to kg
        let heightCm = (Double(height) ?? 170) * 2.54 // inches to cm
        
        // Calculate BMR (Mifflin-St Jeor Equation - more accurate than Harris-Benedict)
        let bmr: Double
        if gender.lowercased() == "male" {
            bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * Double(age)) + 5
        } else {
            bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * Double(age)) - 161
        }
        
        // Activity multiplier
        let activityMultiplier: Double = {
            switch activityLevel.lowercased() {
            case "sedentary": return 1.2
            case "light exercise", "lightlyactive": return 1.375
            case "moderate exercise", "moderatelyactive": return 1.55
            case "heavy exercise", "veryactive": return 1.725
            case "athlete", "extraactive": return 1.9
            default: return 1.2
            }
        }()
        
        // Calculate TDEE
        var tdee = bmr * activityMultiplier
        
        // Adjust for goal
        switch goal.lowercased() {
        case "lose", "weight loss": tdee -= 300 // 500cal deficit for ~1lb/week loss
        case "maintain", "maintenance": break
        case "gain", "bulk": tdee += 300 // 500cal surplus for ~1lb/week gain
        default: break
        }
        
        // Macronutrient distribution (40% carbs, 30% protein, 30% fat - balanced approach)
        goalCalories = Int(tdee.rounded())
        goalProtein = Int(((tdee * 0.3) / 4).rounded()) // 1g protein = 4 calories
        goalFat = Int(((tdee * 0.3) / 9).rounded())     // 1g fat = 9 calories
        goalCarbs = Int(((tdee * 0.4) / 4).rounded())   // 1g carb = 4 calories
        
        // Sugar is part of carbs, no need for separate calculation
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


extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
