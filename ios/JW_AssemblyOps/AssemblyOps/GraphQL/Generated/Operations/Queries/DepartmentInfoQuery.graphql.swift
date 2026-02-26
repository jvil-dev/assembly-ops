// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class DepartmentInfoQuery: GraphQLQuery {
    static let operationName: String = "DepartmentInfo"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query DepartmentInfo($departmentId: ID!) { departmentInfo(departmentId: $departmentId) { __typename id name departmentType accessCode isPublic event { __typename id name eventType venue startDate endDate } overseer { __typename id user { __typename id firstName lastName } } hierarchyRoles { __typename id hierarchyRole eventVolunteer { __typename id firstName lastName } assignedAt } volunteerCount } }"#
      ))

    public var departmentId: ID

    public init(departmentId: ID) {
      self.departmentId = departmentId
    }

    public var __variables: Variables? { ["departmentId": departmentId] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("departmentInfo", DepartmentInfo?.self, arguments: ["departmentId": .variable("departmentId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        DepartmentInfoQuery.Data.self
      ] }

      var departmentInfo: DepartmentInfo? { __data["departmentInfo"] }

      /// DepartmentInfo
      ///
      /// Parent Type: `Department`
      struct DepartmentInfo: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Department }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("name", String.self),
          .field("departmentType", GraphQLEnum<AssemblyOpsAPI.DepartmentType>.self),
          .field("accessCode", String?.self),
          .field("isPublic", Bool.self),
          .field("event", Event.self),
          .field("overseer", Overseer?.self),
          .field("hierarchyRoles", [HierarchyRole].self),
          .field("volunteerCount", Int.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          DepartmentInfoQuery.Data.DepartmentInfo.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var name: String { __data["name"] }
        var departmentType: GraphQLEnum<AssemblyOpsAPI.DepartmentType> { __data["departmentType"] }
        var accessCode: String? { __data["accessCode"] }
        var isPublic: Bool { __data["isPublic"] }
        var event: Event { __data["event"] }
        var overseer: Overseer? { __data["overseer"] }
        var hierarchyRoles: [HierarchyRole] { __data["hierarchyRoles"] }
        var volunteerCount: Int { __data["volunteerCount"] }

        /// DepartmentInfo.Event
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
            .field("eventType", GraphQLEnum<AssemblyOpsAPI.EventType>.self),
            .field("venue", String.self),
            .field("startDate", AssemblyOpsAPI.DateTime.self),
            .field("endDate", AssemblyOpsAPI.DateTime.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            DepartmentInfoQuery.Data.DepartmentInfo.Event.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
          var eventType: GraphQLEnum<AssemblyOpsAPI.EventType> { __data["eventType"] }
          var venue: String { __data["venue"] }
          var startDate: AssemblyOpsAPI.DateTime { __data["startDate"] }
          var endDate: AssemblyOpsAPI.DateTime { __data["endDate"] }
        }

        /// DepartmentInfo.Overseer
        ///
        /// Parent Type: `EventAdmin`
        struct Overseer: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.EventAdmin }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("user", User.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            DepartmentInfoQuery.Data.DepartmentInfo.Overseer.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var user: User { __data["user"] }

          /// DepartmentInfo.Overseer.User
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
              DepartmentInfoQuery.Data.DepartmentInfo.Overseer.User.self
            ] }

            var id: AssemblyOpsAPI.ID { __data["id"] }
            var firstName: String { __data["firstName"] }
            var lastName: String { __data["lastName"] }
          }
        }

        /// DepartmentInfo.HierarchyRole
        ///
        /// Parent Type: `DepartmentHierarchy`
        struct HierarchyRole: AssemblyOpsAPI.SelectionSet {
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
            DepartmentInfoQuery.Data.DepartmentInfo.HierarchyRole.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var hierarchyRole: GraphQLEnum<AssemblyOpsAPI.HierarchyRole> { __data["hierarchyRole"] }
          var eventVolunteer: EventVolunteer { __data["eventVolunteer"] }
          var assignedAt: AssemblyOpsAPI.DateTime { __data["assignedAt"] }

          /// DepartmentInfo.HierarchyRole.EventVolunteer
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
              DepartmentInfoQuery.Data.DepartmentInfo.HierarchyRole.EventVolunteer.self
            ] }

            var id: AssemblyOpsAPI.ID { __data["id"] }
            var firstName: String { __data["firstName"] }
            var lastName: String { __data["lastName"] }
          }
        }
      }
    }
  }

}