//
//  WorkoutTemplateCard.swift
//  lift
//
//  Created by Josh Pelzer on 3/15/25.
//


import SwiftUI

struct TemplateCard: View {
    @Environment(\.colorScheme) var colorScheme
    let templateName: String
    let exercises: [Exercise]
    let showDeleteButton: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    @State var showingAlert: Bool = false
    

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(templateName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    if showDeleteButton { // Conditionally show delete button
                        Button {
                            showingAlert = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .padding(8)
                        }.alert(isPresented:$showingAlert) {
                            Alert(
                                title: Text("Delete This Template?"),
                                primaryButton: .destructive(Text("Delete")) {
                                    onDelete()
                                    print("Template Deleted")
                                },
                                secondaryButton: .cancel(Text("Cancel"))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                if exercises.isEmpty {
                    Text("No exercises yet")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(exercises.prefix(3)) { exercise in
                            Text("• \(exercise.name)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        if exercises.count > 3 {
                            Text("+ \(exercises.count - 3) more")
                                .font(.caption)
                                .foregroundColor(.gray)
                        } else {
                            Group {
                                ForEach(0..<(3 - exercises.count), id: \.self) { _ in
                                    Text("• ")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                }
                                Text("+ \(0) more")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(colorScheme == .dark ? Color(.systemGray6) : .white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
