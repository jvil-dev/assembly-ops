// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class DepartmentCoverageQuery: GraphQLQuery {
    static let operationName: String = "DepartmentCoverage"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query DepartmentCoverage($departmentId: ID!) { departmentCoverage(departmentId: $departmentId) { __typename post { __typename id name capacity } session { __typename id name date startTime endTime } assignments { __typename id volunteer { __typename id firstName lastName } checkIn { __typename id checkInTime } } filled capacity isFilled } }"#
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
          .field("assignments", [Assignment].self),
          .field("filled", Int.self),
          .field("capacity", Int.self),
          .field("isFilled", Bool.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          DepartmentCoverageQuery.Data.DepartmentCoverage.self
        ] }

        var post: Post { __data["post"] }
        var session: Session { __data["session"] }
        var assignments: [Assignment] { __data["assignments"] }
        var filled: Int { __data["filled"] }
        var capacity: Int { __data["capacity"] }
        var isFilled: Bool { __data["isFilled"] }

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
            .field("capacity", Int.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            DepartmentCoverageQuery.Data.DepartmentCoverage.Post.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
          var capacity: Int { __data["capacity"] }
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
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            DepartmentCoverageQuery.Data.DepartmentCoverage.Assignment.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var volunteer: Volunteer { __data["volunteer"] }
          var checkIn: CheckIn? { __data["checkIn"] }

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