// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class AssignHierarchyRoleMutation: GraphQLMutation {
    static let operationName: String = "AssignHierarchyRole"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation AssignHierarchyRole($input: AssignHierarchyRoleInput!) { assignHierarchyRole(input: $input) { __typename id hierarchyRole eventVolunteer { __typename id firstName lastName } assignedAt } }"#
      ))

    public var input: AssignHierarchyRoleInput

    public init(input: AssignHierarchyRoleInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("assignHierarchyRole", AssignHierarchyRole.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        AssignHierarchyRoleMutation.Data.self
      ] }

      var assignHierarchyRole: AssignHierarchyRole { __data["assignHierarchyRole"] }

      /// AssignHierarchyRole
      ///
      /// Parent Type: `DepartmentHierarchy`
      struct AssignHierarchyRole: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.DepartmentHierarchy }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("hierarchyRole", GraphQLEnum<AssemblyOpsAPI.HierarchyRole>.self),
          .field("eventVolunteer", EventVolunteer.self),
          .field("assignedAt", AssemblyOpsAPI.DateTime.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          AssignHierarchyRoleMutation.Data.AssignHierarchyRole.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var hierarchyRole: GraphQLEnum<AssemblyOpsAPI.HierarchyRole> { __data["hierarchyRole"] }
        var eventVolunteer: EventVolunteer { __data["eventVolunteer"] }
        var assignedAt: AssemblyOpsAPI.DateTime { __data["assignedAt"] }

        /// AssignHierarchyRole.EventVolunteer
        ///
        /// Parent Type: `Volunteer`
        struct EventVolunteer: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Volunteer }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("firstName", String.self),
            .field("lastName", String.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            AssignHierarchyRoleMutation.Data.AssignHierarchyRole.EventVolunteer.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var firstName: String { __data["firstName"] }
          var lastName: String { __data["lastName"] }
        }
      }
    }
  }

}