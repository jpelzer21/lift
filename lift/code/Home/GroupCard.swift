//
//  GroupCard.swift
//  lift
//
//  Created by Josh Pelzer on 4/9/25.
//


import SwiftUI

struct GroupCard: View {
    let name: String // Changed to take full group object
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header with group name and admin badge
            HStack(alignment: .top) {
                Text(name)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.primary)
            }
        }
        .padding(16)
        .frame(width: 300, height: 150)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }
}


struct WorkoutGroup: Identifiable {
    var id: String
    let name: String
    let description: String
    let memberCount: Int
    let createdAt: Date
    let isAdmin: Bool
    var templates: [WorkoutTemplate]
}



//
//
//let sampleGroup = WorkoutGroup(
//    id: "group123",
//    name: "Morning Workout Crew",
//    description: "Group for early risers",
//    memberCount: 8,
//    createdAt: Date().addingTimeInterval(-86400), // Yesterday
//    isAdmin: true
//)
//
//let sampleTemplate = WorkoutTemplate(
//    name: "Upper Body Routine",
//    exercises: [
//        Exercise(
//            name: "Bench Press",
//            sets: [
//                ExerciseSet(number: 1, weight: 135, reps: 10),
//                ExerciseSet(number: 2, weight: 155, reps: 8)
//            ]
//        )
//    ]
//)
