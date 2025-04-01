//
//  UserViewModel.swift
//  lift
//
//  Created by Josh Pelzer on 3/20/25.
//


import FirebaseAuth
import FirebaseFirestore
import SwiftUI

class UserViewModel: ObservableObject {
    @Published var userName: String = "Loading..."
    @Published var userEmail: String = "Loading..."
    @Published var weight: String = "Loading..."
    @Published var dob: Date?
    @Published var gender: String = "Loading..."
    @Published var activityLevel: String = "Loading..."
    @Published var goal: String = "Loading..."

    static let shared = UserViewModel() // Singleton instance

    private var hasFetched = false // Prevent duplicate fetches

    init() {
        fetchUserData()
    }
    
    func fetchUserData() {
        guard let user = Auth.auth().currentUser else { return }

        let db = Firestore.firestore()
        db.collection("users").document(user.uid).getDocument { snapshot, error in
            if let error = error {
                print("❌ Error fetching user data: \(error.localizedDescription)")
            } else if let data = snapshot?.data() {
                DispatchQueue.main.async {
                    self.userName = data["name"] as? String ?? "No Name"
                    self.userEmail = data["email"] as? String ?? "No Email"
                    
                    // ✅ Convert Firestore Timestamp to Date
                    if let dobTimestamp = data["dob"] as? Timestamp {
                        self.dob = dobTimestamp.dateValue()
                    }

                    self.gender = data["gender"] as? String ?? "Not Set"
                    self.weight = data["weight"] as? String ?? "0"
                    self.activityLevel = data["activityLevel"] as? String ?? "Not Set"
                    self.goal = data["goal"] as? String ?? "Not Set"
                }
            }
        }
    }
    
    func updateUserProfile(name: String, email: String, dob: Date, gender: String, weight: String, activityLevel: String, goal: String) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("❌ No userID found, update failed")
            return
        }

        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userID)

        let timestampDOB = Timestamp(date: dob)

        let userData: [String: Any] = [
            "name": name,
            "email": email,
            "dob": timestampDOB,
            "gender": gender,
            "weight": weight,
            "activityLevel": activityLevel,
            "goal": goal
        ]

        print("📡 Attempting to update Firestore with:", userData)

        userRef.setData(userData, merge: true) { error in
            if let error = error {
                print("❌ Firestore update failed: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    print("✅ Firestore update successful!")
                    self.userName = name
                    self.userEmail = email
                    self.dob = dob
                    self.gender = gender
                    self.weight = weight
                    self.activityLevel = activityLevel
                    self.goal = goal
                }
            }
        }
    }
    // Reset data on logout
    func resetUserData() {
        DispatchQueue.main.async {
            self.userName = "Loading..."
            self.userEmail = "Loading..."
            self.weight = "Loading..."
            self.dob = nil
            self.gender = "Loading..."
            self.activityLevel = "Loading..."
            self.goal = "Loading..."
            self.hasFetched = false
        }
    }
}
