import SwiftUI

struct GroupWorkoutDetailView: View {
    let workout: (workoutId: String, memberId: String, templateName: String, date: Date)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🏋️ Workout Details")
                .font(.title2)
                .bold()
            
            Text("Template: \(workout.templateName)")
                .font(.headline)
            
            Text("Date: \(workout.date.formatted(date: .abbreviated, time: .shortened))")
                .font(.subheadline)
            
            Text("Member ID: \(workout.memberId)")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            // 🔮 Later you can fetch actual workout sets/reps here if you want
            Spacer()
        }
        .padding()
        .navigationTitle("Workout Detail")
    }
}