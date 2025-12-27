//
//  ProfileView.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/27/25.
//


import SwiftUI

struct ProfileView: View {
  @EnvironmentObject private var appState: AppState

  var body: some View {
      NavigationStack {
          List {
              // Volunteer info section
              if let volunteer = appState.currentVolunteer {
                  Section {
                      HStack(spacing: 16) {
                          Image(systemName: "person.circle.fill")
                              .font(.system(size: 50))
                              .foregroundStyle(Color("ThemeColor"))

                          VStack(alignment: .leading, spacing: 4) {
                              Text(volunteer.fullName)
                                  .font(.headline)
                              Text(volunteer.congregation)
                                  .font(.subheadline)
                                  .foregroundStyle(.secondary)
                          }
                      }
                      .padding(.vertical, 8)
                  }
              }

              // Event info
              if let eventName = appState.currentVolunteer?.eventName {
                  Section("Event") {
                      Label(eventName, systemImage: "building.2")
                  }
              }

              // Department
              if let deptName = appState.currentVolunteer?.departmentName {
                  Section("Department") {
                      Label(deptName, systemImage: "person.2")
                  }
              }

              // Logout
              Section {
                  Button(role: .destructive) {
                      appState.logout()
                  } label: {
                      HStack {
                          Spacer()
                          Text("Log Out")
                          Spacer()
                      }
                  }
              }
          }
          .navigationTitle("Profile")
      }
  }
}

#Preview {
  ProfileView()
      .environmentObject(AppState.shared)
}
