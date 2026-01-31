// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class JoinEventMutation: GraphQLMutation {
    static let operationName: String = "JoinEvent"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation JoinEvent($input: JoinEventInput!) { joinEvent(input: $input) { __typename id role event { __typename id name eventType venue startDate endDate } } }"#
      ))

    public var input: JoinEventInput

    public init(input: JoinEventInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("joinEvent", JoinEvent.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        JoinEventMutation.Data.self
      ] }

      var joinEvent: JoinEvent { __data["joinEvent"] }

      /// JoinEvent
      ///
      /// Parent Type: `EventAdmin`
      struct JoinEvent: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.EventAdmin }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("role", GraphQLEnum<AssemblyOpsAPI.EventRole>.self),
          .field("event", Event.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          JoinEventMutation.Data.JoinEvent.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var role: GraphQLEnum<AssemblyOpsAPI.EventRole> { __data["role"] }
        var event: Event { __data["event"] }

        /// JoinEvent.Event
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
            JoinEventMutation.Data.JoinEvent.Event.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
          var eventType: GraphQLEnum<AssemblyOpsAPI.EventType> { __data["eventType"] }
          var venue: String { __data["venue"] }
          var startDate: AssemblyOpsAPI.DateTime { __data["startDate"] }
          var endDate: AssemblyOpsAPI.DateTime { __data["endDate"] }
        }
      }
    }
  }

}