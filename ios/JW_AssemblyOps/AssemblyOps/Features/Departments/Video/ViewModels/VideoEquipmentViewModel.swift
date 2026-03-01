//
//  VideoEquipmentViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/27/26.
//

// MARK: - Video Equipment ViewModel
//
// Manages equipment CRUD, checkout/return, and filtering for the Video crew.
// Defaults the category filter to video-relevant categories (CO-160 Ch. 4).
//
// Used by: VideoEquipmentListView, VideoEquipmentDetailView,
//          CreateVideoEquipmentSheet, BulkCreateVideoEquipmentSheet, CheckoutVideoEquipmentSheet

import Foundation
import Combine

@MainActor
final class VideoEquipmentViewModel: ObservableObject {
    @Published var equipment: [AudioEquipmentItemModel] = []
    @Published var checkouts: [AudioEquipmentCheckoutItem] = []
    @Published var selectedCategory: AudioEquipmentCategoryItem?
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var error: String?

    var filteredEquipment: [AudioEquipmentItemModel] {
        var items = equipment
        if let cat = selectedCategory {
            items = items.filter { $0.category == cat }
        }
        if !searchText.isEmpty {
            items = items.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                ($0.model?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                ($0.serialNumber?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        return items
    }

    // MARK: - Load

    func loadEquipment(eventId: String) async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            let all = try await AudioVideoService.shared.fetchEquipment(eventId: eventId)
            // Pre-filter to video-relevant categories
            equipment = all.filter { AudioEquipmentCategoryItem.videoRelevantCategories.contains($0.category) }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func loadCheckouts(eventId: String, checkedIn: Bool? = nil) async {
        do {
            checkouts = try await AudioVideoService.shared.fetchCheckouts(eventId: eventId, checkedIn: checkedIn)
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Create

    func createEquipment(eventId: String, name: String, category: String, condition: String? = nil,
                         model: String? = nil, serialNumber: String? = nil,
                         location: String? = nil, notes: String? = nil, areaId: String? = nil) async -> Bool {
        isSaving = true
        error = nil
        defer { isSaving = false }
        do {
            let item = try await AudioVideoService.shared.createEquipment(
                eventId: eventId, name: name, category: category, condition: condition,
                model: model, serialNumber: serialNumber, location: location,
                notes: notes, areaId: areaId
            )
            equipment.append(item)
            HapticManager.shared.success()
            return true
        } catch {
            self.error = error.localizedDescription
            HapticManager.shared.error()
            return false
        }
    }

    func bulkCreateEquipment(eventId: String, items: [AssemblyOpsAPI.AVEquipmentItemInput]) async -> Bool {
        isSaving = true
        error = nil
        defer { isSaving = false }
        do {
            let created = try await AudioVideoService.shared.bulkCreateEquipment(eventId: eventId, items: items)
            equipment.append(contentsOf: created)
            HapticManager.shared.success()
            return true
        } catch {
            self.error = error.localizedDescription
            HapticManager.shared.error()
            return false
        }
    }

    // MARK: - Update

    func updateEquipment(id: String, name: String? = nil, category: String? = nil, condition: String? = nil,
                         model: String? = nil, serialNumber: String? = nil,
                         location: String? = nil, notes: String? = nil, areaId: String? = nil) async -> Bool {
        isSaving = true
        error = nil
        defer { isSaving = false }
        do {
            let updated = try await AudioVideoService.shared.updateEquipment(
                id: id, name: name, category: category, condition: condition,
                model: model, serialNumber: serialNumber, location: location,
                notes: notes, areaId: areaId
            )
            if let index = equipment.firstIndex(where: { $0.id == id }) {
                equipment[index] = updated
            }
            HapticManager.shared.success()
            return true
        } catch {
            self.error = error.localizedDescription
            HapticManager.shared.error()
            return false
        }
    }

    // MARK: - Delete

    func deleteEquipment(id: String) async -> Bool {
        do {
            try await AudioVideoService.shared.deleteEquipment(id: id)
            equipment.removeAll { $0.id == id }
            HapticManager.shared.success()
            return true
        } catch {
            self.error = error.localizedDescription
            HapticManager.shared.error()
            return false
        }
    }

    // MARK: - Checkout / Return

    func checkoutEquipment(equipmentId: String, checkedOutById: String,
                           sessionId: String? = nil, notes: String? = nil) async -> Bool {
        isSaving = true
        error = nil
        defer { isSaving = false }
        do {
            let checkout = try await AudioVideoService.shared.checkoutEquipment(
                equipmentId: equipmentId, checkedOutById: checkedOutById,
                sessionId: sessionId, notes: notes
            )
            checkouts.insert(checkout, at: 0)
            HapticManager.shared.success()
            return true
        } catch {
            self.error = error.localizedDescription
            HapticManager.shared.error()
            return false
        }
    }

    func returnEquipment(checkoutId: String) async -> Bool {
        do {
            try await AudioVideoService.shared.returnEquipment(checkoutId: checkoutId)
            if let index = checkouts.firstIndex(where: { $0.id == checkoutId }) {
                checkouts.remove(at: index)
            }
            HapticManager.shared.success()
            return true
        } catch {
            self.error = error.localizedDescription
            HapticManager.shared.error()
            return false
        }
    }
}
