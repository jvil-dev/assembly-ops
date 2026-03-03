// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class DepartmentCoverageQuery: GraphQLQuery {
    static let operationName: String = "DepartmentCoverage"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query DepartmentCoverage($departmentId: ID!) { departmentCoverage(departmentId: $departmentId) { __typename post { __typename id name category location sortOrder areaId areaName } session { __typename id name date startTime endTime } shifts { __typename id name startTime endTime } assignments { __typename id volunteer { __typename id firstName lastName } checkIn { __typename id checkInTime } status forceAssigned canCount shiftId shiftName } filled } }"#
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
        .field("departmentCoverage", [DepartmentCoverage].self, arguments: ["departmentId": .variable("departmentId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        DepartmentCoverageQuery.Data.self
      ] }

      var departmentCoverage: [DepartmentCoverage] { __data["departmentCoverage"] }

      /// DepartmentCoverage
      ///
      /// Parent Type: `CoverageSlot`
      struct DepartmentCoverage: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.CoverageSlot }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("post", Post.self),
          .field("session", Session.self),
          .field("shifts", [Shift].self),
          .field("assignments", [Assignment].self),
          .field("filled", Int.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          DepartmentCoverageQuery.Data.DepartmentCoverage.self
        ] }

        var post: Post { __data["post"] }
        var session: Session { __data["session"] }
        var shifts: [Shift] { __data["shifts"] }
        var assignments: [Assignment] { __data["assignments"] }
        var filled: Int { __data["filled"] }

        /// DepartmentCoverage.Post
        ///
        /// Parent Type: `CoveragePost`
        struct Post: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.CoveragePost }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("name", String.self),
            .field("category", String?.self),
            .field("location", String?.self),
            .field("sortOrder", Int.self),
            .field("areaId", AssemblyOpsAPI.ID?.self),
            .field("areaName", String?.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            DepartmentCoverageQuery.Data.DepartmentCoverage.Post.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
          var category: String? { __data["category"] }
          var location: String? { __data["location"] }
          var sortOrder: Int { __data["sortOrder"] }
          var areaId: AssemblyOpsAPI.ID? { __data["areaId"] }
          var areaName: String? { __data["areaName"] }
        }

        /// DepartmentCoverage.Session
        ///
        /// Parent Type: `CoverageSession`
        struct Session: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.CoverageSession }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("name", String.self),
            .field("date", AssemblyOpsAPI.DateTime.self),
            .field("startTime", AssemblyOpsAPI.DateTime.self),
            .field("endTime", AssemblyOpsAPI.DateTime.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            DepartmentCoverageQuery.Data.DepartmentCoverage.Session.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
          var date: AssemblyOpsAPI.DateTime { __data["date"] }
          var startTime: AssemblyOpsAPI.DateTime { __data["startTime"] }
          var endTime: AssemblyOpsAPI.DateTime { __data["endTime"] }
        }

        /// DepartmentCoverage.Shift
        ///
        /// Parent Type: `CoverageShift`
        struct Shift: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.CoverageShift }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("name", String.self),
            .field("startTime", AssemblyOpsAPI.DateTime.self),
            .field("endTime", AssemblyOpsAPI.DateTime.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            DepartmentCoverageQuery.Data.DepartmentCoverage.Shift.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
          var startTime: AssemblyOpsAPI.DateTime { __data["startTime"] }
          var endTime: AssemblyOpsAPI.DateTime { __data["endTime"] }
        }

        /// DepartmentCoverage.Assignment
        ///
        /// Parent Type: `CoverageAssignment`
        struct Assignment: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.CoverageAssignment }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("volunteer", Volunteer.self),
            .field("checkIn", CheckIn?.self),
            .field("status", GraphQLEnum<AssemblyOpsAPI.AssignmentStatus>.self),
            .field("forceAssigned", Bool.self),
            .field("canCount", Bool.self),
            .field("shiftId", AssemblyOpsAPI.ID?.self),
            .field("shiftName", String?.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            DepartmentCoverageQuery.Data.DepartmentCoverage.Assignment.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var volunteer: Volunteer { __data["volunteer"] }
          var checkIn: CheckIn? { __data["checkIn"] }
          var status: GraphQLEnum<AssemblyOpsAPI.AssignmentStatus> { __data["status"] }
          var forceAssigned: Bool { __data["forceAssigned"] }
          var canCount: Bool { __data["canCount"] }
          var shiftId: AssemblyOpsAPI.ID? { __data["shiftId"] }
          var shiftName: String? { __data["shiftName"] }

          /// DepartmentCoverage.Assignment.Volunteer
          ///
          /// Parent Type: `CoverageVolunteer`
          struct Volunteer: AssemblyOpsAPI.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.CoverageVolunteer }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", AssemblyOpsAPI.ID.self),
              .field("firstName", String.self),
              .field("lastName", String.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              DepartmentCoverageQuery.Data.DepartmentCoverage.Assignment.Volunteer.self
            ] }

            var id: AssemblyOpsAPI.ID { __data["id"] }
            var firstName: String { __data["firstName"] }
            var lastName: String { __data["lastName"] }
          }

          /// DepartmentCoverage.Assignment.CheckIn
          ///
          /// Parent Type: `CoverageCheckIn`
          struct CheckIn: AssemblyOpsAPI.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.CoverageCheckIn }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", AssemblyOpsAPI.ID.self),
              .field("checkInTime", AssemblyOpsAPI.DateTime.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              DepartmentCoverageQuery.Data.DepartmentCoverage.Assignment.CheckIn.self
            ] }

            var id: AssemblyOpsAPI.ID { __data["id"] }
            var checkInTime: AssemblyOpsAPI.DateTime { __data["checkInTime"] }
          }
        }
      }
    }
  }

}