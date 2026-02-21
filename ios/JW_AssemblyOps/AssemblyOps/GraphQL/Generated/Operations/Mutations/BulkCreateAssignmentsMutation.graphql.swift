// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class BulkCreateAssignmentsMutation: GraphQLMutation {
    static let operationName: String = "BulkCreateAssignments"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation BulkCreateAssignments($inputs: [CreateAssignmentInput!]!) { bulkCreateAssignments(inputs: $inputs) { __typename id isCheckedIn volunteer { __typename id firstName lastName } post { __typename id name } session { __typename id name } } }"#
      ))

    public var inputs: [CreateAssignmentInput]

    public init(inputs: [CreateAssignmentInput]) {
      self.inputs = inputs
    }

    public var __variables: Variables? { ["inputs": inputs] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("bulkCreateAssignments", [BulkCreateAssignment].self, arguments: ["inputs": .variable("inputs")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        BulkCreateAssignmentsMutation.Data.self
      ] }

      var bulkCreateAssignments: [BulkCreateAssignment] { __data["bulkCreateAssignments"] }

      /// BulkCreateAssignment
      ///
      /// Parent Type: `ScheduleAssignment`
      struct BulkCreateAssignment: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.ScheduleAssignment }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("isCheckedIn", Bool.self),
          .field("volunteer", Volunteer.self),
          .field("post", Post.self),
          .field("session", Session.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          BulkCreateAssignmentsMutation.Data.BulkCreateAssignment.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var isCheckedIn: Bool { __data["isCheckedIn"] }
        var volunteer: Volunteer { __data["volunteer"] }
        var post: Post { __data["post"] }
        var session: Session { __data["session"] }

        /// BulkCreateAssignment.Volunteer
        ///
        /// Parent Type: `Volunteer`
        struct Volunteer: AssemblyOpsAPI.SelectionSet {
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
            BulkCreateAssignmentsMutation.Data.BulkCreateAssignment.Volunteer.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var firstName: String { __data["firstName"] }
          var lastName: String { __data["lastName"] }
        }

        /// BulkCreateAssignment.Post
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
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            BulkCreateAssignmentsMutation.Data.BulkCreateAssignment.Post.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
        }

        /// BulkCreateAssignment.Session
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
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            BulkCreateAssignmentsMutation.Data.BulkCreateAssignment.Session.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
        }
      }
    }
  }

}