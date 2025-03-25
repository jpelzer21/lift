//
//  ExerciseCard.swift
//  lift
//
//  Created by Josh Pelzer on 3/16/25.
//
import SwiftUI

struct ExerciseCard: View {
    @Environment(\.colorScheme) var colorScheme
    let exerciseName: String
    let setCount: Int?
    let lastSetDate: Date?
    let isDeleting: Bool
    let deleteAction: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(exerciseName.replacingOccurrences(of: "_", with: " ").capitalized(with: .autoupdatingCurrent))
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .fontWeight(.semibold)
                
                if let setCount = setCount {
                    Text("Sets: \(setCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("Last: \(formattedDate(lastSetDate))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isDeleting {
                Button(action: deleteAction) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .background(Circle().fill(Color.white))
                }
            } else {
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6) : .white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else {
            return "N/A"  // Show "N/A" if no last set date exists
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
