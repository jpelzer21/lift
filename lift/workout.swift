//
//  ContentView.swift
//  lift
//
//  Created by Josh Pelzer on 2/20/25.
//

import SwiftUI
import CoreData

struct workout: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>

    
    
    var body: some View {
        
            Text("Select an item")
        
    }

    

    
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

#Preview {
    workout().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
