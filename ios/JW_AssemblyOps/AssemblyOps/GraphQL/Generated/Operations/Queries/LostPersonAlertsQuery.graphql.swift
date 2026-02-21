// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class LostPersonAlertsQuery: GraphQLQuery {
    static let operationName: String = "LostPersonAlerts"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query LostPersonAlerts($eventId: ID!, $resolved: Boolean) { lostPersonAlerts(eventId: $eventId, resolved: $resolved) { __typename id personName age description lastSeenLocation lastSeenTime contactName contactPhone reportedBy { __typename id volunteerProfile { __typename firstName lastName } } resolved resolvedAt resolvedBy { __typename id firstName lastName } resolutionNotes createdAt } }"#
      ))

    public var eventId: ID
    public var resolved: GraphQLNullable<Bool>

    public init(
      eventId: ID,
      resolved: GraphQLNullable<Bool>
    ) {
      self.eventId = eventId
      self.resolved = resolved
    }

    public var __variables: Variables? { [
      "eventId": eventId,
      "resolved": resolved
    ] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("lostPersonAlerts", [LostPersonAlert].self, arguments: [
          "eventId": .variable("eventId"),
          "resolved": .variable("resolved")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        LostPersonAlertsQuery.Data.self
      ] }

      var lostPersonAlerts: [LostPersonAlert] { __data["lostPersonAlerts"] }

      /// LostPersonAlert
      ///
      /// Parent Type: `LostPersonAlert`
      struct LostPersonAlert: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.LostPersonAlert }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("personName", String.self),
          .field("age", Int?.self),
          .field("description", String.self),
          .field("lastSeenLocation", String?.self),
          .field("lastSeenTime", String?.self),
          .field("contactName", String.self),
          .field("contactPhone", String?.self),
          .field("reportedBy", ReportedBy.self),
          .field("resolved", Bool.self),
          .field("resolvedAt", String?.self),
          .field("resolvedBy", ResolvedBy?.self),
          .field("resolutionNotes", String?.self),
          .field("createdAt", String.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          LostPersonAlertsQuery.Data.LostPersonAlert.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var personName: String { __data["personName"] }
        var age: Int? { __data["age"] }
        var description: String { __data["description"] }
        var lastSeenLocation: String? { __data["lastSeenLocation"] }
        var lastSeenTime: String? { __data["lastSeenTime"] }
        var contactName: String { __data["contactName"] }
        var contactPhone: String? { __data["contactPhone"] }
        var reportedBy: ReportedBy { __data["reportedBy"] }
        var resolved: Bool { __data["resolved"] }
        var resolvedAt: String? { __data["resolvedAt"] }
        var resolvedBy: ResolvedBy? { __data["resolvedBy"] }
        var resolutionNotes: String? { __data["resolutionNotes"] }
        var createdAt: String { __data["createdAt"] }

        /// LostPersonAlert.ReportedBy
        ///
        /// Parent Type: `EventVolunteer`
        struct ReportedBy: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.EventVolunteer }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("volunteerProfile", VolunteerProfile.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            LostPersonAlertsQuery.Data.LostPersonAlert.ReportedBy.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var volunteerProfile: VolunteerProfile { __data["volunteerProfile"] }

          /// LostPersonAlert.ReportedBy.VolunteerProfile
          ///
          /// Parent Type: `VolunteerProfile`
          struct VolunteerProfile: AssemblyOpsAPI.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.VolunteerProfile }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("firstName", String.self),
              .field("lastName", String.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              LostPersonAlertsQuery.Data.LostPersonAlert.ReportedBy.VolunteerProfile.self
            ] }

            var firstName: String { __data["firstName"] }
            var lastName: String { __data["lastName"] }
          }
        }

        /// LostPersonAlert.ResolvedBy
        ///
        /// Parent Type: `Admin`
        struct ResolvedBy: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Admin }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("firstName", String.self),
            .field("lastName", String.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            LostPersonAlertsQuery.Data.LostPersonAlert.ResolvedBy.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var firstName: String { __data["firstName"] }
          var lastName: String { __data["lastName"] }
        }
      }
    }
  }

}