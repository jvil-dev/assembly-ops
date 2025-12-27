//
//  LaunchView.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/27/25.
//


import SwiftUI

struct LaunchView: View {
  var body: some View {
      VStack(spacing: 20) {
          Image(systemName: "person.3.fill")
              .font(.system(size: 60))
              .foregroundStyle(Color("ThemeColor"))

          Text("JW AssemblyOps")
              .font(.largeTitle)
              .fontWeight(.bold)

          Text("Volunteer Check-In")
              .font(.subheadline)
              .foregroundStyle(.secondary)

          ProgressView()
              .padding(.top, 40)
      }
      .padding()
  }
}

#Preview {
  LaunchView()
}
