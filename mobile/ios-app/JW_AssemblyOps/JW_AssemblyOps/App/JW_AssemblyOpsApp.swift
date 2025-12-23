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
            Overseer.self,
            Event.self,
            EventTemplate.self,
            EventRequest.self,
            Department.self,
            Volunteer.self,
            Role.self,
            Session.self,
            Assignment.self,
            ScheduleAssignment.self,
                        
            // Feature models
            CheckIn.self,
            AttendanceCount.self,
            Message.self,
            MessageRecipient.self,
            VolunteerAvailability.self,
                
            // Offline support
            OfflineAction.self
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
