// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class CreateSessionMutation: GraphQLMutation {
    static let operationName: String = "CreateSession"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation CreateSession($eventId: ID!, $input: CreateSessionInput!) { createSession(eventId: $eventId, input: $input) { __typename id name date startTime endTime createdAt } }"#
      ))

    public var eventId: ID
    public var input: CreateSessionInput

    public init(
      eventId: ID,
      input: CreateSessionInput
    ) {
      self.eventId = eventId
      self.input = input
    }

    public var __variables: Variables? { [
      "eventId": eventId,
      "input": input
    ] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("createSession", CreateSession.self, arguments: [
          "eventId": .variable("eventId"),
          "input": .variable("input")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CreateSessionMutation.Data.self
      ] }

      var createSession: CreateSession { __data["createSession"] }

      /// CreateSession
      ///
      /// Parent Type: `Session`
      struct CreateSession: AssemblyOpsAPI.SelectionSet {
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
          .field("createdAt", AssemblyOpsAPI.DateTime.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          CreateSessionMutation.Data.CreateSession.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var name: String { __data["name"] }
        var date: AssemblyOpsAPI.DateTime { __data["date"] }
        var startTime: AssemblyOpsAPI.DateTime { __data["startTime"] }
        var endTime: AssemblyOpsAPI.DateTime { __data["endTime"] }
        var createdAt: AssemblyOpsAPI.DateTime { __data["createdAt"] }
      }
    }
  }

}