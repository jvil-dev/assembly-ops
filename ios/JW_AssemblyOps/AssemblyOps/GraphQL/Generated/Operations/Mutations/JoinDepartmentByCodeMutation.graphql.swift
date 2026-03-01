// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class JoinDepartmentByCodeMutation: GraphQLMutation {
    static let operationName: String = "JoinDepartmentByCode"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation JoinDepartmentByCode($input: JoinDepartmentByCodeInput!) { joinDepartmentByAccessCode(input: $input) { __typename id user { __typename id firstName lastName } department { __typename id name departmentType } } }"#
      ))

    public var input: JoinDepartmentByCodeInput

    public init(input: JoinDepartmentByCodeInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("joinDepartmentByAccessCode", JoinDepartmentByAccessCode.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        JoinDepartmentByCodeMutation.Data.self
      ] }

      var joinDepartmentByAccessCode: JoinDepartmentByAccessCode { __data["joinDepartmentByAccessCode"] }

      /// JoinDepartmentByAccessCode
      ///
      /// Parent Type: `EventVolunteer`
      struct JoinDepartmentByAccessCode: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.EventVolunteer }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("user", User.self),
          .field("department", Department?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          JoinDepartmentByCodeMutation.Data.JoinDepartmentByAccessCode.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var user: User { __data["user"] }
        var department: Department? { __data["department"] }

        /// JoinDepartmentByAccessCode.User
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
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            JoinDepartmentByCodeMutation.Data.JoinDepartmentByAccessCode.User.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var firstName: String { __data["firstName"] }
          var lastName: String { __data["lastName"] }
        }

        /// JoinDepartmentByAccessCode.Department
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
            JoinDepartmentByCodeMutation.Data.JoinDepartmentByAccessCode.Department.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
          var departmentType: GraphQLEnum<AssemblyOpsAPI.DepartmentType> { __data["departmentType"] }
        }
      }
    }
  }

}