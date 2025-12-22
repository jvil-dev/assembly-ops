//
//  JW_AssemblyOpsApp.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/21/25.
//

import SwiftUI
import SwiftData

@main
struct JW_AssemblyOpsApp: App {
    
    // MARK: SwiftData Container
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        
        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
        fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    // MARK: - Body
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
