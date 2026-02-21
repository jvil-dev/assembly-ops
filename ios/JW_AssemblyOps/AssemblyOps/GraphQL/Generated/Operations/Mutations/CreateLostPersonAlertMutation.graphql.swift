// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class CreateLostPersonAlertMutation: GraphQLMutation {
    static let operationName: String = "CreateLostPersonAlert"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation CreateLostPersonAlert($input: CreateLostPersonAlertInput!) { createLostPersonAlert(input: $input) { __typename id personName age description lastSeenLocation lastSeenTime contactName contactPhone createdAt } }"#
      ))

    public var input: CreateLostPersonAlertInput

    public init(input: CreateLostPersonAlertInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("createLostPersonAlert", CreateLostPersonAlert.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CreateLostPersonAlertMutation.Data.self
      ] }

      var createLostPersonAlert: CreateLostPersonAlert { __data["createLostPersonAlert"] }

      /// CreateLostPersonAlert
      ///
      /// Parent Type: `LostPersonAlert`
      struct CreateLostPersonAlert: AssemblyOpsAPI.SelectionSet {
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
          .field("createdAt", String.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          CreateLostPersonAlertMutation.Data.CreateLostPersonAlert.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var personName: String { __data["personName"] }
        var age: Int? { __data["age"] }
        var description: String { __data["description"] }
        var lastSeenLocation: String? { __data["lastSeenLocation"] }
        var lastSeenTime: String? { __data["lastSeenTime"] }
        var contactName: String { __data["contactName"] }
        var contactPhone: String? { __data["contactPhone"] }
        var createdAt: String { __data["createdAt"] }
      }
    }
  }

}