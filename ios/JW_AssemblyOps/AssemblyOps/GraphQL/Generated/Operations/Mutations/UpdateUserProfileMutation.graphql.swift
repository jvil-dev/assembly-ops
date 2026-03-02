// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class UpdateUserProfileMutation: GraphQLMutation {
    static let operationName: String = "UpdateUserProfile"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation UpdateUserProfile($input: UpdateUserProfileInput!) { updateUserProfile(input: $input) { __typename id userId email firstName lastName fullName phone congregation congregationId isOverseer congregationRef { __typename id name state circuit { __typename id code } } } }"#
      ))

    public var input: UpdateUserProfileInput

    public init(input: UpdateUserProfileInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("updateUserProfile", UpdateUserProfile.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        UpdateUserProfileMutation.Data.self
      ] }

      var updateUserProfile: UpdateUserProfile { __data["updateUserProfile"] }

      /// UpdateUserProfile
      ///
      /// Parent Type: `User`
      struct UpdateUserProfile: AssemblyOpsAPI.SelectionSet {
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
          .field("phone", String?.self),
          .field("congregation", String?.self),
          .field("congregationId", AssemblyOpsAPI.ID?.self),
          .field("isOverseer", Bool.self),
          .field("congregationRef", CongregationRef?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          UpdateUserProfileMutation.Data.UpdateUserProfile.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var userId: String { __data["userId"] }
        var email: String { __data["email"] }
        var firstName: String { __data["firstName"] }
        var lastName: String { __data["lastName"] }
        var fullName: String { __data["fullName"] }
        var phone: String? { __data["phone"] }
        var congregation: String? { __data["congregation"] }
        var congregationId: AssemblyOpsAPI.ID? { __data["congregationId"] }
        var isOverseer: Bool { __data["isOverseer"] }
        var congregationRef: CongregationRef? { __data["congregationRef"] }

        /// UpdateUserProfile.CongregationRef
        ///
        /// Parent Type: `Congregation`
        struct CongregationRef: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Congregation }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("name", String.self),
            .field("state", String.self),
            .field("circuit", Circuit.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            UpdateUserProfileMutation.Data.UpdateUserProfile.CongregationRef.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
          var state: String { __data["state"] }
          var circuit: Circuit { __data["circuit"] }

          /// UpdateUserProfile.CongregationRef.Circuit
          ///
          /// Parent Type: `Circuit`
          struct Circuit: AssemblyOpsAPI.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Circuit }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", AssemblyOpsAPI.ID.self),
              .field("code", String.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              UpdateUserProfileMutation.Data.UpdateUserProfile.CongregationRef.Circuit.self
            ] }

            var id: AssemblyOpsAPI.ID { __data["id"] }
            var code: String { __data["code"] }
          }
        }
      }
    }
  }

}