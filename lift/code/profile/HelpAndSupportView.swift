//
//  HelpAndSupportView.swift
//  lift
//
//  Created by Josh Pelzer on 4/2/25.
//


import SwiftUI

struct HelpAndSupportView: View {
    let supportItems = [
        ("FAQ", "questionmark.circle.fill", Color.blue),
        ("Contact Us", "envelope.fill", Color.green),
        ("Report a Problem", "exclamationmark.triangle.fill", Color.red),
        ("Terms of Service", "doc.text.fill", Color.gray),
        ("Privacy Policy", "lock.fill", Color.purple)
    ]
    
    var body: some View {
        Text("none of this works yet - it is just a tentative layout")
        List {
            Section(header: Text("Help Resources")) {
                ForEach(supportItems, id: \.0) { item in
                    NavigationLink(destination: HelpDetailView(title: item.0)) {
                        HStack {
                            Image(systemName: item.1)
                                .foregroundColor(item.2)
                                .frame(width: 30)
                            Text(item.0)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Need immediate help?")
                        .font(.headline)
                    Text("Our support team is available 24/7 to assist you with any issues or questions you may have.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        // Action to call support
                        if let url = URL(string: "tel://+18005551234") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "phone.fill")
                                .foregroundColor(.white)
                            Text("Call Support")
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    .padding(.top, 5)
                }
                .padding(.vertical, 10)
            }
        }
        .navigationTitle("Help & Support")
        .listStyle(InsetGroupedListStyle())
    }
}

struct HelpDetailView: View {
    let title: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(title)
                    .font(.title)
                    .bold()
                
                Text(loremIpsum)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .navigationTitle(title)
    }
    
    private var loremIpsum: String {
        """
        Contact Developer for questions
        """
    }
}
