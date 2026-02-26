// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class PromoteToAppAdminMutation: GraphQLMutation {
    static let operationName: String = "PromoteToAppAdmin"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation PromoteToAppAdmin($input: PromoteToAppAdminInput!) { promoteToAppAdmin(input: $input) { __typename id role claimedAt user { __typename id firstName lastName email } event { __typename id name } department { __typename id name departmentType } } }"#
      ))

    public var input: PromoteToAppAdminInput

    public init(input: PromoteToAppAdminInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("promoteToAppAdmin", PromoteToAppAdmin.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        PromoteToAppAdminMutation.Data.self
      ] }

      var promoteToAppAdmin: PromoteToAppAdmin { __data["promoteToAppAdmin"] }

      /// PromoteToAppAdmin
      ///
      /// Parent Type: `EventAdmin`
      struct PromoteToAppAdmin: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.EventAdmin }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("role", GraphQLEnum<AssemblyOpsAPI.EventRole>.self),
          .field("claimedAt", AssemblyOpsAPI.DateTime.self),
          .field("user", User.self),
          .field("event", Event.self),
          .field("department", Department?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          PromoteToAppAdminMutation.Data.PromoteToAppAdmin.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var role: GraphQLEnum<AssemblyOpsAPI.EventRole> { __data["role"] }
        var claimedAt: AssemblyOpsAPI.DateTime { __data["claimedAt"] }
        var user: User { __data["user"] }
        var event: Event { __data["event"] }
        var department: Department? { __data["department"] }

        /// PromoteToAppAdmin.User
        ///
        /// Parent Type: `User`
        struct User: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.User }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("firstName", String.self),
            .field("lastName", String.self),
            .field("email", String.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            PromoteToAppAdminMutation.Data.PromoteToAppAdmin.User.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var firstName: String { __data["firstName"] }
          var lastName: String { __data["lastName"] }
          var email: String { __data["email"] }
        }

        /// PromoteToAppAdmin.Event
        ///
        /// Parent Type: `Event`
        struct Event: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Event }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("name", String.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            PromoteToAppAdminMutation.Data.PromoteToAppAdmin.Event.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
        }

        /// PromoteToAppAdmin.Department
        ///
        /// Parent Type: `Department`
        struct Department: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Department }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("name", String.self),
            .field("departmentType", GraphQLEnum<AssemblyOpsAPI.DepartmentType>.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            PromoteToAppAdminMutation.Data.PromoteToAppAdmin.Department.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
          var departmentType: GraphQLEnum<AssemblyOpsAPI.DepartmentType> { __data["departmentType"] }
        }
      }
    }
  }

}