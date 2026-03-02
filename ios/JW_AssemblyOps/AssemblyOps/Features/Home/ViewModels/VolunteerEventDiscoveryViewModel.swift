//
//  VolunteerEventDiscoveryViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/24/26.
//

// MARK: - Volunteer Event Discovery View Model
//
// Loads publicly visible events and handles join requests.
// Also supports joining a department directly via access code.
// Used by VolunteerEventDiscoveryView.
//
// Methods:
//   - loadEvents(): Fetch public events from discoverEvents query
//   - requestToJoin(eventId:departmentType:note:): Submit join request
//   - joinByAccessCode(code:): Join department directly via access code
//

import Foundation
import Combine
import Apollo

struct EventDepartmentInfo: Identifiable, Hashable {
    let id: String
    let name: String
    let departmentType: String
    let volunteerCount: Int
}

struct DiscoverableEvent: Identifiable, Hashable {
    let id: String
    let name: String
    let eventType: String
    let circuit: String?
    let state: String?
    let venue: String
    let address: String
    let startDate: String
    let endDate: String
    let theme: String?
    let isPublic: Bool
    let volunteerCount: Int
    let departments: [EventDepartmentInfo]

    var isInviteOnly: Bool {
        eventType == "REGIONAL_CONVENTION" || eventType == "SPECIAL_CONVENTION"
    }

    var displayEventType: String {
        switch eventType {
        case "CIRCUIT_ASSEMBLY_CO": return "Circuit Assembly"
        case "CIRCUIT_ASSEMBLY_BR": return "Circuit Assembly"
        case "REGIONAL_CONVENTION": return "Regional Convention"
        case "SPECIAL_CONVENTION": return "Special Convention"
        default: return eventType
        }
    }
}

@MainActor
final class VolunteerEventDiscoveryViewModel: ObservableObject {
    @Published var events: [DiscoverableEvent] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Tracks pending requests by eventId
    @Published var pendingRequestIds: Set<String> = []
    @Published var sentRequestIds: Set<String> = []

    // Expand / department selection state
    @Published var expandedEventId: String?
    @Published var selectedDepartmentType: String?
    @Published var joinNote: String = ""

    // Access code join state
    @Published var isJoiningByCode = false
    @Published var accessCodeResult: AccessCodeJoinResult?

    struct AccessCodeJoinResult: Identifiable {
        let id = UUID()
    }

    // MARK: - Sectioned Event Lists

    @Published var conventionSearchText = ""

    var circuitAssemblies: [DiscoverableEvent] {
        events.filter { $0.eventType.hasPrefix("CIRCUIT_ASSEMBLY") }
    }

    var conventions: [DiscoverableEvent] {
        events.filter { $0.eventType == "REGIONAL_CONVENTION" || $0.eventType == "SPECIAL_CONVENTION" }
    }

    var filteredConventions: [DiscoverableEvent] {
        guard !conventionSearchText.isEmpty else { return conventions }
        let query = conventionSearchText.lowercased()
        return conventions.filter {
            $0.venue.lowercased().contains(query) ||
            $0.address.lowercased().contains(query) ||
            ($0.state?.lowercased().contains(query) ?? false) ||
            $0.name.lowercased().contains(query) ||
            Self.formattedDateRange($0.startDate, $0.endDate).lowercased().contains(query)
        }
    }

    private static func formattedDateRange(_ start: String, _ end: String) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM d, yyyy"
        let startStr = DateUtils.parseISO8601(start).map { fmt.string(from: $0) } ?? start
        let endStr = DateUtils.parseISO8601(end).map { fmt.string(from: $0) } ?? end
        return "\(startStr) \(endStr)"
    }

    // MARK: - Expand / Collapse

    func toggleExpand(eventId: String) {
        if expandedEventId == eventId {
            expandedEventId = nil
            selectedDepartmentType = nil
            joinNote = ""
        } else {
            expandedEventId = eventId
            selectedDepartmentType = nil
            joinNote = ""
        }
    }

    // MARK: - Network

    func loadEvents() {
        isLoading = true
        errorMessage = nil

        let circuitCodeFilter: GraphQLNullable<String> = AppState.shared.currentUser?.circuitCode.map { .some($0) } ?? .none

        NetworkClient.shared.apollo.fetch(
            query: AssemblyOpsAPI.DiscoverEventsQuery(
                eventType: .none,
                state: .none,
                language: .none,
                circuitCode: circuitCodeFilter
            ),
            cachePolicy: .fetchIgnoringCacheData
        ) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.discoverEvents {
                        self?.events = data.map { e in
                            DiscoverableEvent(
                                id: e.id,
                                name: e.name,
                                eventType: e.eventType.rawValue,
                                circuit: e.circuit,
                                state: e.state,
                                venue: e.venue,
                                address: e.address,
                                startDate: e.startDate,
                                endDate: e.endDate,
                                theme: e.theme,
                                isPublic: e.isPublic,
                                volunteerCount: e.volunteerCount,
                                departments: e.departments.map { d in
                                    EventDepartmentInfo(
                                        id: d.id,
                                        name: d.name,
                                        departmentType: d.departmentType.rawValue,
                                        volunteerCount: d.volunteerCount
                                    )
                                }
                            )
                        }
                    }
                case .failure(let error):
                    self?.errorMessage = "Failed to load events: \(error.localizedDescription)"
                }
                self?.isLoading = false
            }
        }
    }

    func requestToJoin(eventId: String, departmentType: String? = nil, note: String? = nil) {
        guard !pendingRequestIds.contains(eventId) else { return }
        pendingRequestIds.insert(eventId)

        let deptEnum: GraphQLNullable<GraphQLEnum<AssemblyOpsAPI.DepartmentType>>
        if let dt = departmentType {
            deptEnum = .some(GraphQLEnum(rawValue: dt))
        } else {
            deptEnum = .none
        }

        let noteValue: GraphQLNullable<String> = note.map { .some($0) } ?? .none

        NetworkClient.shared.apollo.perform(
            mutation: AssemblyOpsAPI.RequestToJoinEventMutation(
                eventId: eventId,
                departmentType: deptEnum,
                note: noteValue
            )
        ) { [weak self] result in
            Task { @MainActor in
                self?.pendingRequestIds.remove(eventId)
                switch result {
                case .success(let graphQLResult):
                    if graphQLResult.data?.requestToJoinEvent != nil {
                        self?.sentRequestIds.insert(eventId)
                        self?.expandedEventId = nil
                        self?.selectedDepartmentType = nil
                        self?.joinNote = ""
                        HapticManager.shared.success()
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        self?.errorMessage = errors.first?.message ?? "Request failed"
                        HapticManager.shared.error()
                    }
                case .failure:
                    self?.errorMessage = "Unable to send request. Please try again."
                    HapticManager.shared.error()
                }
            }
        }
    }

    func joinByAccessCode(code: String) {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !trimmed.isEmpty else {
            errorMessage = "volunteerDiscovery.accessCode.empty".localized
            return
        }

        isJoiningByCode = true
        errorMessage = nil

        let input = AssemblyOpsAPI.JoinDepartmentByCodeInput(accessCode: trimmed)

        NetworkClient.shared.apollo.perform(
            mutation: AssemblyOpsAPI.JoinDepartmentByCodeMutation(input: input)
        ) { [weak self] result in
            Task { @MainActor in
                self?.isJoiningByCode = false
                switch result {
                case .success(let graphQLResult):
                    if graphQLResult.data?.joinDepartmentByAccessCode != nil {
                        self?.accessCodeResult = AccessCodeJoinResult()
                        HapticManager.shared.success()
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        self?.errorMessage = errors.first?.message ?? "volunteerDiscovery.accessCode.failed".localized
                        HapticManager.shared.error()
                    }
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    HapticManager.shared.error()
                }
            }
        }
    }
}
