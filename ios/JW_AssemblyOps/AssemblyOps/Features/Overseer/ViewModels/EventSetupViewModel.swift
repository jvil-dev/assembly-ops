//
//  EventSetupViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/31/26.
//

// MARK: - Event Setup View Model
//
// Manages event activation, joining, and department claiming for overseers.
// Used by EventSetupView, EventTemplateListView, JoinEventView.
//
// Methods:
//   - loadTemplates(): Fetch available event templates
//   - activateEvent(templateId:): Create event from template
//   - joinEvent(joinCode:): Join an existing event
//   - loadAvailableDepartments(eventId:): Fetch unclaimed departments
//   - claimDepartment(eventId:departmentType:): Claim a department
//   - completeSetup(): Mark event setup as done, load events
//

import Foundation
import Apollo
import Combine

struct EventTemplateItem: Identifiable {
    let id: String
    let eventType: String
    let circuit: String?
    let region: String
    let serviceYear: Int
    let name: String
    let theme: String?
    let themeScripture: String?
    let venue: String
    let address: String
    let startDate: String
    let endDate: String
    let language: String
    let isActivated: Bool
}

struct ActivatedEventInfo {
    let id: String
    let name: String
    let joinCode: String
    let venue: String
}

struct JoinedEventInfo {
    let eventAdminId: String
    let role: String
    let eventId: String
    let eventName: String
    let venue: String
}

@MainActor
final class EventSetupViewModel: ObservableObject {
    @Published var templates: [EventTemplateItem] = []
    @Published var isLoadingTemplates = false

    @Published var activatedEvent: ActivatedEventInfo?
    @Published var isActivating = false

    @Published var joinCode: String = ""
    @Published var joinedEvent: JoinedEventInfo?
    @Published var isJoining = false

    @Published var availableDepartments: [String] = []
    @Published var isLoadingDepartments = false
    @Published var selectedDepartmentType: String?
    @Published var isClaiming = false

    @Published var errorMessage: String?
    @Published var setupComplete = false

    private let appState = AppState.shared

    // MARK: - Templates

    var circuitAssemblyTemplates: [EventTemplateItem] {
        templates.filter { $0.eventType == "CIRCUIT_ASSEMBLY" }
    }

    var regionalConventionTemplates: [EventTemplateItem] {
        templates.filter { $0.eventType == "REGIONAL_CONVENTION" }
    }

    func loadTemplates() {
        isLoadingTemplates = true
        errorMessage = nil

        NetworkClient.shared.apollo.fetch(
            query: AssemblyOpsAPI.EventTemplatesQuery(serviceYear: .none),
            cachePolicy: .fetchIgnoringCacheData
        ) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.eventTemplates {
                        self?.templates = data.map { t in
                            EventTemplateItem(
                                id: t.id,
                                eventType: t.eventType.rawValue,
                                circuit: t.circuit,
                                region: t.region,
                                serviceYear: t.serviceYear,
                                name: t.name,
                                theme: t.theme,
                                themeScripture: t.themeScripture,
                                venue: t.venue,
                                address: t.address,
                                startDate: t.startDate,
                                endDate: t.endDate,
                                language: t.language,
                                isActivated: t.isActivated
                            )
                        }
                    }
                case .failure(let error):
                    self?.errorMessage = "Failed to load templates: \(error.localizedDescription)"
                }
                self?.isLoadingTemplates = false
            }
        }
    }

    // MARK: - Activate Event

    func activateEvent(templateId: String) {
        isActivating = true
        errorMessage = nil

        let input = AssemblyOpsAPI.ActivateEventInput(templateId: templateId)

        NetworkClient.shared.apollo.perform(
            mutation: AssemblyOpsAPI.ActivateEventMutation(input: input)
        ) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.activateEvent {
                        self?.activatedEvent = ActivatedEventInfo(
                            id: data.id,
                            name: data.name,
                            joinCode: data.joinCode,
                            venue: data.venue
                        )
                        // Load departments so App Admin can claim one after activation
                        self?.loadAvailableDepartments(eventId: data.id)
                        HapticManager.shared.success()
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        self?.errorMessage = errors.first?.localizedDescription ?? "Failed to activate event"
                        HapticManager.shared.error()
                    }
                case .failure(let error):
                    self?.errorMessage = "Unable to activate event: \(error.localizedDescription)"
                    HapticManager.shared.error()
                }
                self?.isActivating = false
            }
        }
    }

    // MARK: - Join Event

    func joinEvent() {
        let code = joinCode.trimmingCharacters(in: .whitespaces).uppercased()
        guard !code.isEmpty else { return }

        isJoining = true
        errorMessage = nil

        let input = AssemblyOpsAPI.JoinEventInput(joinCode: code)

        NetworkClient.shared.apollo.perform(
            mutation: AssemblyOpsAPI.JoinEventMutation(input: input)
        ) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.joinEvent {
                        self?.joinedEvent = JoinedEventInfo(
                            eventAdminId: data.id,
                            role: data.role.rawValue,
                            eventId: data.event.id,
                            eventName: data.event.name,
                            venue: data.event.venue
                        )
                        // Load available departments for claiming
                        self?.loadAvailableDepartments(eventId: data.event.id)
                        HapticManager.shared.success()
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        self?.errorMessage = errors.first?.localizedDescription ?? "Failed to join event"
                        HapticManager.shared.error()
                    }
                case .failure(let error):
                    self?.errorMessage = "Unable to join event: \(error.localizedDescription)"
                    HapticManager.shared.error()
                }
                self?.isJoining = false
            }
        }
    }

    // MARK: - Available Departments

    func loadAvailableDepartments(eventId: String) {
        isLoadingDepartments = true

        NetworkClient.shared.apollo.fetch(
            query: AssemblyOpsAPI.AvailableDepartmentsQuery(eventId: eventId),
            cachePolicy: .fetchIgnoringCacheData
        ) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.availableDepartments {
                        self?.availableDepartments = data.map { $0.rawValue }
                    }
                case .failure:
                    // Non-critical - they can still proceed
                    break
                }
                self?.isLoadingDepartments = false
            }
        }
    }

    // MARK: - Claim Department

    func claimDepartment(eventId: String, departmentType: String) {
        isClaiming = true
        errorMessage = nil

        let input = AssemblyOpsAPI.ClaimDepartmentInput(
            eventId: eventId,
            departmentType: GraphQLEnum(rawValue: departmentType)
        )

        NetworkClient.shared.apollo.perform(
            mutation: AssemblyOpsAPI.ClaimDepartmentMutation(input: input)
        ) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let graphQLResult):
                    if graphQLResult.data?.claimDepartment != nil {
                        HapticManager.shared.success()
                        self?.completeSetup()
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        self?.errorMessage = errors.first?.localizedDescription ?? "Failed to claim department"
                        HapticManager.shared.error()
                    }
                case .failure(let error):
                    self?.errorMessage = "Unable to claim department: \(error.localizedDescription)"
                    HapticManager.shared.error()
                }
                self?.isClaiming = false
            }
        }
    }

    // MARK: - Complete Setup

    func completeSetup() {
        appState.needsEventSetup = false
        setupComplete = true
        // Load events into session state
        Task {
            await OverseerSessionState.shared.loadEvents()
        }
    }
}
