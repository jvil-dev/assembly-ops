// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class MyJoinRequestsQuery: GraphQLQuery {
    static let operationName: String = "MyJoinRequests"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query MyJoinRequests { myJoinRequests { __typename id eventId departmentType status note createdAt resolvedAt } }"#
      ))

    public init() {}

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("myJoinRequests", [MyJoinRequest].self),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        MyJoinRequestsQuery.Data.self
      ] }

      var myJoinRequests: [MyJoinRequest] { __data["myJoinRequests"] }

      /// MyJoinRequest
      ///
      /// Parent Type: `EventJoinRequest`
      struct MyJoinRequest: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.EventJoinRequest }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("eventId", String.self),
          .field("departmentType", GraphQLEnum<AssemblyOpsAPI.DepartmentType>?.self),
          .field("status", GraphQLEnum<AssemblyOpsAPI.JoinRequestStatus>.self),
          .field("note", String?.self),
          .field("createdAt", AssemblyOpsAPI.DateTime.self),
          .field("resolvedAt", AssemblyOpsAPI.DateTime?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          MyJoinRequestsQuery.Data.MyJoinRequest.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var eventId: String { __data["eventId"] }
        var departmentType: GraphQLEnum<AssemblyOpsAPI.DepartmentType>? { __data["departmentType"] }
        var status: GraphQLEnum<AssemblyOpsAPI.JoinRequestStatus> { __data["status"] }
        var note: String? { __data["note"] }
        var createdAt: AssemblyOpsAPI.DateTime { __data["createdAt"] }
        var resolvedAt: AssemblyOpsAPI.DateTime? { __data["resolvedAt"] }
      }
    }
  }

}