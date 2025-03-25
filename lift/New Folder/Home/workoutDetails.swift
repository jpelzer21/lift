//
//  DateDetailView.swift
//  lift
//
//  Created by Josh Pelzer on 3/19/25.
//


import SwiftUI

struct DateDetailView: View {
    var date: Date
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }()

    var body: some View {
        VStack {
            Text("Workout Details")
                .font(.largeTitle)
                .bold()
                .padding()

            Text(dateFormatter.string(from: date))
                .font(.title)
                .padding()

            Spacer()
        }
        .navigationTitle("Workout Day")
        .navigationBarTitleDisplayMode(.inline)
    }
}
