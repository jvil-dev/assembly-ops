// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class LoginAdminMutation: GraphQLMutation {
    static let operationName: String = "LoginAdmin"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation LoginAdmin($input: LoginAdminInput!) { loginAdmin(input: $input) { __typename admin { __typename id email firstName lastName fullName phone congregation } accessToken refreshToken expiresIn } }"#
      ))

    public var input: LoginAdminInput

    public init(input: LoginAdminInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("loginAdmin", LoginAdmin.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        LoginAdminMutation.Data.self
      ] }

      var loginAdmin: LoginAdmin { __data["loginAdmin"] }

      /// LoginAdmin
      ///
      /// Parent Type: `AuthPayload`
      struct LoginAdmin: AssemblyOpsAPI.SelectionSet {
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
          LoginAdminMutation.Data.LoginAdmin.self
        ] }

        var admin: Admin { __data["admin"] }
        var accessToken: String { __data["accessToken"] }
        var refreshToken: String { __data["refreshToken"] }
        var expiresIn: Int { __data["expiresIn"] }

        /// LoginAdmin.Admin
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
            .field("phone", String?.self),
            .field("congregation", String?.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            LoginAdminMutation.Data.LoginAdmin.Admin.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var email: String { __data["email"] }
          var firstName: String { __data["firstName"] }
          var lastName: String { __data["lastName"] }
          var fullName: String { __data["fullName"] }
          var phone: String? { __data["phone"] }
          var congregation: String? { __data["congregation"] }
        }
      }
    }
  }

}