//
//  GroupMembersView.swift
//  lift
//
//  Created by Josh Pelzer on 4/10/25.
//


import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct GroupMembersView: View {
    let groupId: String
    @State var members: [Member]
    
    @Environment(\.dismiss) private var dismiss
    @State private var showConfirmation = false
    @State private var memberToRemove: Member?
    
    private var isAdmin: Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return false }
        return members.first(where: { $0.id == currentUserId })?.role == "admin"
    }
    
    var body: some View {
        NavigationView {
            VStack {
                ForEach($members) { $member in
                    HStack(spacing: 16) {
                        if let profileURL = member.profileURL,
                           let base64String = profileURL.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                           !base64String.isEmpty,
                           let imageData = Data(base64Encoded: base64String),
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.blue.opacity(0.2), lineWidth: 1))
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.gray)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(member.name)
                                .font(.headline)
                           
                        }
                        Spacer()

                        if isAdmin && member.id != Auth.auth().currentUser?.uid {
                            Button(action: {
                                memberToRemove = member
                                showConfirmation = true
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding(20)
            .navigationTitle("Group Members")
            .confirmationDialog("Remove this member?", isPresented: $showConfirmation, titleVisibility: .visible) {
                Button("Remove", role: .destructive) {
                    if let member = memberToRemove {
                        removeMember(member)
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func removeMember(_ member: Member) {
        let db = Firestore.firestore()
        
        // Remove member from group's subcollection
        db.collection("groups").document(groupId).collection("members").document(member.id).delete { error in
            if let error = error {
                print("Failed to remove member from group: \(error)")
                return
            }
            
            // Remove group reference from user's collection
            db.collection("users").document(member.id).collection("groups").document(groupId).delete { error in
                if let error = error {
                    print("Failed to remove group reference from user: \(error)")
                }
            }
            
            // Update local state
            members.removeAll { $0.id == member.id }
        }
    }
}








