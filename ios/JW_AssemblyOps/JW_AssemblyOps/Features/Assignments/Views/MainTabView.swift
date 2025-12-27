//
//  MainTabView.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/27/25.
//

import SwiftUI

  struct MainTabView: View {
      @EnvironmentObject private var appState: AppState

      var body: some View {
          TabView {
              HomeView()
                  .tabItem {
                      Label("Home", systemImage: "house")
                  }

              AssignmentsListView()
                  .tabItem {
                      Label("Schedule", systemImage: "calendar")
                  }

              MessagesView()
                  .tabItem {
                      Label("Messages", systemImage: "envelope")
                  }

              ProfileView()
                  .tabItem {
                      Label("Profile", systemImage: "person")
                  }
          }
      }
  }

#Preview {
    MainTabView()
}
