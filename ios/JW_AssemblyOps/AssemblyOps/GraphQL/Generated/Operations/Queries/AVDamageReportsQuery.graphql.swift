// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class AVDamageReportsQuery: GraphQLQuery {
    static let operationName: String = "AVDamageReports"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query AVDamageReports($eventId: ID!, $resolved: Boolean) { avDamageReports(eventId: $eventId, resolved: $resolved) { __typename id equipment { __typename id name category } description severity reportedBy { __typename id user { __typename firstName lastName } } session { __typename id name } resolved resolvedAt resolvedBy { __typename id firstName lastName } resolutionNotes createdAt } }"#
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
        .field("avDamageReports", [AvDamageReport].self, arguments: [
          "eventId": .variable("eventId"),
          "resolved": .variable("resolved")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        AVDamageReportsQuery.Data.self
      ] }

      var avDamageReports: [AvDamageReport] { __data["avDamageReports"] }

      /// AvDamageReport
      ///
      /// Parent Type: `AVDamageReport`
      struct AvDamageReport: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.AVDamageReport }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("equipment", Equipment.self),
          .field("description", String.self),
          .field("severity", GraphQLEnum<AssemblyOpsAPI.AVDamageSeverity>.self),
          .field("reportedBy", ReportedBy.self),
          .field("session", Session?.self),
          .field("resolved", Bool.self),
          .field("resolvedAt", String?.self),
          .field("resolvedBy", ResolvedBy?.self),
          .field("resolutionNotes", String?.self),
          .field("createdAt", String.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          AVDamageReportsQuery.Data.AvDamageReport.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var equipment: Equipment { __data["equipment"] }
        var description: String { __data["description"] }
        var severity: GraphQLEnum<AssemblyOpsAPI.AVDamageSeverity> { __data["severity"] }
        var reportedBy: ReportedBy { __data["reportedBy"] }
        var session: Session? { __data["session"] }
        var resolved: Bool { __data["resolved"] }
        var resolvedAt: String? { __data["resolvedAt"] }
        var resolvedBy: ResolvedBy? { __data["resolvedBy"] }
        var resolutionNotes: String? { __data["resolutionNotes"] }
        var createdAt: String { __data["createdAt"] }

        /// AvDamageReport.Equipment
        ///
        /// Parent Type: `AVEquipmentItem`
        struct Equipment: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.AVEquipmentItem }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("name", String.self),
            .field("category", GraphQLEnum<AssemblyOpsAPI.AVEquipmentCategory>.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            AVDamageReportsQuery.Data.AvDamageReport.Equipment.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
          var category: GraphQLEnum<AssemblyOpsAPI.AVEquipmentCategory> { __data["category"] }
        }

        /// AvDamageReport.ReportedBy
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
            AVDamageReportsQuery.Data.AvDamageReport.ReportedBy.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var user: User { __data["user"] }

          /// AvDamageReport.ReportedBy.User
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
              AVDamageReportsQuery.Data.AvDamageReport.ReportedBy.User.self
            ] }

            var firstName: String { __data["firstName"] }
            var lastName: String { __data["lastName"] }
          }
        }

        /// AvDamageReport.Session
        ///
        /// Parent Type: `Session`
        struct Session: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Session }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("name", String.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            AVDamageReportsQuery.Data.AvDamageReport.Session.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
        }

        /// AvDamageReport.ResolvedBy
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
            AVDamageReportsQuery.Data.AvDamageReport.ResolvedBy.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var firstName: String { __data["firstName"] }
          var lastName: String { __data["lastName"] }
        }
      }
    }
  }

}