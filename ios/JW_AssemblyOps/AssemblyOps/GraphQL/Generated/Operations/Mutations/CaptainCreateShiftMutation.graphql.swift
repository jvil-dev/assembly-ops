// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class CaptainCreateShiftMutation: GraphQLMutation {
    static let operationName: String = "CaptainCreateShift"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation CaptainCreateShift($input: CaptainCreateShiftInput!) { captainCreateShift(input: $input) { __typename id name startTime endTime session { __typename id name } post { __typename id name } createdBy { __typename id firstName lastName } } }"#
      ))

    public var input: CaptainCreateShiftInput

    public init(input: CaptainCreateShiftInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("captainCreateShift", CaptainCreateShift.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CaptainCreateShiftMutation.Data.self
      ] }

      var captainCreateShift: CaptainCreateShift { __data["captainCreateShift"] }

      /// CaptainCreateShift
      ///
      /// Parent Type: `Shift`
      struct CaptainCreateShift: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Shift }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("name", String.self),
          .field("startTime", AssemblyOpsAPI.DateTime.self),
          .field("endTime", AssemblyOpsAPI.DateTime.self),
          .field("session", Session.self),
          .field("post", Post.self),
          .field("createdBy", CreatedBy?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          CaptainCreateShiftMutation.Data.CaptainCreateShift.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var name: String { __data["name"] }
        var startTime: AssemblyOpsAPI.DateTime { __data["startTime"] }
        var endTime: AssemblyOpsAPI.DateTime { __data["endTime"] }
        var session: Session { __data["session"] }
        var post: Post { __data["post"] }
        var createdBy: CreatedBy? { __data["createdBy"] }

        /// CaptainCreateShift.Session
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
            CaptainCreateShiftMutation.Data.CaptainCreateShift.Session.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
        }

        /// CaptainCreateShift.Post
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
            CaptainCreateShiftMutation.Data.CaptainCreateShift.Post.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
        }

        /// CaptainCreateShift.CreatedBy
        ///
        /// Parent Type: `User`
        struct CreatedBy: AssemblyOpsAPI.SelectionSet {
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
            CaptainCreateShiftMutation.Data.CaptainCreateShift.CreatedBy.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var firstName: String { __data["firstName"] }
          var lastName: String { __data["lastName"] }
        }
      }
    }
  }

}