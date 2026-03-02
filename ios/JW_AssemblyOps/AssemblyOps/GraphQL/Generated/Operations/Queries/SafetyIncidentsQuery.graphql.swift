// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class SafetyIncidentsQuery: GraphQLQuery {
    static let operationName: String = "SafetyIncidents"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query SafetyIncidents($eventId: ID!, $resolved: Boolean) { safetyIncidents(eventId: $eventId, resolved: $resolved) { __typename id type description location post { __typename id name } reportedBy { __typename id user { __typename firstName lastName } } resolved resolvedAt resolvedBy { __typename id firstName lastName } resolutionNotes createdAt } }"#
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
        .field("safetyIncidents", [SafetyIncident].self, arguments: [
          "eventId": .variable("eventId"),
          "resolved": .variable("resolved")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        SafetyIncidentsQuery.Data.self
      ] }

      var safetyIncidents: [SafetyIncident] { __data["safetyIncidents"] }

      /// SafetyIncident
      ///
      /// Parent Type: `SafetyIncident`
      struct SafetyIncident: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.SafetyIncident }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("type", GraphQLEnum<AssemblyOpsAPI.SafetyIncidentType>.self),
          .field("description", String.self),
          .field("location", String?.self),
          .field("post", Post?.self),
          .field("reportedBy", ReportedBy.self),
          .field("resolved", Bool.self),
          .field("resolvedAt", String?.self),
          .field("resolvedBy", ResolvedBy?.self),
          .field("resolutionNotes", String?.self),
          .field("createdAt", String.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          SafetyIncidentsQuery.Data.SafetyIncident.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var type: GraphQLEnum<AssemblyOpsAPI.SafetyIncidentType> { __data["type"] }
        var description: String { __data["description"] }
        var location: String? { __data["location"] }
        var post: Post? { __data["post"] }
        var reportedBy: ReportedBy { __data["reportedBy"] }
        var resolved: Bool { __data["resolved"] }
        var resolvedAt: String? { __data["resolvedAt"] }
        var resolvedBy: ResolvedBy? { __data["resolvedBy"] }
        var resolutionNotes: String? { __data["resolutionNotes"] }
        var createdAt: String { __data["createdAt"] }

        /// SafetyIncident.Post
        ///
        /// Parent Type: `Post`
        struct Post: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Post }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("name", String.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            SafetyIncidentsQuery.Data.SafetyIncident.Post.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
        }

        /// SafetyIncident.ReportedBy
        ///
        /// Parent Type: `EventVolunteer`
        struct ReportedBy: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.EventVolunteer }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("user", User.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            SafetyIncidentsQuery.Data.SafetyIncident.ReportedBy.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var user: User { __data["user"] }

          /// SafetyIncident.ReportedBy.User
          ///
          /// Parent Type: `User`
          struct User: AssemblyOpsAPI.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.User }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("firstName", String.self),
              .field("lastName", String.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              SafetyIncidentsQuery.Data.SafetyIncident.ReportedBy.User.self
            ] }

            var firstName: String { __data["firstName"] }
            var lastName: String { __data["lastName"] }
          }
        }

        /// SafetyIncident.ResolvedBy
        ///
        /// Parent Type: `User`
        struct ResolvedBy: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.User }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("firstName", String.self),
            .field("lastName", String.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            SafetyIncidentsQuery.Data.SafetyIncident.ResolvedBy.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var firstName: String { __data["firstName"] }
          var lastName: String { __data["lastName"] }
        }
      }
    }
  }

}