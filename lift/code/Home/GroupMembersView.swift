//
//  GroupMembersView.swift
//  lift
//
//  Created by Josh Pelzer on 4/10/25.
//


import SwiftUI

struct GroupMembersView: View {
    @State var members: [Member]
    @Environment(\.dismiss) private var dismiss

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
                        
//                        Text("Joined: \(formattedDate(member.joinedAt))")
//                            .font(.caption)
//                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 6)
                }
                .navigationTitle("Group Members")
                .toolbar {
//                    ToolbarItem(placement: .topBarLeading) {
//                        Button("Done") {
//                            dismiss()
//                        }
//                    }
                }
                Spacer()
            }
            .padding(20)
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
