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
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var viewModel: UserViewModel
    @Environment(\.dismiss) private var dismiss
    
    let group: WorkoutGroup
    @State private var groupTemplates: [WorkoutTemplate] = []
    @State private var showLeaveConfirmation = false
    @State private var showDeleteConfirmation = false
    @State private var selectedExercises: [Exercise] = []
    @State private var selectedWorkoutTitle: String = "Empty Workout"
    @State private var showWorkoutView = false
    @State private var showTemplatePicker = false
    @State private var showMembersView = false
    
    @State private var showCopiedAlert = false

    
    private var isAdmin: Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return false }
            if let member = group.members.first(where: { $0.id == currentUserId }) {
                return member.role == "admin"
            }
            return false
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        // Group Name
                        Text(group.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        // Description
                        Text(group.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if isAdmin {
                        AdminBadge()
                    }
                }
                
                // Info Section
                HStack {
                    Button(action: {
                        print(group.members)
                        showMembersView = true
                    }) {
                        Label("\(group.members.count) members", systemImage: "person.3.fill")
                            .font(.subheadline)
                            .foregroundColor(.pink)
                    }
                    .sheet(isPresented: $showMembersView) {
                        GroupMembersView(groupId: group.id, members: group.members)
                    }
                    Spacer()
                    Label("Created: \(formattedDate(group.createdAt))", systemImage: "calendar")
                }
                .font(.subheadline)
                .foregroundColor(.gray)
                   
                
                Divider()
                
                
                
                
                // Group Code Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("GROUP CODE")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.leading, 2)
                    
                    HStack {
                        Text(group.code)
                            .font(.title2)
                            .fontWeight(.bold)
                            .monospacedDigit()
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button(action: copyCodeToClipboard) {
                            HStack(spacing: 6) {
                                Image(systemName: showCopiedAlert ? "checkmark" : "doc.on.doc")
                                Text(showCopiedAlert ? "Copied!" : "Copy")
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(showCopiedAlert ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
                            .foregroundColor(showCopiedAlert ? .green : .blue)
                            .cornerRadius(8)
                            .animation(.easeInOut(duration: 0.2), value: showCopiedAlert)
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                    )
                }
                
                Divider()
                
                HStack {
                    // Templates Section
                    Text("Templates:")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                    if isAdmin || group.everyoneCanEdit {
                        Button(action: {
                            showTemplatePicker = true
                        }) {
                            Label("Add Templates", systemImage: "plus")
                                .font(.headline)
                        }
                    }
                }
                
                if groupTemplates.isEmpty {
                    Text("No templates available.")
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                } else {
                    VStack {
                        ForEach(groupTemplates, id: \.id) {template in
                            TemplateCard(templateName: template.name,
                                         exercises: template.exercises,
                                         showDeleteButton: isAdmin,
                                         onTap: {
                                            selectedWorkoutTitle = template.name
                                            selectedExercises = template.exercises
                                            showWorkoutView.toggle()
                                        },
                                        onDelete: {
                                            if isAdmin || group.everyoneCanEdit {
                                                deleteTemplate(template)
                                            }
                                        })
                        }
                    }
                }

                Divider()
                
                // Leave Group Button
                Button(role: .destructive) {
                    showLeaveConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Leave Group")
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.top, 20)
                if isAdmin {
                    Spacer()
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Group")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.top, 20)
                }

                Spacer()
            }
            .padding()
        }
        .onAppear {
            fetchGroupTemplates()
        }
        .confirmationDialog("Are you sure you want to leave this group?", isPresented: $showLeaveConfirmation, titleVisibility: .visible) {
            Button("Leave Group", role: .destructive) {
                leaveGroup()
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Are you sure you want to Delete \(group.name)?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete Group", role: .destructive) {
                viewModel.deleteGroup(group)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
        .fullScreenCover(isPresented: $showWorkoutView, onDismiss: {
            viewModel.fetchTemplatesRealtime()
        }) {
            WorkoutView(workoutTitle: $selectedWorkoutTitle, exercises: $selectedExercises)
        }
        .sheet(isPresented: $showTemplatePicker) {
            TemplatePickerView(templates: viewModel.templates) { selectedTemplate in
                addTemplateToGroup(selectedTemplate)
            }
        }
    }
    
    private func copyCodeToClipboard() {
        UIPasteboard.general.string = group.code
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Visual feedback
        showCopiedAlert = true
        
        // Reset after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showCopiedAlert = false
            }
        }
    }
    

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func fetchGroupTemplates() {
        print("FETCH GROUP TEMPLATES() CALLED")
        let db = Firestore.firestore()
        
        db.collection("groups")
            .document(group.id)
            .collection("templates")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching group templates: \(error.localizedDescription)")
                    return
                }
                
                // Use self directly
                guard let documents = snapshot?.documents else {
                    print("No templates found for group.")
                    self.groupTemplates = []
                    return
                }

                self.groupTemplates = documents.compactMap { document in
                    do {
                        let data = document.data()
                        
                        // Manual decoding for better error handling
                        guard let name = data["name"] as? String,
                              let exercisesData = data["exercises"] as? [[String: Any]] else {
                            print("Missing required fields in template \(document.documentID)")
                            return nil
                        }
                        
                        let exercises = exercisesData.compactMap { exerciseDict -> Exercise? in
                            guard let exerciseName = exerciseDict["name"] as? String,
                                  let setsData = exerciseDict["sets"] as? [[String: Any]] else {
                                print("Invalid exercise format in template \(document.documentID)")
                                return nil
                            }
                            
                            let sets = setsData.compactMap { setDict -> ExerciseSet? in
                                guard let reps = setDict["reps"] as? Int,
                                      let setNum = setDict["setNum"] as? Int,
                                      let weight = setDict["weight"] as? Double else {
                                    print("Invalid set format in template \(document.documentID)")
                                    return nil
                                }
                                
                                let date: Date
                                if let timestamp = setDict["date"] as? Timestamp {
                                    date = timestamp.dateValue()
                                } else {
                                    date = Date() // Default to current date
                                }
                                
                                return ExerciseSet(
                                    id: UUID(),
                                    number: setNum,
                                    weight: weight,
                                    reps: reps,
                                    date: date,
                                    isCompleted: false
                                )
                            }
                            
                            return Exercise(name: exerciseName, sets: sets)
                        }
                        
                        return WorkoutTemplate(
                            id: document.documentID,
                            name: name,
                            exercises: exercises
                        )
                    }
                }
                
                print("Successfully loaded \(self.groupTemplates.count) templates")
            }
    }
    
    private func deleteTemplate(_ template: WorkoutTemplate) {
        let db = Firestore.firestore()
        db.collection("groups").document(group.id).collection("templates").document(template.id).delete { error in
            if let error = error {
                print("Error deleting template: \(error)")
            } else {
                // Remove the template from the local array
                groupTemplates.removeAll { $0.id == template.id }
            }
        }
    }

    
    private func addTemplateToGroup(_ template: WorkoutTemplate) {
        print("ADD TEMPLATE TO GROUP() CALLED")
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Error: User not logged in.")
            return
        }
        
        let db = Firestore.firestore()
        let groupTemplatesRef = db.collection("groups").document(group.id).collection("templates")
        
        // Convert template to Firestore-compatible format
        let templateData: [String: Any] = [
            "name": template.name,
            "createdBy": userId,
            "createdAt": FieldValue.serverTimestamp(),
            "exercises": template.exercises.map { exercise in
                return [
                    "name": exercise.name,
                    "sets": exercise.sets.map { set in
                        return [
                            "setNum": set.number,
                            "reps": set.reps,
                            "weight": set.weight,
                            "date": Timestamp(date: set.date)
                        ]
                    }
                ]
            }
        ]
        
        // Add with error handling
        groupTemplatesRef.addDocument(data: templateData) { error in
            if let error = error {
                print("Error adding template: \(error.localizedDescription)")
            } else {
                print("Template added successfully")
                self.fetchGroupTemplates()
            }
        }
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
    
    private func validateTemplate(_ template: WorkoutTemplate) -> Bool {
        guard !template.name.isEmpty else { return false }
        guard !template.exercises.isEmpty else { return false }
        return template.exercises.allSatisfy { !$0.sets.isEmpty }
    }
}
