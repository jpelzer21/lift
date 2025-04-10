import SwiftUI

struct CreateGroupView: View {
    @Environment(\.dismiss) var dismiss

    @State private var groupName: String = ""
    @State private var groupDescription: String = ""
    @State private var isCreating = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Create a New Group")
                    .font(.title2)
                    .fontWeight(.semibold)

                TextField("Group Name", text: $groupName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                TextField("Description (optional)", text: $groupDescription)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

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
            .padding()
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
        guard !groupName.isEmpty else {
            errorMessage = "Group name is required."
            return
        }

        isCreating = true
        errorMessage = nil

        // 🔧 Replace this with actual Firestore logic
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Simulate success
            isCreating = false
            dismiss()
        }

        // If there’s an error:
        // self.errorMessage = "Failed to create group."
        // self.isCreating = false
    }
}