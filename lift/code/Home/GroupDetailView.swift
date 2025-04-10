//
//  GroupCard 2.swift
//  lift
//
//  Created by Josh Pelzer on 4/9/25.
//


import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct GroupDetailView: View {
    let group: WorkoutGroup
    @Environment(\.dismiss) private var dismiss
    @State private var showConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                // Group Name
                Text(group.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // Description
                Text(group.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                
                // Info Section
                HStack {
                    Label("\(group.memberCount) members", systemImage: "person.3.fill")
                    Spacer()
                    Label("Created: \(formattedDate(group.createdAt))", systemImage: "calendar")
                }
                .font(.subheadline)
                .foregroundColor(.gray)

                if group.isAdmin {
                    Text("You are an admin of this group")
                        .font(.footnote)
                        .foregroundColor(.green)
                        .padding(.top, 4)
                }
                
                Divider()
                
                // Templates Section
                Text("Workout Templates")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if group.templates.isEmpty {
                    Text("No templates available.")
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                } else {
//                    VStack(alignment: .leading, spacing: 8) {
//                        ForEach(group.templates, id: \.id) { template in
//                            VStack(alignment: .leading, spacing: 4) {
//                                Text(template.name)
//                                    .font(.headline)
//                                Text(template.description)
//                                    .font(.subheadline)
//                                    .foregroundColor(.gray)
//                            }
//                            .padding()
//                            .background(Color(.secondarySystemBackground))
//                            .cornerRadius(10)
//                        }
//                    }
                }

                Divider()
                
                // Leave Group Button
                Button(role: .destructive) {
                    showConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Leave Group")
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.top, 20)

                Spacer()
            }
            .padding()
        }
        .confirmationDialog("Are you sure you want to leave this group?", isPresented: $showConfirmation, titleVisibility: .visible) {
            Button("Leave Group", role: .destructive) {
                leaveGroup()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
    
    // MARK: - Helper Methods

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func leaveGroup() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Error: User not logged in.")
            return
        }

        let db = Firestore.firestore()
        let userGroupRef = db.collection("users").document(userId).collection("groups").document(group.id)
        let groupMembersRef = db.collection("groups").document(group.id).collection("members").document(userId)
        let groupRef = db.collection("groups").document(group.id)

        let batch = db.batch()

        // Remove group from user's collection
        batch.deleteDocument(userGroupRef)

        // Remove user from group's members collection
        batch.deleteDocument(groupMembersRef)

        // Decrease member count by 1 (atomic decrement)
        batch.updateData(["memberCount": FieldValue.increment(Int64(-1))], forDocument: groupRef)

        batch.commit { error in
            if let error = error {
                print("Error leaving group: \(error.localizedDescription)")
                // Optionally: show user feedback here
            } else {
                print("Successfully left the group and updated member count.")
                dismiss()
            }
        }
    }
}
