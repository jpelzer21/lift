//
//  GroupCard 2.swift
//  lift
//
//  Created by Josh Pelzer on 4/9/25.
//


import SwiftUI

// Detailed Group View
struct GroupDetailView: View {
    let group: WorkoutGroup
    @State private var selectedTab: GroupDetailTab = .about
    @State private var showInviteView = false
    @Environment(\.dismiss) var dismiss
    
    enum GroupDetailTab: String, CaseIterable {
        case about = "About"
        case members = "Members"
        case templates = "Templates"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with cover image
                ZStack(alignment: .bottomLeading) {
                    Color(.systemGray5)
                        .frame(height: 120)
                    
                    Text(group.name)
                        .font(.title.bold())
                        .foregroundColor(.primary)
                        .padding()
                }
                
                // Tab selector
                Picker("Group Sections", selection: $selectedTab) {
                    ForEach(GroupDetailTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Tab content
                TabView(selection: $selectedTab) {
                    AboutGroupTab(group: group)
                        .tag(GroupDetailTab.about)
                    
                    MembersTab(group: group)
                        .tag(GroupDetailTab.members)
                    
                    GroupTemplatesTab(group: group)
                        .tag(GroupDetailTab.templates)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showInviteView = true }) {
                        Image(systemName: "person.badge.plus")
                    }
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showInviteView) {
//                InviteMembersView(group: group)
            }
        }
    }
}

// MARK: - Subviews

struct AboutGroupTab: View {
    let group: WorkoutGroup
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Description")
                    .font(.headline)
                
                Text(group.description.isEmpty ? "No description provided" : group.description)
                    .font(.body)
                
                Divider()
                
                GroupInfoRow(icon: "person.2", title: "Members", value: "\(group.memberCount)")
                GroupInfoRow(icon: "calendar", title: "Created", value: group.createdAt.formatted(date: .long, time: .omitted))
//                GroupInfoRow(icon: "clock", title: "Last Active", value: group.lastActivity?.formatted(.relative(presentation: .named)) ?? "Unknown")
                
                if group.isAdmin {
                    Divider()
                    Text("Admin Tools")
                        .font(.headline)
                    Button("Edit Group Info") { /* ... */ }
                        .buttonStyle(.bordered)
                }
            }
            .padding()
        }
    }
}

struct MembersTab: View {
    let group: WorkoutGroup
    @State private var members: [GroupMember] = []
    @State private var isLoading = false
    
    var body: some View {
        List {
            ForEach(members) { member in
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading) {
                        Text(member.name)
                            .font(.headline)
                        Text(member.role.capitalized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if member.isOwner {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                    }
                }
            }
        }
        .overlay {
            if isLoading {
                ProgressView()
            } else if members.isEmpty {
                ContentUnavailableView("No Members", systemImage: "person.2.slash")
            }
        }
        .task {
            await loadMembers()
        }
    }
    
    private func loadMembers() async {
        isLoading = true
        // Fetch members from Firestore
        // members = await GroupService.fetchMembers(groupId: group.id)
        isLoading = false
    }
}

struct GroupTemplatesTab: View {
    let group: WorkoutGroup
    @State private var sharedTemplates: [WorkoutTemplate] = []
    
    var body: some View {
        Text("")
//        TemplateGridView(templates: sharedTemplates)
//            .overlay {
//                if sharedTemplates.isEmpty {
//                    ContentUnavailableView(
//                        "No Shared Templates",
//                        systemImage: "list.bullet.rectangle",
//                        description: Text("Members haven't shared any templates yet")
//                    )
//                }
//            }
//            .task {
//                // sharedTemplates = await GroupService.fetchSharedTemplates(groupId: group.id)
//            }
    }
}

// MARK: - Supporting Views

struct GroupInfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Label(title, systemImage: icon)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Data Models

struct GroupMember: Identifiable {
    let id: String
    let name: String
    let role: String // "admin", "member"
    let isOwner: Bool
    let joinDate: Date
}

// MARK: - Preview
//
//struct GroupDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        GroupDetailView(group: WorkoutGroup(
//            id: "1",
//            name: "Morning Workout Crew",
//            description: "Group for early risers who want to get their workout done before work",
//            memberCount: 12,
//            createdAt: Date().addingTimeInterval(-86400 * 7),
//            lastActivity: Date().addingTimeInterval(-3600),
//            templates: [],
//            isAdmin: true
//        ))
//    }
//}
