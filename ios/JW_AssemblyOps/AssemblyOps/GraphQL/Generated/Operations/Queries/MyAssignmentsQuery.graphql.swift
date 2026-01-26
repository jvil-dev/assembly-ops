// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class MyAssignmentsQuery: GraphQLQuery {
    static let operationName: String = "MyAssignments"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query MyAssignments { myAssignments { __typename id post { __typename id name location department { __typename id name departmentType } } session { __typename id name date startTime endTime } isCheckedIn checkIn { __typename id status checkInTime checkOutTime } } }"#
      ))

    public init() {}

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("myAssignments", [MyAssignment].self),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        MyAssignmentsQuery.Data.self
      ] }

      var myAssignments: [MyAssignment] { __data["myAssignments"] }

      /// MyAssignment
      ///
      /// Parent Type: `ScheduleAssignment`
      struct MyAssignment: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.ScheduleAssignment }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("post", Post.self),
          .field("session", Session.self),
          .field("isCheckedIn", Bool.self),
          .field("checkIn", CheckIn?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          MyAssignmentsQuery.Data.MyAssignment.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var post: Post { __data["post"] }
        var session: Session { __data["session"] }
        var isCheckedIn: Bool { __data["isCheckedIn"] }
        var checkIn: CheckIn? { __data["checkIn"] }

        /// MyAssignment.Post
        ///
        /// Parent Type: `Post`
        struct Post: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Post }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("name", String.self),
            .field("location", String?.self),
            .field("department", Department.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            MyAssignmentsQuery.Data.MyAssignment.Post.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
          var location: String? { __data["location"] }
          var department: Department { __data["department"] }

          /// MyAssignment.Post.Department
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
              MyAssignmentsQuery.Data.MyAssignment.Post.Department.self
            ] }

            var id: AssemblyOpsAPI.ID { __data["id"] }
            var name: String { __data["name"] }
            var departmentType: GraphQLEnum<AssemblyOpsAPI.DepartmentType> { __data["departmentType"] }
          }
        }

        /// MyAssignment.Session
        ///
        /// Parent Type: `Session`
        struct Session: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Session }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("name", String.self),
            .field("date", AssemblyOpsAPI.DateTime.self),
            .field("startTime", AssemblyOpsAPI.DateTime.self),
            .field("endTime", AssemblyOpsAPI.DateTime.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            MyAssignmentsQuery.Data.MyAssignment.Session.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
          var date: AssemblyOpsAPI.DateTime { __data["date"] }
          var startTime: AssemblyOpsAPI.DateTime { __data["startTime"] }
          var endTime: AssemblyOpsAPI.DateTime { __data["endTime"] }
        }

        /// MyAssignment.CheckIn
        ///
        /// Parent Type: `CheckIn`
        struct CheckIn: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.CheckIn }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("status", GraphQLEnum<AssemblyOpsAPI.CheckInStatus>.self),
            .field("checkInTime", AssemblyOpsAPI.DateTime.self),
            .field("checkOutTime", AssemblyOpsAPI.DateTime?.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            MyAssignmentsQuery.Data.MyAssignment.CheckIn.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var status: GraphQLEnum<AssemblyOpsAPI.CheckInStatus> { __data["status"] }
          var checkInTime: AssemblyOpsAPI.DateTime { __data["checkInTime"] }
          var checkOutTime: AssemblyOpsAPI.DateTime? { __data["checkOutTime"] }
        }
      }
    }
  }

}