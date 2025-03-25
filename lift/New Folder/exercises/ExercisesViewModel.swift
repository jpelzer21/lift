//
//  ExerciseListViewModel.swift
//  lift
//
//  Created by Josh Pelzer on 3/20/25.
//


import FirebaseFirestore
import FirebaseAuth
import SwiftUI

class ExercisesViewModel: ObservableObject {
    @Published var exercises: [(name: String, setCount: Int?, lastSetDate: Date?)] = []
    @Published var isLoading = true
    @Published var selectedSortOption: String = "A-Z"

    private var listener: ListenerRegistration?
    private var userID: String? { Auth.auth().currentUser?.uid }

    init() {
        fetchExercises()
    }

    func fetchExercises() {
        print("FETCH EXERCISES() CALLED")
        guard let userID = userID else { return }

        let db = Firestore.firestore()
        var query: Query = db.collection("users").document(userID).collection("exercises")

        switch selectedSortOption {
        case "Most Recent":
            query = query.order(by: "lastSetDate", descending: true)
        case "Most Sets":
            query = query.order(by: "setCount", descending: true)
        case "Alphabetical A-Z":
            query = query.order(by: "name", descending: false)
        case "Alphabetical Z-A":
            query = query.order(by: "name", descending: true)
        default:
            break
        }

        listener?.remove()
        listener = query.addSnapshotListener { snapshot, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    print("Error fetching exercises: \(error.localizedDescription)")
                    self.exercises = []
                } else {
                    self.exercises = snapshot?.documents.compactMap { doc in
                        guard let name = doc.data()["name"] as? String else { return nil }
                        let setCount = doc.data()["setCount"] as? Int
                        let lastSetTimestamp = doc.data()["lastSetDate"] as? Timestamp
                        let lastSetDate = lastSetTimestamp?.dateValue()
                        
                        return (name: name, setCount: setCount, lastSetDate: lastSetDate)
                    } ?? []
                }
            }
        }
    }

    func deleteExercise(named name: String) {
        print("DELETE EXERCISE() CALLED")
        guard let userID = userID else { return }

        let db = Firestore.firestore()
        db.collection("users").document(userID).collection("exercises").document(name).delete { error in
            if let error = error {
                print("Error deleting exercise: \(error.localizedDescription)")
            } else {
                print(name)
                DispatchQueue.main.async {
                    self.exercises.removeAll { $0.name == name }
                }
            }
        }
    }
}
