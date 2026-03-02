// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class RemoveVolunteerFromDepartmentMutation: GraphQLMutation {
    static let operationName: String = "RemoveVolunteerFromDepartment"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation RemoveVolunteerFromDepartment($id: ID!) { updateVolunteer(id: $id, input: { departmentId: null }) { __typename id department { __typename id } } }"#
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
        .field("updateVolunteer", UpdateVolunteer.self, arguments: [
          "id": .variable("id"),
          "input": ["departmentId": .null]
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        RemoveVolunteerFromDepartmentMutation.Data.self
      ] }

      var updateVolunteer: UpdateVolunteer { __data["updateVolunteer"] }

      /// UpdateVolunteer
      ///
      /// Parent Type: `Volunteer`
      struct UpdateVolunteer: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Volunteer }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("department", Department?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          RemoveVolunteerFromDepartmentMutation.Data.UpdateVolunteer.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var department: Department? { __data["department"] }

        /// UpdateVolunteer.Department
        ///
        /// Parent Type: `Department`
        struct Department: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Department }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            RemoveVolunteerFromDepartmentMutation.Data.UpdateVolunteer.Department.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
        }
      }
    }
  }

}