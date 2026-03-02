// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class UpdateMyProfileMutation: GraphQLMutation {
    static let operationName: String = "UpdateMyProfile"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation UpdateMyProfile($input: UpdateMyProfileInput!) { updateMyProfile(input: $input) { __typename id phone email } }"#
      ))

    public var input: UpdateMyProfileInput

    public init(input: UpdateMyProfileInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("updateMyProfile", UpdateMyProfile.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        UpdateMyProfileMutation.Data.self
      ] }

      var updateMyProfile: UpdateMyProfile { __data["updateMyProfile"] }

      /// UpdateMyProfile
      ///
      /// Parent Type: `Volunteer`
      struct UpdateMyProfile: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Volunteer }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("phone", String?.self),
          .field("email", String?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          UpdateMyProfileMutation.Data.UpdateMyProfile.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var phone: String? { __data["phone"] }
        var email: String? { __data["email"] }
      }
    }
  }

}