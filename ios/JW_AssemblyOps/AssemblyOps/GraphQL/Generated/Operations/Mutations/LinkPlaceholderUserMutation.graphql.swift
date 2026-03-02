// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class LinkPlaceholderUserMutation: GraphQLMutation {
    static let operationName: String = "LinkPlaceholderUser"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation LinkPlaceholderUser($placeholderUserId: String!, $realUserId: String!) { linkPlaceholderUser( placeholderUserId: $placeholderUserId realUserId: $realUserId ) { __typename success mergedCount message } }"#
      ))

    public var placeholderUserId: String
    public var realUserId: String

    public init(
      placeholderUserId: String,
      realUserId: String
    ) {
      self.placeholderUserId = placeholderUserId
      self.realUserId = realUserId
    }

    public var __variables: Variables? { [
      "placeholderUserId": placeholderUserId,
      "realUserId": realUserId
    ] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("linkPlaceholderUser", LinkPlaceholderUser.self, arguments: [
          "placeholderUserId": .variable("placeholderUserId"),
          "realUserId": .variable("realUserId")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        LinkPlaceholderUserMutation.Data.self
      ] }

      var linkPlaceholderUser: LinkPlaceholderUser { __data["linkPlaceholderUser"] }

      /// LinkPlaceholderUser
      ///
      /// Parent Type: `LinkPlaceholderResult`
      struct LinkPlaceholderUser: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.LinkPlaceholderResult }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("success", Bool.self),
          .field("mergedCount", Int.self),
          .field("message", String.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          LinkPlaceholderUserMutation.Data.LinkPlaceholderUser.self
        ] }

        var success: Bool { __data["success"] }
        var mergedCount: Int { __data["mergedCount"] }
        var message: String { __data["message"] }
      }
    }
  }

}