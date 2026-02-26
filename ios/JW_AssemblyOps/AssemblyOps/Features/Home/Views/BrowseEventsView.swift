//
//  BrowseEventsView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/25/26.
//

// MARK: - Browse Events View
//
// Role-aware wrapper pushed from EventsHomeView's "+" button.
//   - Overseers → EventSetupView (embedded, no inner NavigationStack)
//   - Volunteers → VolunteerEventDiscoveryView
//
// Already inside EventsHomeView's NavigationStack, so child views
// must NOT wrap their own NavigationStack.
//

import SwiftUI

struct BrowseEventsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        if appState.isOverseer {
            EventSetupView(isEmbedded: true)
                .environmentObject(appState)
        } else {
            VolunteerEventDiscoveryView()
        }
    }
}
