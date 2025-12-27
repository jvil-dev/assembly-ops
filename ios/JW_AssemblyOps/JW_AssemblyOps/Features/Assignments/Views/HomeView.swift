//
//  HomeView.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/27/25.
//

import SwiftUI

struct HomeView: View {
  @EnvironmentObject private var appState: AppState

  var body: some View {
      NavigationStack {
          ScrollView {
              VStack(alignment: .leading, spacing: 20) {
                  // Event header
                  if let eventName = appState.currentVolunteer?.eventName {
                      Text(eventName)
                          .font(.title2)
                          .fontWeight(.bold)
                          .padding(.horizontal)
                  }

                  // Today's date card
                  todayCard

                  // Quick stats or upcoming assignment preview
                  // TODO: Flesh out in future sprint
              }
              .padding(.top)
          }
          .navigationTitle("Home")
      }
  }

  private var todayCard: some View {
      HStack {
          Image(systemName: "calendar")
              .foregroundStyle(Color("ThemeColor"))
          Text(Date(), style: .date)
              .font(.headline)
          Spacer()
          Image(systemName: "chevron.right")
              .foregroundStyle(.secondary)
      }
      .padding()
      .background(Color(.secondarySystemGroupedBackground))
      .clipShape(RoundedRectangle(cornerRadius: 12))
      .padding(.horizontal)
  }
}
