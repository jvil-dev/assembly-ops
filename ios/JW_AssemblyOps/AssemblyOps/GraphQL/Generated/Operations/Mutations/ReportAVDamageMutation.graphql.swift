// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class ReportAVDamageMutation: GraphQLMutation {
    static let operationName: String = "ReportAVDamage"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation ReportAVDamage($input: ReportAVDamageInput!) { reportAVDamage(input: $input) { __typename id equipment { __typename id name category } description severity reportedBy { __typename id user { __typename firstName lastName } } session { __typename id name } createdAt } }"#
      ))

    public var input: ReportAVDamageInput

    public init(input: ReportAVDamageInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("reportAVDamage", ReportAVDamage.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        ReportAVDamageMutation.Data.self
      ] }

      var reportAVDamage: ReportAVDamage { __data["reportAVDamage"] }

      /// ReportAVDamage
      ///
      /// Parent Type: `AVDamageReport`
      struct ReportAVDamage: AssemblyOpsAPI.SelectionSet {
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
          .field("createdAt", String.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          ReportAVDamageMutation.Data.ReportAVDamage.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var equipment: Equipment { __data["equipment"] }
        var description: String { __data["description"] }
        var severity: GraphQLEnum<AssemblyOpsAPI.AVDamageSeverity> { __data["severity"] }
        var reportedBy: ReportedBy { __data["reportedBy"] }
        var session: Session? { __data["session"] }
        var createdAt: String { __data["createdAt"] }

        /// ReportAVDamage.Equipment
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
            ReportAVDamageMutation.Data.ReportAVDamage.Equipment.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
          var category: GraphQLEnum<AssemblyOpsAPI.AVEquipmentCategory> { __data["category"] }
        }

        /// ReportAVDamage.ReportedBy
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
            ReportAVDamageMutation.Data.ReportAVDamage.ReportedBy.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var user: User { __data["user"] }

          /// ReportAVDamage.ReportedBy.User
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
              ReportAVDamageMutation.Data.ReportAVDamage.ReportedBy.User.self
            ] }

            var firstName: String { __data["firstName"] }
            var lastName: String { __data["lastName"] }
          }
        }

        /// ReportAVDamage.Session
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
            ReportAVDamageMutation.Data.ReportAVDamage.Session.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
        }
      }
    }
  }

}