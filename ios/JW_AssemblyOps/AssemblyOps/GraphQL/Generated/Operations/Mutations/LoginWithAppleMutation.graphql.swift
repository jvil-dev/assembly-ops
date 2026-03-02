// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class LoginWithAppleMutation: GraphQLMutation {
    static let operationName: String = "LoginWithApple"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation LoginWithApple($input: AppleAuthInput!) { loginWithApple(input: $input) { __typename user { __typename id userId email firstName lastName fullName isOverseer } accessToken refreshToken expiresIn isNewUser pendingOAuthToken email firstName lastName } }"#
      ))

    public var input: AppleAuthInput

    public init(input: AppleAuthInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("loginWithApple", LoginWithApple.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        LoginWithAppleMutation.Data.self
      ] }

      var loginWithApple: LoginWithApple { __data["loginWithApple"] }

      /// LoginWithApple
      ///
      /// Parent Type: `OAuthAuthPayload`
      struct LoginWithApple: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.OAuthAuthPayload }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("user", User?.self),
          .field("accessToken", String?.self),
          .field("refreshToken", String?.self),
          .field("expiresIn", Int?.self),
          .field("isNewUser", Bool.self),
          .field("pendingOAuthToken", String?.self),
          .field("email", String.self),
          .field("firstName", String?.self),
          .field("lastName", String?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          LoginWithAppleMutation.Data.LoginWithApple.self
        ] }

        var user: User? { __data["user"] }
        var accessToken: String? { __data["accessToken"] }
        var refreshToken: String? { __data["refreshToken"] }
        var expiresIn: Int? { __data["expiresIn"] }
        var isNewUser: Bool { __data["isNewUser"] }
        var pendingOAuthToken: String? { __data["pendingOAuthToken"] }
        var email: String { __data["email"] }
        var firstName: String? { __data["firstName"] }
        var lastName: String? { __data["lastName"] }

        /// LoginWithApple.User
        ///
        /// Parent Type: `User`
        struct User: AssemblyOpsAPI.SelectionSet {
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
            LoginWithAppleMutation.Data.LoginWithApple.User.self
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

}