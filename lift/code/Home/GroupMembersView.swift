import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct GroupMembersView: View {
    let groupId: String
    @State var members: [Member]

    @Environment(\.dismiss) private var dismiss
    @State private var showConfirmation = false
    @State private var memberToRemove: Member?
    @State private var promotingMemberId: String?

    private var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }

    private var isAdmin: Bool {
        guard let currentUserId else { return false }
        return members.first(where: { $0.id == currentUserId })?.role == "admin"
    }

    var body: some View {
        NavigationView {
            List {
                ForEach($members) { $member in
//                    NavigationLink(destination: MemberWorkoutHistoryView(memberId: member.id)) {
                        HStack(spacing: 16) {
                            profileImage(for: member)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(member.name)
                                        .font(.headline)
                                    
                                    if member.role == "admin" {
                                        Text("Admin")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.blue)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            if isAdmin && member.id != currentUserId {
                                Button(action: {
                                    memberToRemove = member
                                    showConfirmation = true
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .padding(.vertical, 8)
//                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if isAdmin && member.role != "admin" && member.id != currentUserId {
                            Button {
                                if isAdmin {
                                    promoteToAdmin(member)
                                }
                            } label: {
                                Label("Make Admin", systemImage: "chevron.up")
                            }
                            .tint(.blue)
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        if isAdmin && member.role == "admin" && member.id != currentUserId {
                            Button(role: .destructive) {
                                if isAdmin {
                                    demoteToMember(member)
                                }
                            } label: {
                                Label("Remove Admin", systemImage: "chevron.down")
                            }
                            .tint(.red)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
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

    @ViewBuilder
    private func profileImage(for member: Member) -> some View {
        if let profileURL = member.profileURL,
           let base64String = profileURL.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
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
    }

    private func removeMember(_ member: Member) {
        let db = Firestore.firestore()

        db.collection("groups").document(groupId).collection("members").document(member.id).delete { error in
            if let error = error {
                print("Failed to remove member from group: \(error)")
                return
            }

            db.collection("users").document(member.id).collection("groups").document(groupId).delete { error in
                if let error = error {
                    print("Failed to remove group reference from user: \(error)")
                }
            }

            members.removeAll { $0.id == member.id }
        }
    }

    private func promoteToAdmin(_ member: Member) {
        let db = Firestore.firestore()
        promotingMemberId = member.id

        db.collection("groups").document(groupId).collection("members").document(member.id).updateData([
            "role": "admin"
        ]) { error in
            promotingMemberId = nil

            if let error = error {
                print("Failed to promote to admin: \(error)")
                return
            }

            if let index = members.firstIndex(where: { $0.id == member.id }) {
                members[index].role = "admin"
            }
        }
    }
    
    private func demoteToMember(_ member: Member) {
        let db = Firestore.firestore()

        db.collection("groups").document(groupId).collection("members").document(member.id).updateData([
            "role": "member"
        ]) { error in
            if let error = error {
                print("Failed to demote to member: \(error)")
                return
            }

            if let index = members.firstIndex(where: { $0.id == member.id }) {
                members[index].role = "member"
            }
        }
    }
}
