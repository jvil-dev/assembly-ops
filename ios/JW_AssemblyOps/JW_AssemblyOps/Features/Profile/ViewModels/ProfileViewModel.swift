//
//  ProfileViewModel.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 1/3/26.
//

// MARK: - Profile View Model
//
// Fetches and manages volunteer profile data from GraphQL.
//
// Published Properties:
//   - volunteer: Volunteer profile data (nil until loaded)
//   - errorMessage: Error message if fetch fails
//   - hasLoaded: True after first fetch attempt completes
//
// Methods:
//   - fetchProfile(): Fetches volunteer profile from myVolunteerProfile query
//   - refresh(): Re-fetches profile data
//
// Dependencies:
//   - NetworkClient: Apollo client for GraphQL
//   - Volunteer: Profile data model
//
// Used by: ProfileView.swift

import Foundation
import SwiftUI
import Combine
import Apollo

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var volunteer: Volunteer?
    @Published var errorMessage: String?
    @Published var hasLoaded = false

    func fetchProfile() {
        errorMessage = nil

        NetworkClient.shared.apollo.fetch(
            query: AssemblyOpsAPI.MyVolunteerProfileQuery(),
            cachePolicy: .fetchIgnoringCacheData
        ) { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }

                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors, !errors.isEmpty {
                        self.errorMessage = errors.first?.localizedDescription ?? "Failed to load profile"
                    } else if let data = graphQLResult.data?.myVolunteerProfile {
                        self.volunteer = self.mapVolunteer(from: data)
                    } else {
                        self.errorMessage = "No profile data returned"
                    }
                case .failure:
                    self.errorMessage = "Unable to connect. Pull to refresh."
                }

                self.hasLoaded = true
            }
        }
    }
    
    private func mapVolunteer(from data: AssemblyOpsAPI.MyVolunteerProfileQuery.Data.MyVolunteerProfile) -> Volunteer {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return Volunteer(
            id: data.id,
            volunteerId: data.volunteerId,
            firstName: data.firstName,
            lastName: data.lastName,
            congregation: data.congregation,
            phone: data.phone,
            email: data.email,
            appointmentStatus: data.appointmentStatus?.rawValue,
            departmentId: data.department?.id,
            departmentName: data.department?.name,
            departmentType: data.department?.departmentType.rawValue,
            eventId: data.event.id,
            eventName: data.event.name,
            eventVenue: data.event.venue,
            eventAddress: data.event.address,
            eventStartDate: isoFormatter.date(from: data.event.startDate),
            eventEndDate: isoFormatter.date(from: data.event.endDate)
        )
    }
    
    func refresh() {
        fetchProfile()
    }
}
