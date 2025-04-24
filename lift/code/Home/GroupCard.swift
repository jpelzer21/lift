//
//  GroupCard.swift
//  lift
//
//  Created by Josh Pelzer on 4/9/25.
//

import SwiftUI

struct GroupCard: View {
    @Environment(\.colorScheme) var colorScheme
    let group: WorkoutGroup
    let isAdmin: Bool
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Spacer()
                    if isAdmin {
                        AdminBadge()
                    }
                }
                Spacer()
            }
            
            VStack {
                // Header with group name and admin badge
                HStack(alignment: .top) {
                    Spacer()
                    VStack {
                        Spacer()
                        Text(group.name)
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    Spacer()
                }
                
                // Description
                Text(group.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Divider()
                    .padding(.vertical, 4)
                
                // Stats row
                HStack(spacing: 20) {
                    GroupStatItem(icon: "person.3.fill", value: "\(group.members.count)", label: "Members")
                    
                    GroupStatItem(icon: "calendar", value: formattedDate(group.createdAt), label: "Created")
                    
                    GroupStatItem(icon: "doc.text.fill", value: "\(group.templates.count)", label: "Templates")
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .frame(height: 150)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(colorScheme == .dark ? .systemGray6 : .white))
                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 5)
        .padding(.vertical, 8)
        
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Subviews

struct AdminBadge: View {
    var body: some View {
        Text("Admin")
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.2))
            .foregroundColor(.blue)
            .cornerRadius(4)
    }
}

private struct GroupStatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}


struct WorkoutGroup: Identifiable {
    var id: String
    let name: String
    let description: String
    let code: String
    let memberCount: Int
    let createdAt: Date
    let isAdmin: Bool
    var templates: [WorkoutTemplate]
    var members: [Member]
    let everyoneCanEdit: Bool
}

struct Member: Identifiable {
    var id: String
    let name: String
    var profileURL: URL?
    var role: String
}

struct WorkoutTemplate: Identifiable, Codable {
    var id: String // Firestore document ID
    let name: String
    let exercises: [Exercise]
}
