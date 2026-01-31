// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class UpdateAdminProfileMutation: GraphQLMutation {
    static let operationName: String = "UpdateAdminProfile"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation UpdateAdminProfile($input: UpdateAdminProfileInput!) { updateAdminProfile(input: $input) { __typename id email firstName lastName fullName phone congregationId congregationRef { __typename id name city state circuit { __typename id code } } } }"#
      ))

    public var input: UpdateAdminProfileInput

    public init(input: UpdateAdminProfileInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("updateAdminProfile", UpdateAdminProfile.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        UpdateAdminProfileMutation.Data.self
      ] }

      var updateAdminProfile: UpdateAdminProfile { __data["updateAdminProfile"] }

      /// UpdateAdminProfile
      ///
      /// Parent Type: `Admin`
      struct UpdateAdminProfile: AssemblyOpsAPI.SelectionSet {
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
          .field("congregationId", AssemblyOpsAPI.ID?.self),
          .field("congregationRef", CongregationRef?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          UpdateAdminProfileMutation.Data.UpdateAdminProfile.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var email: String { __data["email"] }
        var firstName: String { __data["firstName"] }
        var lastName: String { __data["lastName"] }
        var fullName: String { __data["fullName"] }
        var phone: String? { __data["phone"] }
        var congregationId: AssemblyOpsAPI.ID? { __data["congregationId"] }
        var congregationRef: CongregationRef? { __data["congregationRef"] }

        /// UpdateAdminProfile.CongregationRef
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
            .field("city", String.self),
            .field("state", String.self),
            .field("circuit", Circuit.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            UpdateAdminProfileMutation.Data.UpdateAdminProfile.CongregationRef.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
          var city: String { __data["city"] }
          var state: String { __data["state"] }
          var circuit: Circuit { __data["circuit"] }

          /// UpdateAdminProfile.CongregationRef.Circuit
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
              UpdateAdminProfileMutation.Data.UpdateAdminProfile.CongregationRef.Circuit.self
            ] }

            var id: AssemblyOpsAPI.ID { __data["id"] }
            var code: String { __data["code"] }
          }
        }
      }
    }
  }

}