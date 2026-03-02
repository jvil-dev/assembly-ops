// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class SetOverseerModeMutation: GraphQLMutation {
    static let operationName: String = "SetOverseerMode"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation SetOverseerMode($isOverseer: Boolean!) { setOverseerMode(isOverseer: $isOverseer) { __typename id userId email firstName lastName fullName isOverseer } }"#
      ))

    public var isOverseer: Bool

    public init(isOverseer: Bool) {
      self.isOverseer = isOverseer
    }

    public var __variables: Variables? { ["isOverseer": isOverseer] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("setOverseerMode", SetOverseerMode.self, arguments: ["isOverseer": .variable("isOverseer")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        SetOverseerModeMutation.Data.self
      ] }

      var setOverseerMode: SetOverseerMode { __data["setOverseerMode"] }

      /// SetOverseerMode
      ///
      /// Parent Type: `User`
      struct SetOverseerMode: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.User }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("userId", String.self),
          .field("email", String.self),
          .field("firstName", String.self),
          .field("lastName", String.self),
          .field("fullName", String.self),
          .field("isOverseer", Bool.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          SetOverseerModeMutation.Data.SetOverseerMode.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var userId: String { __data["userId"] }
        var email: String { __data["email"] }
        var firstName: String { __data["firstName"] }
        var lastName: String { __data["lastName"] }
        var fullName: String { __data["fullName"] }
        var isOverseer: Bool { __data["isOverseer"] }
      }
    }
  }

}