// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class MyWalkThroughCompletionsQuery: GraphQLQuery {
    static let operationName: String = "MyWalkThroughCompletions"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query MyWalkThroughCompletions { myWalkThroughCompletions { __typename id session { __typename id name } completedAt itemCount notes } }"#
      ))

    public init() {}

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("myWalkThroughCompletions", [MyWalkThroughCompletion].self),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        MyWalkThroughCompletionsQuery.Data.self
      ] }

      var myWalkThroughCompletions: [MyWalkThroughCompletion] { __data["myWalkThroughCompletions"] }

      /// MyWalkThroughCompletion
      ///
      /// Parent Type: `WalkThroughCompletion`
      struct MyWalkThroughCompletion: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.WalkThroughCompletion }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("session", Session.self),
          .field("completedAt", String.self),
          .field("itemCount", Int.self),
          .field("notes", String?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          MyWalkThroughCompletionsQuery.Data.MyWalkThroughCompletion.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var session: Session { __data["session"] }
        var completedAt: String { __data["completedAt"] }
        var itemCount: Int { __data["itemCount"] }
        var notes: String? { __data["notes"] }

        /// MyWalkThroughCompletion.Session
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
            MyWalkThroughCompletionsQuery.Data.MyWalkThroughCompletion.Session.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
        }
      }
    }
  }

}