// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class DepartmentAreasQuery: GraphQLQuery {
    static let operationName: String = "DepartmentAreas"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query DepartmentAreas($departmentId: ID!) { departmentAreas(departmentId: $departmentId) { __typename id name description category sortOrder postCount posts { __typename id name capacity category sortOrder } captains { __typename id session { __typename id name date } eventVolunteer { __typename id user { __typename firstName lastName } } } } }"#
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
        .field("departmentAreas", [DepartmentArea].self, arguments: ["departmentId": .variable("departmentId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        DepartmentAreasQuery.Data.self
      ] }

      var departmentAreas: [DepartmentArea] { __data["departmentAreas"] }

      /// DepartmentArea
      ///
      /// Parent Type: `Area`
      struct DepartmentArea: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Area }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("name", String.self),
          .field("description", String?.self),
          .field("category", String?.self),
          .field("sortOrder", Int.self),
          .field("postCount", Int.self),
          .field("posts", [Post].self),
          .field("captains", [Captain].self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          DepartmentAreasQuery.Data.DepartmentArea.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var name: String { __data["name"] }
        var description: String? { __data["description"] }
        var category: String? { __data["category"] }
        var sortOrder: Int { __data["sortOrder"] }
        var postCount: Int { __data["postCount"] }
        var posts: [Post] { __data["posts"] }
        var captains: [Captain] { __data["captains"] }

        /// DepartmentArea.Post
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
            .field("capacity", Int.self),
            .field("category", String?.self),
            .field("sortOrder", Int.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            DepartmentAreasQuery.Data.DepartmentArea.Post.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
          var capacity: Int { __data["capacity"] }
          var category: String? { __data["category"] }
          var sortOrder: Int { __data["sortOrder"] }
        }

        /// DepartmentArea.Captain
        ///
        /// Parent Type: `AreaCaptainAssignment`
        struct Captain: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.AreaCaptainAssignment }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("session", Session.self),
            .field("eventVolunteer", EventVolunteer.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            DepartmentAreasQuery.Data.DepartmentArea.Captain.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var session: Session { __data["session"] }
          var eventVolunteer: EventVolunteer { __data["eventVolunteer"] }

          /// DepartmentArea.Captain.Session
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
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              DepartmentAreasQuery.Data.DepartmentArea.Captain.Session.self
            ] }

            var id: AssemblyOpsAPI.ID { __data["id"] }
            var name: String { __data["name"] }
            var date: AssemblyOpsAPI.DateTime { __data["date"] }
          }

          /// DepartmentArea.Captain.EventVolunteer
          ///
          /// Parent Type: `EventVolunteer`
          struct EventVolunteer: AssemblyOpsAPI.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.EventVolunteer }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", AssemblyOpsAPI.ID.self),
              .field("user", User.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              DepartmentAreasQuery.Data.DepartmentArea.Captain.EventVolunteer.self
            ] }

            var id: AssemblyOpsAPI.ID { __data["id"] }
            var user: User { __data["user"] }

            /// DepartmentArea.Captain.EventVolunteer.User
            ///
            /// Parent Type: `User`
            struct User: AssemblyOpsAPI.SelectionSet {
              let __data: DataDict
              init(_dataDict: DataDict) { __data = _dataDict }

              static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.User }
              static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .field("firstName", String.self),
                .field("lastName", String.self),
              ] }
              static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                DepartmentAreasQuery.Data.DepartmentArea.Captain.EventVolunteer.User.self
              ] }

              var firstName: String { __data["firstName"] }
              var lastName: String { __data["lastName"] }
            }
          }
        }
      }
    }
  }

}