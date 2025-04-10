import SwiftUI

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
        guard !groupCode.isEmpty else {
            errorMessage = "Please enter a group code."
            return
        }

        isJoining = true
        errorMessage = nil

        // 🔧 Replace this with your Firestore group-joining logic
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Simulate success
            isJoining = false
            dismiss()
        }

        // If there’s an error:
        // self.errorMessage = "Group not found."
        // self.isJoining = false
    }
}