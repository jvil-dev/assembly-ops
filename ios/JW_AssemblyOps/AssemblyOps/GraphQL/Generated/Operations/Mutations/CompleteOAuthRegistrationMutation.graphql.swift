// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class CompleteOAuthRegistrationMutation: GraphQLMutation {
    static let operationName: String = "CompleteOAuthRegistration"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation CompleteOAuthRegistration($input: CompleteOAuthRegistrationInput!) { completeOAuthRegistration(input: $input) { __typename admin { __typename id email firstName lastName fullName } accessToken refreshToken expiresIn } }"#
      ))

    public var input: CompleteOAuthRegistrationInput

    public init(input: CompleteOAuthRegistrationInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("completeOAuthRegistration", CompleteOAuthRegistration.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CompleteOAuthRegistrationMutation.Data.self
      ] }

      var completeOAuthRegistration: CompleteOAuthRegistration { __data["completeOAuthRegistration"] }

      /// CompleteOAuthRegistration
      ///
      /// Parent Type: `AuthPayload`
      struct CompleteOAuthRegistration: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.AuthPayload }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("admin", Admin.self),
          .field("accessToken", String.self),
          .field("refreshToken", String.self),
          .field("expiresIn", Int.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          CompleteOAuthRegistrationMutation.Data.CompleteOAuthRegistration.self
        ] }

        var admin: Admin { __data["admin"] }
        var accessToken: String { __data["accessToken"] }
        var refreshToken: String { __data["refreshToken"] }
        var expiresIn: Int { __data["expiresIn"] }

        /// CompleteOAuthRegistration.Admin
        ///
        /// Parent Type: `Admin`
        struct Admin: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Admin }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("email", String.self),
            .field("firstName", String.self),
            .field("lastName", String.self),
            .field("fullName", String.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            CompleteOAuthRegistrationMutation.Data.CompleteOAuthRegistration.Admin.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var email: String { __data["email"] }
          var firstName: String { __data["firstName"] }
          var lastName: String { __data["lastName"] }
          var fullName: String { __data["fullName"] }
        }
      }
    }
  }

}