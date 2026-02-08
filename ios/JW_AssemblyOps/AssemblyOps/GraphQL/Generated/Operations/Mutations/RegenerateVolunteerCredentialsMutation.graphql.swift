// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class RegenerateVolunteerCredentialsMutation: GraphQLMutation {
    static let operationName: String = "RegenerateVolunteerCredentials"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation RegenerateVolunteerCredentials($id: ID!) { regenerateVolunteerCredentials(id: $id) { __typename volunteerId token } }"#
      ))

    public var id: ID

    public init(id: ID) {
      self.id = id
    }

    public var __variables: Variables? { ["id": id] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("regenerateVolunteerCredentials", RegenerateVolunteerCredentials.self, arguments: ["id": .variable("id")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        RegenerateVolunteerCredentialsMutation.Data.self
      ] }

      var regenerateVolunteerCredentials: RegenerateVolunteerCredentials { __data["regenerateVolunteerCredentials"] }

      /// RegenerateVolunteerCredentials
      ///
      /// Parent Type: `VolunteerCredentials`
      struct RegenerateVolunteerCredentials: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.VolunteerCredentials }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("volunteerId", String.self),
          .field("token", String.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          RegenerateVolunteerCredentialsMutation.Data.RegenerateVolunteerCredentials.self
        ] }

        var volunteerId: String { __data["volunteerId"] }
        var token: String { __data["token"] }
      }
    }
  }

}