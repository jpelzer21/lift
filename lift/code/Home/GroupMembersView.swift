import SwiftUI

struct GroupMembersView: View {
    let members: [Member]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List(members) { member in
                HStack(spacing: 16) {
                    AsyncImage(url: URL(string: member.profileURL)) { phase in
                        if let image = phase.image {
                            image.resizable()
                        } else if phase.error != nil {
                            Image(systemName: "person.crop.circle.badge.exclamationmark")
                                .resizable()
                        } else {
                            ProgressView()
                        }
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(member.name)
                            .font(.headline)
                        Text(member.role.capitalized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text("Joined: \(formattedDate(member.joinedAt))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 6)
            }
            .navigationTitle("Group Members")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}