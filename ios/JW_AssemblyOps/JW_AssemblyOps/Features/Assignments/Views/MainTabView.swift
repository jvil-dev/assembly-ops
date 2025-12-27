//
//  MainTabView.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/27/25.
//


import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            Text("Assignments")
                .tabItem {
                    Label("Schedule", systemImage: "calendar")
                }
            
            Text("Profile")
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
    }
}

#Preview {
    MainTabView()
}
