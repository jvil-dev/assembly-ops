//
//  AssignmentsViewModel.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/27/25.
//


import Foundation
import SwiftUI
import Combine
import Apollo

@MainActor
final class AssignmentsViewModel: ObservableObject {
    @Published var assignments: [Assignment] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var hasLoaded: Bool = false
    
    /// Assignments grouped by date
    var groupedAssignments: [(date: Date, assignments: [Assignment])] {
        let grouped = Dictionary(grouping: assignments) { assignment in
            Calendar.current.startOfDay(for: assignment.date)
        }
        return grouped
            .map { (date: $0.key, assignments: $0.value.sorted { $0.startTime < $1.startTime }) }
            .sorted { $0.date < $1.date }
    }
    
    /// Today's assignments
    var todayAssignments: [Assignment] {
        assignments.filter { $0.isToday }
    }
    
    /// Upcoming assignments (today and future)
    var upcomingAssignments: [Assignment] {
        assignments.filter { $0.isUpcoming }
    }
    
    /// Check if there are any assignments
    var isEmpty: Bool {
        assignments.isEmpty
    }
    
    /// Fetch assignments from API
    func fetchAssignments() {
          isLoading = true
          errorMessage = nil

          NetworkClient.shared.apollo.fetch(
              query: AssemblyOpsAPI.MyAssignmentsQuery(),
              cachePolicy: .fetchIgnoringCacheData
          ) { [weak self] result in
              Task { @MainActor in
                  switch result {
                  case .success(let graphQLResult):
                      if let data = graphQLResult.data?.myAssignments {
                          self?.assignments = data.compactMap { Assignment(from: $0) }
                      } else if let errors = graphQLResult.errors, !errors.isEmpty {
                          self?.errorMessage = errors.first?.localizedDescription ?? "Failed to load assignments"
                      }
                  case .failure(let error):
                      self?.errorMessage = "Unable to connect. Pull to refresh."
                      print("Fetch assignments error: \(error)")
                  }
                  self?.isLoading = false
                  self?.hasLoaded = true
              }
          }
      }

      func refresh() {
          fetchAssignments()
      }
}

// MARK: - Apollo Fetch Extension
extension ApolloClient {
    func fetch<Query: GraphQLQuery>(
        query: Query,
        cachePolicy: CachePolicy = .default
    ) async throws -> GraphQLResult<Query.Data> {
        try await withCheckedThrowingContinuation { continuation in
            self.fetch(query: query, cachePolicy: cachePolicy) { result in
                switch result {
                case .success(let graphQLResult):
                    continuation.resume(returning: graphQLResult)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
