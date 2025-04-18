//
//  CreateGroupView.swift
//  lift
//
//  Created by Josh Pelzer on 4/9/25.
//


import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct CreateGroupView: View {
    @Environment(\.dismiss) var dismiss

    @State private var groupName: String = ""
    @State private var groupDescription: String = ""
    @State private var groupCode: String = ""
    @State private var isCreating = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {

                TextField("Group Name", text: $groupName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                TextField("Description (optional)", text: $groupDescription)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                TextField("Group Code (e.g. ABC123)", text: $groupCode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .autocapitalization(.allCharacters)
                    .disableAutocorrection(true)
                    .onChange(of: groupCode) { _, newValue in
                        let filtered = newValue.uppercased().filter { $0.isLetter || $0.isNumber }
                        groupCode = String(filtered.prefix(8))
                    }

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }

                Button(action: createGroup) {
                    if isCreating {
                        ProgressView()
                    } else {
                        Text("Create Group")
                            .fontWeight(.semibold)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 10)
                            .background(Color.pink)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .disabled(groupName.isEmpty || isCreating)

                Spacer()
            }
            .padding(.vertical, 25)
            .navigationTitle("Create Group")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func createGroup() {
        print("CREATE GROUP() CALLED")
        // Validate inputs
        guard !groupName.isEmpty else {
            errorMessage = "Group name cannot be empty"
            return
        }
        
        guard groupCode.count >= 4 else {
            errorMessage = "Group code must be at least 4 characters"
            return
        }
        
        isCreating = true
        errorMessage = nil
        
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "You must be logged in to create a group"
            isCreating = false
            return
        }
        
        let db = Firestore.firestore()
        let groupsCollection = db.collection("groups")
        
        // Check if group code is already taken
        groupsCollection.whereField("code", isEqualTo: groupCode).getDocuments { snapshot, error in
            if let error = error {
                errorMessage = "Error checking group code: \(error.localizedDescription)"
                isCreating = false
                return
            }
            
            guard snapshot?.documents.isEmpty == true else {
                errorMessage = "This group code is already taken"
                isCreating = false
                return
            }
            
            // Create the group document
            let groupData: [String: Any] = [
                "name": groupName,
                "description": groupDescription,
                "code": groupCode,
                "createdAt": Timestamp(date: Date()),
                "ownerId": userId,
                "memberCount": 1
            ]
            
            var groupRef: DocumentReference?
            groupRef = groupsCollection.addDocument(data: groupData) { error in
                if let error = error {
                    errorMessage = "Error creating group: \(error.localizedDescription)"
                    isCreating = false
                    return
                }
                
                guard let groupId = groupRef?.documentID else {
                    errorMessage = "Failed to get group ID"
                    isCreating = false
                    return
                }
                
                let joinedAt = Timestamp(date: Date())

                // Add to user's groups subcollection
                let userGroupRef = db.collection("users").document(userId)
                    .collection("groups").document(groupId)
                
                let userGroupData: [String: Any] = [
                    "groupId": groupId,
                    "joinedAt": joinedAt,
                    "role": "admin"
                ]
                
                // Add to group's members subcollection
                let groupMemberRef = db.collection("groups").document(groupId)
                    .collection("members").document(userId)
                
                let groupMemberData: [String: Any] = [
                    "userId": userId,
                    "joinedAt": joinedAt,
                    "role": "admin"
                ]
                
                let batch = db.batch()
                batch.setData(userGroupData, forDocument: userGroupRef)
                batch.setData(groupMemberData, forDocument: groupMemberRef)
                
                batch.commit { error in
                    isCreating = false
                    
                    if let error = error {
                        errorMessage = "Error setting group membership: \(error.localizedDescription)"
                        groupRef?.delete() // rollback
                        return
                    }
                    
                    dismiss()
                }
            }
        }
    }
}
