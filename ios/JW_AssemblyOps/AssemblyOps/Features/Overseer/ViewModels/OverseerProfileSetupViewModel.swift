//
//  OverseerProfileSetupViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/31/26.
//

// MARK: - Overseer Profile Setup View Model
//
// Manages the mandatory profile completion flow for new overseers.
// Fetches circuits and congregations from seed data, validates form,
// and calls updateAdminProfile mutation to persist the profile.
//
// Properties:
//   - firstName, lastName, phone: Form fields (pre-filled from login)
//   - circuits: Available circuits from backend
//   - congregations: Congregations filtered by selected circuit
//   - selectedCircuit: Currently selected circuit
//   - selectedCongregation: Currently selected congregation
//
// Flow:
//   1. On appear: fetch circuits from backend
//   2. User selects circuit -> fetches congregations for that circuit
//   3. User selects congregation -> auto-displays circuit info
//   4. User taps Continue -> calls updateAdminProfile mutation
//   5. On success -> AppState.needsProfileSetup = false
//

import Foundation
import Apollo
import Combine

struct CircuitItem: Identifiable, Hashable {
    let id: String
    let code: String
    let region: String
    let language: String
}

struct CongregationItem: Identifiable, Hashable {
    let id: String
    let name: String
    let city: String
    let state: String
    let language: String
}

@MainActor
final class OverseerProfileSetupViewModel: ObservableObject {
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var phone: String = ""

    @Published var circuits: [CircuitItem] = []
    @Published var congregations: [CongregationItem] = []
    @Published var selectedCircuit: CircuitItem?
    @Published var selectedCongregation: CongregationItem?

    @Published var isLoadingCircuits = false
    @Published var isLoadingCongregations = false
    @Published var isSaving = false
    @Published var errorMessage: String?

    private let appState = AppState.shared

    var isFormValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty &&
        selectedCongregation != nil
    }

    /// Pre-fill form fields from current overseer info
    func prefill() {
        if let overseer = appState.currentOverseer {
            firstName = overseer.firstName
            lastName = overseer.lastName
            phone = overseer.phone ?? ""
        }
    }

    // MARK: - Fetch Circuits

    func loadCircuits() {
        isLoadingCircuits = true
        errorMessage = nil

        NetworkClient.shared.apollo.fetch(
            query: AssemblyOpsAPI.CircuitsQuery(region: .none, language: .none),
            cachePolicy: .fetchIgnoringCacheData
        ) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.circuits {
                        self?.circuits = data.map { circuit in
                            CircuitItem(
                                id: circuit.id,
                                code: circuit.code,
                                region: circuit.region,
                                language: circuit.language
                            )
                        }
                    }
                case .failure(let error):
                    self?.errorMessage = "Failed to load circuits: \(error.localizedDescription)"
                }
                self?.isLoadingCircuits = false
            }
        }
    }

    // MARK: - Fetch Congregations by Circuit

    func loadCongregations(for circuit: CircuitItem) {
        selectedCircuit = circuit
        selectedCongregation = nil
        congregations = []
        isLoadingCongregations = true

        NetworkClient.shared.apollo.fetch(
            query: AssemblyOpsAPI.CongregationsByCircuitQuery(circuitId: circuit.id),
            cachePolicy: .fetchIgnoringCacheData
        ) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.congregationsByCircuit {
                        self?.congregations = data.map { cong in
                            CongregationItem(
                                id: cong.id,
                                name: cong.name,
                                city: cong.city,
                                state: cong.state,
                                language: cong.language
                            )
                        }
                    }
                case .failure(let error):
                    self?.errorMessage = "Failed to load congregations: \(error.localizedDescription)"
                }
                self?.isLoadingCongregations = false
            }
        }
    }

    // MARK: - Save Profile

    func saveProfile() {
        guard isFormValid, let congregation = selectedCongregation else { return }

        isSaving = true
        errorMessage = nil

        let input = AssemblyOpsAPI.UpdateAdminProfileInput(
            firstName: .some(firstName.trimmingCharacters(in: .whitespaces)),
            lastName: .some(lastName.trimmingCharacters(in: .whitespaces)),
            phone: phone.isEmpty ? .none : .some(phone.trimmingCharacters(in: .whitespaces)),
            congregationId: .some(congregation.id)
        )

        NetworkClient.shared.apollo.perform(
            mutation: AssemblyOpsAPI.UpdateAdminProfileMutation(input: input)
        ) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.updateAdminProfile {
                        // Update AppState with new profile data
                        self?.appState.currentOverseer = OverseerInfo(
                            id: data.id,
                            email: data.email,
                            fullName: data.fullName,
                            firstName: data.firstName,
                            lastName: data.lastName,
                            phone: data.phone,
                            congregationId: data.congregationId,
                            circuitId: data.congregationRef?.circuit.id,
                            overseerType: self?.appState.currentOverseer?.overseerType ?? ""
                        )
                        self?.appState.needsProfileSetup = false
                        HapticManager.shared.success()
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        self?.errorMessage = errors.first?.localizedDescription ?? "Failed to save profile"
                        HapticManager.shared.error()
                    }
                case .failure(let error):
                    self?.errorMessage = "Unable to save. Please check your connection."
                    print("Profile save error: \(error)")
                    HapticManager.shared.error()
                }
                self?.isSaving = false
            }
        }
    }
}
