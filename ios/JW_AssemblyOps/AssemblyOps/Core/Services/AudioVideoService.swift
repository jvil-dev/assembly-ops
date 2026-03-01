//
//  AudioVideoService.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/27/26.
//

// MARK: - Audio/Video Service
//
// Handles all Audio department GraphQL API calls.
// Manages equipment, checkouts, damage reports, hazard assessments,
// and safety briefings.
//
// Methods:
//   Equipment:
//   - fetchEquipment(eventId:category:areaId:): Equipment list with filters
//   - fetchEquipmentItem(id:): Single item with checkout history + damage reports
//   - fetchEquipmentSummary(eventId:): Dashboard aggregate stats
//   - createEquipment(...): Create a single equipment item
//   - bulkCreateEquipment(eventId:items:): Batch create equipment
//   - updateEquipment(id:input:): Patch-update equipment fields
//   - deleteEquipment(id:): Delete equipment item
//
//   Checkouts:
//   - fetchCheckouts(eventId:checkedIn:): Checkout list with filter
//   - checkoutEquipment(...): Check out equipment to a volunteer
//   - returnEquipment(checkoutId:): Return checked-out equipment
//
//   Damage:
//   - fetchDamageReports(eventId:resolved:): Damage reports with filter
//   - reportDamage(...): Report equipment damage
//   - resolveDamage(id:resolutionNotes:): Mark damage resolved
//
//   Hazards:
//   - fetchHazardAssessments(eventId:): All hazard assessments
//   - createHazardAssessment(...): Create new hazard assessment
//   - deleteHazardAssessment(id:): Delete hazard assessment
//
//   Briefings:
//   - fetchSafetyBriefings(eventId:): All safety briefings with attendees
//   - fetchMySafetyBriefings(eventId:): Current volunteer's briefings
//   - createSafetyBriefing(...): Create safety briefing
//   - updateSafetyBriefingNotes(id:notes:): Update briefing notes
//   - deleteSafetyBriefing(id:): Delete safety briefing
//
// Dependencies:
//   - NetworkClient: Apollo client for GraphQL

import Foundation
import Apollo

enum AudioVideoError: LocalizedError {
    case networkError(String)
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .networkError(let message): return "Network error: \(message)"
        case .serverError(let message): return message
        }
    }
}

/// Service for Audio/Video department operations
final class AudioVideoService {
    static let shared = AudioVideoService()

    private init() {}

    // MARK: - Equipment

    /// Fetch equipment list for an event with optional filters
    func fetchEquipment(eventId: String, category: String? = nil, areaId: String? = nil) async throws -> [AudioEquipmentItemModel] {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.AVEquipmentQuery(
                    eventId: eventId,
                    category: category.map { .some(.init(rawValue: $0)) } ?? .none,
                    areaId: areaId.map { .some($0) } ?? .none
                ),
                cachePolicy: .fetchIgnoringCacheData
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.avEquipment {
                        let items = data.compactMap { AudioEquipmentItemModel(from: $0) }
                        continuation.resume(returning: items)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AudioVideoError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(returning: [])
                    }
                case .failure(let error):
                    continuation.resume(throwing: AudioVideoError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Fetch a single equipment item with checkout history and damage reports
    func fetchEquipmentItem(id: String) async throws -> AssemblyOpsAPI.AVEquipmentItemQuery.Data.AvEquipmentItem? {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.AVEquipmentItemQuery(id: id),
                cachePolicy: .fetchIgnoringCacheData
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AudioVideoError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(returning: graphQLResult.data?.avEquipmentItem)
                    }
                case .failure(let error):
                    continuation.resume(throwing: AudioVideoError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Fetch equipment summary stats for dashboard
    func fetchEquipmentSummary(eventId: String) async throws -> AudioEquipmentSummaryItem? {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.AVEquipmentSummaryQuery(eventId: eventId),
                cachePolicy: .fetchIgnoringCacheData
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.avEquipmentSummary {
                        continuation.resume(returning: AudioEquipmentSummaryItem(from: data))
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AudioVideoError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(returning: nil)
                    }
                case .failure(let error):
                    continuation.resume(throwing: AudioVideoError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Create a single equipment item
    func createEquipment(eventId: String, name: String, category: String, condition: String? = nil,
                         model: String? = nil, serialNumber: String? = nil,
                         location: String? = nil, notes: String? = nil, areaId: String? = nil) async throws -> AudioEquipmentItemModel {
        let input = AssemblyOpsAPI.CreateAVEquipmentInput(
            eventId: eventId,
            name: name,
            category: .init(rawValue: category),
            condition: condition.map { .some(.init(rawValue: $0)) } ?? .none,
            model: model.map { .some($0) } ?? .none,
            serialNumber: serialNumber.map { .some($0) } ?? .none,
            location: location.map { .some($0) } ?? .none,
            notes: notes.map { .some($0) } ?? .none,
            areaId: areaId.map { .some($0) } ?? .none
        )
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.CreateAVEquipmentMutation(input: input)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.createAVEquipment,
                       let item = AudioEquipmentItemModel(fromCreate: data) {
                        continuation.resume(returning: item)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AudioVideoError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(throwing: AudioVideoError.serverError("Failed to create equipment"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: AudioVideoError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Bulk create equipment items
    func bulkCreateEquipment(eventId: String, items: [AssemblyOpsAPI.AVEquipmentItemInput]) async throws -> [AudioEquipmentItemModel] {
        let input = AssemblyOpsAPI.BulkCreateAVEquipmentInput(
            eventId: eventId,
            items: items
        )
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.BulkCreateAVEquipmentMutation(input: input)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.bulkCreateAVEquipment {
                        let items = data.compactMap { AudioEquipmentItemModel(fromBulk: $0) }
                        continuation.resume(returning: items)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AudioVideoError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(returning: [])
                    }
                case .failure(let error):
                    continuation.resume(throwing: AudioVideoError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Update an equipment item (patch-style)
    func updateEquipment(id: String, name: String? = nil, category: String? = nil, condition: String? = nil,
                         model: String? = nil, serialNumber: String? = nil,
                         location: String? = nil, notes: String? = nil, areaId: String? = nil) async throws -> AudioEquipmentItemModel {
        let input = AssemblyOpsAPI.UpdateAVEquipmentInput(
            name: name.map { .some($0) } ?? .none,
            category: category.map { .some(.init(rawValue: $0)) } ?? .none,
            condition: condition.map { .some(.init(rawValue: $0)) } ?? .none,
            model: model.map { .some($0) } ?? .none,
            serialNumber: serialNumber.map { .some($0) } ?? .none,
            location: location.map { .some($0) } ?? .none,
            notes: notes.map { .some($0) } ?? .none,
            areaId: areaId.map { .some($0) } ?? .none
        )
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.UpdateAVEquipmentMutation(id: id, input: input)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.updateAVEquipment,
                       let item = AudioEquipmentItemModel(fromUpdate: data) {
                        continuation.resume(returning: item)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AudioVideoError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(throwing: AudioVideoError.serverError("Failed to update equipment"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: AudioVideoError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Delete an equipment item
    func deleteEquipment(id: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.DeleteAVEquipmentMutation(id: id)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if graphQLResult.data?.deleteAVEquipment != nil {
                        continuation.resume()
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AudioVideoError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(throwing: AudioVideoError.serverError("Failed to delete equipment"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: AudioVideoError.networkError(error.localizedDescription))
                }
            }
        }
    }

    // MARK: - Checkouts

    /// Fetch equipment checkouts for an event
    func fetchCheckouts(eventId: String, checkedIn: Bool? = nil) async throws -> [AudioEquipmentCheckoutItem] {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.AVEquipmentCheckoutsQuery(
                    eventId: eventId,
                    checkedIn: checkedIn.map { .some($0) } ?? .none
                ),
                cachePolicy: .fetchIgnoringCacheData
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.avEquipmentCheckouts {
                        let checkouts = data.map { AudioEquipmentCheckoutItem(fromList: $0) }
                        continuation.resume(returning: checkouts)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AudioVideoError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(returning: [])
                    }
                case .failure(let error):
                    continuation.resume(throwing: AudioVideoError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Check out equipment to a volunteer
    func checkoutEquipment(equipmentId: String, checkedOutById: String, sessionId: String? = nil, notes: String? = nil) async throws -> AudioEquipmentCheckoutItem {
        let input = AssemblyOpsAPI.CheckoutEquipmentInput(
            equipmentId: equipmentId,
            checkedOutById: checkedOutById,
            sessionId: sessionId.map { .some($0) } ?? .none,
            notes: notes.map { .some($0) } ?? .none
        )
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.CheckoutEquipmentMutation(input: input)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.checkoutEquipment {
                        let item = AudioEquipmentCheckoutItem(fromCheckout: data)
                        continuation.resume(returning: item)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AudioVideoError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(throwing: AudioVideoError.serverError("Failed to checkout equipment"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: AudioVideoError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Return checked-out equipment
    func returnEquipment(checkoutId: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.ReturnEquipmentMutation(checkoutId: checkoutId)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if graphQLResult.data?.returnEquipment != nil {
                        continuation.resume()
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AudioVideoError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(throwing: AudioVideoError.serverError("Failed to return equipment"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: AudioVideoError.networkError(error.localizedDescription))
                }
            }
        }
    }

    // MARK: - Damage Reports

    /// Fetch damage reports for an event
    func fetchDamageReports(eventId: String, resolved: Bool? = nil) async throws -> [AudioDamageReportItem] {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.AVDamageReportsQuery(
                    eventId: eventId,
                    resolved: resolved.map { .some($0) } ?? .none
                ),
                cachePolicy: .fetchIgnoringCacheData
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.avDamageReports {
                        let reports = data.compactMap { AudioDamageReportItem(from: $0) }
                        continuation.resume(returning: reports)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AudioVideoError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(returning: [])
                    }
                case .failure(let error):
                    continuation.resume(throwing: AudioVideoError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Report equipment damage
    func reportDamage(equipmentId: String, description: String, severity: String, sessionId: String? = nil) async throws -> AudioDamageReportItem {
        let input = AssemblyOpsAPI.ReportAVDamageInput(
            equipmentId: equipmentId,
            description: description,
            severity: .init(rawValue: severity),
            sessionId: sessionId.map { .some($0) } ?? .none
        )
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.ReportAVDamageMutation(input: input)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.reportAVDamage,
                       let item = AudioDamageReportItem(fromReport: data) {
                        continuation.resume(returning: item)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AudioVideoError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(throwing: AudioVideoError.serverError("Failed to report damage"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: AudioVideoError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Resolve a damage report
    func resolveDamage(id: String, resolutionNotes: String? = nil) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.ResolveAVDamageMutation(
                    id: id,
                    resolutionNotes: resolutionNotes.map { .some($0) } ?? .none
                )
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if graphQLResult.data?.resolveAVDamage != nil {
                        continuation.resume()
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AudioVideoError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(throwing: AudioVideoError.serverError("Failed to resolve damage report"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: AudioVideoError.networkError(error.localizedDescription))
                }
            }
        }
    }

    // MARK: - Hazard Assessments

    /// Fetch hazard assessments for an event
    func fetchHazardAssessments(eventId: String) async throws -> [AudioHazardAssessmentItem] {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.AVHazardAssessmentsQuery(eventId: eventId),
                cachePolicy: .fetchIgnoringCacheData
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.avHazardAssessments {
                        let assessments = data.compactMap { AudioHazardAssessmentItem(from: $0) }
                        continuation.resume(returning: assessments)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AudioVideoError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(returning: [])
                    }
                case .failure(let error):
                    continuation.resume(throwing: AudioVideoError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Create a hazard assessment
    func createHazardAssessment(eventId: String, title: String, hazardType: String,
                                description: String, controls: String,
                                ppeRequired: [String], sessionId: String? = nil) async throws -> AudioHazardAssessmentItem {
        let input = AssemblyOpsAPI.CreateAVHazardAssessmentInput(
            eventId: eventId,
            title: title,
            hazardType: .init(rawValue: hazardType),
            description: description,
            controls: controls,
            ppeRequired: ppeRequired,
            sessionId: sessionId.map { .some($0) } ?? .none
        )
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.CreateAVHazardAssessmentMutation(input: input)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.createAVHazardAssessment,
                       let item = AudioHazardAssessmentItem(fromCreate: data) {
                        continuation.resume(returning: item)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AudioVideoError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(throwing: AudioVideoError.serverError("Failed to create hazard assessment"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: AudioVideoError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Delete a hazard assessment
    func deleteHazardAssessment(id: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.DeleteAVHazardAssessmentMutation(id: id)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if graphQLResult.data?.deleteAVHazardAssessment != nil {
                        continuation.resume()
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AudioVideoError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(throwing: AudioVideoError.serverError("Failed to delete hazard assessment"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: AudioVideoError.networkError(error.localizedDescription))
                }
            }
        }
    }

    // MARK: - Safety Briefings

    /// Fetch all safety briefings for an event
    func fetchSafetyBriefings(eventId: String) async throws -> [AudioSafetyBriefingItem] {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.AVSafetyBriefingsQuery(eventId: eventId),
                cachePolicy: .fetchIgnoringCacheData
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.avSafetyBriefings {
                        let briefings = data.map { AudioSafetyBriefingItem(from: $0) }
                        continuation.resume(returning: briefings)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AudioVideoError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(returning: [])
                    }
                case .failure(let error):
                    continuation.resume(throwing: AudioVideoError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Fetch safety briefings the current volunteer attended
    func fetchMySafetyBriefings(eventId: String) async throws -> [AudioSafetyBriefingItem] {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.MyAVSafetyBriefingsQuery(eventId: eventId),
                cachePolicy: .fetchIgnoringCacheData
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.myAVSafetyBriefings {
                        let briefings = data.map { AudioSafetyBriefingItem(fromMy: $0) }
                        continuation.resume(returning: briefings)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AudioVideoError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(returning: [])
                    }
                case .failure(let error):
                    continuation.resume(throwing: AudioVideoError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Create a safety briefing
    func createSafetyBriefing(eventId: String, topic: String, notes: String? = nil, attendeeIds: [String]) async throws -> AudioSafetyBriefingItem {
        let input = AssemblyOpsAPI.CreateAVSafetyBriefingInput(
            eventId: eventId,
            topic: topic,
            notes: notes.map { .some($0) } ?? .none,
            attendeeIds: attendeeIds
        )
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.CreateAVSafetyBriefingMutation(input: input)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.createAVSafetyBriefing {
                        let item = AudioSafetyBriefingItem(fromCreate: data)
                        continuation.resume(returning: item)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AudioVideoError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(throwing: AudioVideoError.serverError("Failed to create safety briefing"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: AudioVideoError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Update safety briefing notes
    func updateSafetyBriefingNotes(id: String, notes: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.UpdateAVSafetyBriefingNotesMutation(id: id, notes: notes)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if graphQLResult.data?.updateAVSafetyBriefingNotes != nil {
                        continuation.resume()
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AudioVideoError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(throwing: AudioVideoError.serverError("Failed to update briefing notes"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: AudioVideoError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Delete a safety briefing
    func deleteSafetyBriefing(id: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.DeleteAVSafetyBriefingMutation(id: id)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if graphQLResult.data?.deleteAVSafetyBriefing != nil {
                        continuation.resume()
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AudioVideoError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(throwing: AudioVideoError.serverError("Failed to delete safety briefing"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: AudioVideoError.networkError(error.localizedDescription))
                }
            }
        }
    }
}
