import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct HistoryView: View {
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
                        
                        Text("No workout history found!")
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
            .navigationTitle("Workout History")
            .onAppear(perform: fetchWorkoutHistory)
        }
    }
    
    private func fetchWorkoutHistory() {
        print("FETCH WORKOUT HISTORY() CALLED")
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userID).collection("workouts")
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error fetching workouts: \(error.localizedDescription)")
                        self.workouts = []
                    } else {
                        self.workouts = snapshot?.documents.compactMap { doc in
                            let id = doc.documentID  // Unique workout ID
                            let title = doc["title"] as? String ?? "No Title"
                            let timestamp = (doc["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                            
                            // Extract exercises with sets and reps
                            let exercisesArray = doc["exercises"] as? [[String: Any]] ?? []
                            let formattedExercises = exercisesArray.compactMap { exercise -> String? in
                                guard let name = exercise["name"] as? String,
                                      let sets = exercise["sets"] as? Int,
                                      let reps = exercise["reps"] as? Int else { return nil }
                                return "\(sets)x\(reps) \(name)"  // Format as "3x8 Bench Press"
                            }
                            
                            return (id, title, timestamp, formattedExercises)
                        } ?? []
                    }
                    self.isLoading = false
                }
            }
    }
}

struct WorkoutCard: View {
    @Environment(\.colorScheme) var colorScheme
    var workout: (id: String, title: String, date: Date, exercises: [String])
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "dumbbell.fill")
                    .foregroundColor(.pink)
                    .font(.title2)
                
                Text(workout.title)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text(formatDate(workout.date))
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(workout.exercises, id: \.self) { exercise in
                    HStack {
                        Text("• ")
                            .font(.headline)
                        Text(exercise)  // Already formatted as "3x8 Bench Press"
                    }
                    .font(.subheadline)
                }
            }
        }
        .padding()
        .cornerRadius(12)
        .background(colorScheme == .dark ? Color(.systemGray6) : .white)
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
