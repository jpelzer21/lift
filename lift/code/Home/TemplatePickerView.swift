//
//  TemplatePickerView.swift
//  lift
//
//  Created by Josh Pelzer on 4/10/25.
//

import SwiftUI

struct TemplatePickerView: View {
    let templates: [WorkoutTemplate]
    let onSelect: (WorkoutTemplate) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List(templates) { template in
                Button(action: {
                    onSelect(template)
                    dismiss()
                }) {
                    VStack(alignment: .leading) {
                        Text(template.name)
                            .font(.headline)
                        Text("\(template.exercises.count) exercises")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Select Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
