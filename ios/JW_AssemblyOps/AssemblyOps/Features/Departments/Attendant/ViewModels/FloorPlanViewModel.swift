//
//  FloorPlanViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 3/4/26.
//


import Foundation
import SwiftUI
import Combine

// MARK: - FloorPlanViewModel

@MainActor
final class FloorPlanViewModel: ObservableObject {
    @Published var imageUrl: URL?
    @Published var isLoading = false
    @Published var isUploading = false
    @Published var error: String?
    @Published var hasFloorPlan = false

    // MARK: - Load

    func loadFloorPlan(eventId: String) async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            if let urlString = try await FloorPlanService.shared.fetchViewUrl(eventId: eventId),
               let url = URL(string: urlString) {
                imageUrl = url
                hasFloorPlan = true
            } else {
                imageUrl = nil
                hasFloorPlan = false
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Upload

    func upload(eventId: String, imageData: Data) async {
        isUploading = true
        error = nil
        defer { isUploading = false }
        do {
            try await FloorPlanService.shared.uploadFloorPlan(eventId: eventId, imageData: imageData)
            await loadFloorPlan(eventId: eventId)  // Refresh URL after upload
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Delete

    func delete(eventId: String) async {
        error = nil
        do {
            try await FloorPlanService.shared.deleteFloorPlan(eventId: eventId)
            imageUrl = nil
            hasFloorPlan = false
        } catch {
            self.error = error.localizedDescription
        }
    }
}
