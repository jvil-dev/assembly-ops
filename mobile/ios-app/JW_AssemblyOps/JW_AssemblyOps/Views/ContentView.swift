//
//  ContentView.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/21/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundStyle(.accent)
            
            Text(Constants.App.name)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(Constants.App.tagline)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Divider()
                .padding(.horizontal, 40)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
