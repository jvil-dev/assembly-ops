// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class AddVolunteerByUserIdMutation: GraphQLMutation {
    static let operationName: String = "AddVolunteerByUserId"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation AddVolunteerByUserId($eventId: ID!, $userId: String!, $departmentId: ID) { addVolunteerByUserId( eventId: $eventId userId: $userId departmentId: $departmentId ) { __typename id user { __typename id firstName lastName } department { __typename id name departmentType } } }"#
      ))

    public var eventId: ID
    public var userId: String
    public var departmentId: GraphQLNullable<ID>

    public init(
      eventId: ID,
      userId: String,
      departmentId: GraphQLNullable<ID>
    ) {
      self.eventId = eventId
      self.userId = userId
      self.departmentId = departmentId
    }

    public var __variables: Variables? { [
      "eventId": eventId,
      "userId": userId,
      "departmentId": departmentId
    ] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("addVolunteerByUserId", AddVolunteerByUserId.self, arguments: [
          "eventId": .variable("eventId"),
          "userId": .variable("userId"),
          "departmentId": .variable("departmentId")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        AddVolunteerByUserIdMutation.Data.self
      ] }

      var addVolunteerByUserId: AddVolunteerByUserId { __data["addVolunteerByUserId"] }

      /// AddVolunteerByUserId
      ///
      /// Parent Type: `EventVolunteer`
      struct AddVolunteerByUserId: AssemblyOpsAPI.SelectionSet {
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
          AddVolunteerByUserIdMutation.Data.AddVolunteerByUserId.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var user: User { __data["user"] }
        var department: Department? { __data["department"] }

        /// AddVolunteerByUserId.User
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
            AddVolunteerByUserIdMutation.Data.AddVolunteerByUserId.User.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var firstName: String { __data["firstName"] }
          var lastName: String { __data["lastName"] }
        }

        /// AddVolunteerByUserId.Department
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
            AddVolunteerByUserIdMutation.Data.AddVolunteerByUserId.Department.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
          var departmentType: GraphQLEnum<AssemblyOpsAPI.DepartmentType> { __data["departmentType"] }
        }
      }
    }
  }

}