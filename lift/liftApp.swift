//
//  liftApp.swift
//  lift
//
//  Created by Josh Pelzer on 2/20/25.
//

import SwiftUI

@main
struct liftApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
