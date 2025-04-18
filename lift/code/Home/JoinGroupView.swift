//
//  JoinGroupView.swift
//  lift
//
//  Created by Josh Pelzer on 4/9/25.
//


import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct JoinGroupView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var groupCode: String = ""
    @State private var errorMessage: String?
    @State private var isJoining = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Enter Group Code")
                    .font(.title2)
                    .fontWeight(.semibold)

                TextField("e.g. ABC123", text: $groupCode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .autocapitalization(.allCharacters)
                    .disableAutocorrection(true)

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }

                Button(action: joinGroup) {
                    if isJoining {
                        ProgressView()
                    } else {
                        Text("Join Group")
                            .fontWeight(.semibold)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 10)
                            .background(Color.pink)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .disabled(groupCode.isEmpty || isJoining)

                Spacer()
            }
            .padding()
            .navigationTitle("Join Group")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func joinGroup() {
        print("JOIN GROUP() CALLED")
        guard !groupCode.isEmpty else {
            errorMessage = "Please enter a group code."
            return
        }
        
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "You must be logged in to join a group."
            return
        }
        
        isJoining = true
        errorMessage = nil
        
        let db = Firestore.firestore()
        
        // First find the group with matching code
        db.collection("groups")
          .whereField("code", isEqualTo: groupCode.uppercased())
          .limit(to: 1)
          .getDocuments { (snapshot, error) in
              self.isJoining = false  // Directly reference self
              
              if let error = error {
                  self.errorMessage = "Error searching for group: \(error.localizedDescription)"
                  return
              }
              
              guard let document = snapshot?.documents.first else {
                  self.errorMessage = "No group found with that code. Check the code and try again."
                  return
              }
              
              let groupId = document.documentID
              
              // Check if user is already in the group
              let userGroupRef = db.collection("users").document(userId)
                  .collection("groups").document(groupId)
              
              userGroupRef.getDocument { (userGroupDoc, error) in
                  self.isJoining = false
                  
                  if let error = error {
                      self.errorMessage = "Error checking membership: \(error.localizedDescription)"
                      return
                  }
                  
                  if userGroupDoc?.exists == true {
                      self.errorMessage = "You're already a member of this group."
                      return
                  }
                  
                  // Use a batch to atomically update both group and user
                  let batch = db.batch()
                  
                  // 1. Update group's member count
                  batch.updateData([
                      "memberCount": FieldValue.increment(Int64(1))
                  ], forDocument: document.reference)
                  
                  // 2. Add user to group's members subcollection
                  let groupMemberRef = document.reference.collection("members").document(userId)
                  batch.setData([
                      "userId": userId,
                      "joinedAt": FieldValue.serverTimestamp(),
                      "role": "member"
                  ], forDocument: groupMemberRef)
                  
                  // 3. Add group to user's groups subcollection
                  batch.setData([
                      "groupId": groupId,
                      "joinedAt": FieldValue.serverTimestamp(),
                      "role": "member",
                      "groupName": document.data()["name"] as? String ?? ""
                  ], forDocument: userGroupRef)
                  
                  // Commit the batch
                  batch.commit { error in
                      self.isJoining = false
                      
                      if let error = error {
                          self.errorMessage = "Failed to join group: \(error.localizedDescription)"
                      } else {
                          self.dismiss()
                      }
                  }
              }
          }
    }
}
