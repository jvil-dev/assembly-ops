// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class RegisterUserMutation: GraphQLMutation {
    static let operationName: String = "RegisterUser"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation RegisterUser($input: RegisterUserInput!) { registerUser(input: $input) { __typename user { __typename id userId email firstName lastName fullName phone congregation congregationId appointmentStatus isOverseer congregationRef { __typename id name state circuit { __typename id code } } } accessToken refreshToken expiresIn } }"#
      ))

    public var input: RegisterUserInput

    public init(input: RegisterUserInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("registerUser", RegisterUser.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        RegisterUserMutation.Data.self
      ] }

      var registerUser: RegisterUser { __data["registerUser"] }

      /// RegisterUser
      ///
      /// Parent Type: `UserAuthPayload`
      struct RegisterUser: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.UserAuthPayload }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("user", User.self),
          .field("accessToken", String.self),
          .field("refreshToken", String.self),
          .field("expiresIn", Int.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          RegisterUserMutation.Data.RegisterUser.self
        ] }

        var user: User { __data["user"] }
        var accessToken: String { __data["accessToken"] }
        var refreshToken: String { __data["refreshToken"] }
        var expiresIn: Int { __data["expiresIn"] }

        /// RegisterUser.User
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
            .field("phone", String?.self),
            .field("congregation", String?.self),
            .field("congregationId", AssemblyOpsAPI.ID?.self),
            .field("appointmentStatus", GraphQLEnum<AssemblyOpsAPI.AppointmentStatus>?.self),
            .field("isOverseer", Bool.self),
            .field("congregationRef", CongregationRef?.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            RegisterUserMutation.Data.RegisterUser.User.self
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
          var appointmentStatus: GraphQLEnum<AssemblyOpsAPI.AppointmentStatus>? { __data["appointmentStatus"] }
          var isOverseer: Bool { __data["isOverseer"] }
          var congregationRef: CongregationRef? { __data["congregationRef"] }

          /// RegisterUser.User.CongregationRef
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
              RegisterUserMutation.Data.RegisterUser.User.CongregationRef.self
            ] }

            var id: AssemblyOpsAPI.ID { __data["id"] }
            var name: String { __data["name"] }
            var state: String { __data["state"] }
            var circuit: Circuit { __data["circuit"] }

            /// RegisterUser.User.CongregationRef.Circuit
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
                RegisterUserMutation.Data.RegisterUser.User.CongregationRef.Circuit.self
              ] }

              var id: AssemblyOpsAPI.ID { __data["id"] }
              var code: String { __data["code"] }
            }
          }
        }
      }
    }
  }

}