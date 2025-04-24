//
//  MemberWorkoutHistoryView.swift
//  lift
//
//  Created by Josh Pelzer on 4/20/25.
//


import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct MemberWorkoutHistoryView: View {
    let memberId: String
    @State private var workouts: [(id: String, title: String, date: Date, exercises: [String])] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading workouts...")
                        .padding()
                } else if workouts.isEmpty {
                    VStack {
                        Image(systemName: "list.bullet.rectangle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.gray)
                        
                        Text("No workouts in the last 7 days")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 100)
                } else {
                    ScrollView {
                        VStack(spacing: 15) {
                            ForEach(workouts, id: \.id) { workout in
                                WorkoutCard(workout: workout)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("7-Day History")
            .onAppear(perform: fetchWorkoutHistory)
        }
    }
    
    private func fetchWorkoutHistory() {
        print("FETCHING MEMBER WORKOUT HISTORY FOR: \(memberId)")
        
        let db = Firestore.firestore()
//        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        db.collection("users").document(memberId).collection("workouts")
            .limit(to: 7)
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error fetching workouts: \(error.localizedDescription)")
                        self.workouts = []
                    } else {
                        self.workouts = snapshot?.documents.compactMap { doc in
                            let id = doc.documentID
                            let title = doc["title"] as? String ?? "No Title"
                            let timestamp = (doc["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                            
                            let exercisesArray = doc["exercises"] as? [[String: Any]] ?? []
                            let formattedExercises = exercisesArray.compactMap { exercise -> String? in
                                guard let name = exercise["name"] as? String,
                                      let sets = exercise["sets"] as? Int,
                                      let reps = exercise["reps"] as? Int else { return nil }
                                return "\(sets)x\(reps) \(name)"
                            }
                            
                            return (id, title, timestamp, formattedExercises)
                        } ?? []
                    }
                    self.isLoading = false
                }
            }
    }
}
