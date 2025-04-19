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
            query = query.order(by: "lastSetDate", descending: true).limit(to: 20)
            case "Most Sets":
            query = query.order(by: "setCount", descending: true).limit(to: 20)
            case "Alphabetical A-Z":
                query = query.order(by: "name", descending: false).limit(to: 20)
            case "Alphabetical Z-A":
                query = query.order(by: "name", descending: true).limit(to: 20)
            case "Muscle Groups":
                query = query.order(by: "muscleGroups", descending: true).limit(to: 20)
            default:
                query = query.order(by: "name", descending: false).limit(to: 20) // Default to A-Z ordering
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
        guard let userID = userID else {
            print("No user logged in.")
            return
        }
        
        print("Attempting to delete exercise: \(name)")
        
        let db = Firestore.firestore()
        let exercisesRef = db.collection("users").document(userID).collection("exercises")

        // Query for exercises with the specified name
        exercisesRef.whereField("name", isEqualTo: name).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching exercise to delete: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents, !documents.isEmpty else {
                print("No exercise found with name: \(name)")
                return
            }
            
            // Assuming there is only one document with that name, delete it
            for document in documents {
                exercisesRef.document(document.documentID).delete { error in
                    if let error = error {
                        print("Error deleting exercise: \(error.localizedDescription)")
                    } else {
                        print("Exercise \(name) deleted successfully.")
                        // Remove from the exercises array immediately to update the UI
                        self.exercises.removeAll { exercise in
                            exercise.name == name
                        }
                    }
                }
            }
        }
    }
    
}
