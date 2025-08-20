//
//  GroupWorkoutHistoryView.swift
//  Stat Lab
//
//  Created by Josh Pelzer on 8/20/25.
//

import SwiftUI
import FirebaseFirestore

struct GroupWorkoutHistoryView: View {
    let groupId: String
    @Environment(\.colorScheme) var colorScheme
    
    @State private var workouts: [(id: String, memberId: String, title: String, date: Date)] = []
    @State private var memberNames: [String: String] = [:]
    @State private var isLoading = true
    @State private var isLoadingMore = false
    @State private var hasMoreData = true
    @State private var lastDocument: DocumentSnapshot? = nil
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading group history...")
            } else if workouts.isEmpty {
                Text("No workouts found")
                    .foregroundColor(.secondary)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(workouts.indices, id: \.self) { index in
                            let workout = workouts[index]
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(workout.title)
                                        .font(.headline)
                                    Text("by \(memberNames[workout.memberId] ?? "Unknown")")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text(workout.date, style: .date)
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(colorScheme == .dark ? .systemGray6 : .white))
                                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                            )
                        }
                        
                        // Load More Button
                        if hasMoreData {
                            if isLoadingMore {
                                ProgressView().padding()
                            } else {
                                Button(action: loadMoreWorkouts) {
                                    Text("Load More Workouts")
                                        .font(.subheadline)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                                .padding(.top, 8)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            fetchGroupWorkouts(loadMore: false)
        }
    }
    
    // MARK: - Fetch group workouts
    private func fetchGroupWorkouts(loadMore: Bool = false) {
        let db = Firestore.firestore()
        var query: Query = db.collection("groups").document(groupId).collection("workouts")
            .order(by: "timestamp", descending: true)
            .limit(to: 10)
        
        if loadMore, let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }
        
        query.getDocuments { snapshot, error in
            guard let docs = snapshot?.documents else {
                self.isLoading = false
                self.isLoadingMore = false
                return
            }
            
            if let last = docs.last {
                self.lastDocument = last
            }
            
            let newWorkouts: [(id: String, memberId: String, title: String, date: Date)] =
                docs.compactMap { doc in
                    let id = doc.documentID
                    let title = doc["title"] as? String ?? "No Title"
                    let memberId = doc["userId"] as? String ?? "unknown"
                    let date = (doc["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                    return (id: id, memberId: memberId, title: title, date: date)
                }
            
            DispatchQueue.main.async {
                if loadMore {
                    self.workouts.append(contentsOf: newWorkouts)
                } else {
                    self.workouts = newWorkouts
                }
                self.hasMoreData = !docs.isEmpty
                self.isLoading = false
                self.isLoadingMore = false
                
                // Fetch names for new members
                let memberIds = Set(newWorkouts.map { $0.memberId })
                fetchMemberNames(for: Array(memberIds))
            }
        }
    }
    
    // MARK: - Load More
    private func loadMoreWorkouts() {
        isLoadingMore = true
        fetchGroupWorkouts(loadMore: true)
    }
    
    // MARK: - Member Names
    private func fetchMemberNames(for ids: [String]) {
        let db = Firestore.firestore()
        for id in ids where memberNames[id] == nil {
            db.collection("users").document(id).getDocument { doc, _ in
                if let name = doc?["name"] as? String {
                    DispatchQueue.main.async {
                        memberNames[id] = name
                    }
                }
            }
        }
    }
}
