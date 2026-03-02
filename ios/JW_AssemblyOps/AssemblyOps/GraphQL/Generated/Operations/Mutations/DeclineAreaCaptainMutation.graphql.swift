// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class DeclineAreaCaptainMutation: GraphQLMutation {
    static let operationName: String = "DeclineAreaCaptain"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation DeclineAreaCaptain($input: DeclineAreaCaptainInput!) { declineAreaCaptain(input: $input) { __typename id status respondedAt declineReason area { __typename id name } session { __typename id name } } }"#
      ))

    public var input: DeclineAreaCaptainInput

    public init(input: DeclineAreaCaptainInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("declineAreaCaptain", DeclineAreaCaptain.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        DeclineAreaCaptainMutation.Data.self
      ] }

      var declineAreaCaptain: DeclineAreaCaptain { __data["declineAreaCaptain"] }

      /// DeclineAreaCaptain
      ///
      /// Parent Type: `AreaCaptainAssignment`
      struct DeclineAreaCaptain: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.AreaCaptainAssignment }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("status", GraphQLEnum<AssemblyOpsAPI.AssignmentStatus>.self),
          .field("respondedAt", AssemblyOpsAPI.DateTime?.self),
          .field("declineReason", String?.self),
          .field("area", Area.self),
          .field("session", Session.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          DeclineAreaCaptainMutation.Data.DeclineAreaCaptain.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var status: GraphQLEnum<AssemblyOpsAPI.AssignmentStatus> { __data["status"] }
        var respondedAt: AssemblyOpsAPI.DateTime? { __data["respondedAt"] }
        var declineReason: String? { __data["declineReason"] }
        var area: Area { __data["area"] }
        var session: Session { __data["session"] }

        /// DeclineAreaCaptain.Area
        ///
        /// Parent Type: `Area`
        struct Area: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Area }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("name", String.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            DeclineAreaCaptainMutation.Data.DeclineAreaCaptain.Area.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
        }

        /// DeclineAreaCaptain.Session
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
            DeclineAreaCaptainMutation.Data.DeclineAreaCaptain.Session.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
        }
      }
    }
  }

}