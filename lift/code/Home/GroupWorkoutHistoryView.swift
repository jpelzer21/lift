import SwiftUI
import FirebaseFirestore

struct GroupWorkoutHistoryView: View {
    let groupId: String
    let memberIds: [String]   // pass in all the userIds of group members
    
    @State private var workouts: [(id: String, memberId: String, title: String, date: Date, exercises: [String])] = []
    @State private var isLoading = true
    @State private var memberNames: [String: String] = [:] // cache user names
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading group history...")
                    .padding()
            } else if workouts.isEmpty {
                VStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.gray)
                    
                    Text("No workouts found")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 100)
            } else {
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(workouts, id: \.id) { workout in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(workout.title)
                                    .font(.headline)
                                Text("by \(memberNames[workout.memberId] ?? "Unknown")")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(workout.date, style: .date)
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                
                                ForEach(workout.exercises, id: \.self) { ex in
                                    Text("• \(ex)")
                                        .font(.body)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
                            .shadow(radius: 2)
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear(perform: fetchGroupHistory)
    }
    
    private func fetchGroupHistory() {
        let db = Firestore.firestore()
        var allWorkouts: [(id: String, memberId: String, title: String, date: Date, exercises: [String])] = []
        let dispatchGroup = DispatchGroup()
        
        for memberId in memberIds {
            dispatchGroup.enter()
            db.collection("users").document(memberId).collection("workouts")
                .order(by: "timestamp", descending: true)
                .limit(to: 10) // limit per member
                .getDocuments { snapshot, error in
                    if let docs = snapshot?.documents {
                        let memberWorkouts = docs.compactMap { doc -> (String, String, String, Date, [String])? in
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
                            return (id, memberId, title, timestamp, formattedExercises)
                        }
                        allWorkouts.append(contentsOf: memberWorkouts)
                    }
                    dispatchGroup.leave()
                }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.workouts = allWorkouts.sorted { $0.date > $1.date }
            self.isLoading = false
            fetchMemberNames()
        }
    }
    
    private func fetchMemberNames() {
        let db = Firestore.firestore()
        for memberId in memberIds {
            db.collection("users").document(memberId).getDocument { doc, _ in
                if let name = doc?["name"] as? String {
                    DispatchQueue.main.async {
                        memberNames[memberId] = name
                    }
                }
            }
        }
    }
}