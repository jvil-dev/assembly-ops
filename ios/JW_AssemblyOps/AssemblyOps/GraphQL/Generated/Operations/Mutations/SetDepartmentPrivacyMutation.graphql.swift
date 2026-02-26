// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class SetDepartmentPrivacyMutation: GraphQLMutation {
    static let operationName: String = "SetDepartmentPrivacy"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation SetDepartmentPrivacy($departmentId: ID!, $isPublic: Boolean!) { setDepartmentPrivacy(departmentId: $departmentId, isPublic: $isPublic) { __typename id isPublic } }"#
      ))

    public var departmentId: ID
    public var isPublic: Bool

    public init(
      departmentId: ID,
      isPublic: Bool
    ) {
      self.departmentId = departmentId
      self.isPublic = isPublic
    }

    public var __variables: Variables? { [
      "departmentId": departmentId,
      "isPublic": isPublic
    ] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("setDepartmentPrivacy", SetDepartmentPrivacy.self, arguments: [
          "departmentId": .variable("departmentId"),
          "isPublic": .variable("isPublic")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        SetDepartmentPrivacyMutation.Data.self
      ] }

      var setDepartmentPrivacy: SetDepartmentPrivacy { __data["setDepartmentPrivacy"] }

      /// SetDepartmentPrivacy
      ///
      /// Parent Type: `Department`
      struct SetDepartmentPrivacy: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Department }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("isPublic", Bool.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          SetDepartmentPrivacyMutation.Data.SetDepartmentPrivacy.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var isPublic: Bool { __data["isPublic"] }
      }
    }
  }

}