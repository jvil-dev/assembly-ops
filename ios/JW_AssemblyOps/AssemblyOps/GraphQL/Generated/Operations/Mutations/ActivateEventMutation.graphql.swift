// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class ActivateEventMutation: GraphQLMutation {
    static let operationName: String = "ActivateEvent"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation ActivateEvent($input: ActivateEventInput!) { activateEvent(input: $input) { __typename id name joinCode eventType venue address startDate endDate } }"#
      ))

    public var input: ActivateEventInput

    public init(input: ActivateEventInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("activateEvent", ActivateEvent.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        ActivateEventMutation.Data.self
      ] }

      var activateEvent: ActivateEvent { __data["activateEvent"] }

      /// ActivateEvent
      ///
      /// Parent Type: `Event`
      struct ActivateEvent: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Event }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("name", String.self),
          .field("joinCode", String.self),
          .field("eventType", GraphQLEnum<AssemblyOpsAPI.EventType>.self),
          .field("venue", String.self),
          .field("address", String.self),
          .field("startDate", AssemblyOpsAPI.DateTime.self),
          .field("endDate", AssemblyOpsAPI.DateTime.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          ActivateEventMutation.Data.ActivateEvent.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var name: String { __data["name"] }
        var joinCode: String { __data["joinCode"] }
        var eventType: GraphQLEnum<AssemblyOpsAPI.EventType> { __data["eventType"] }
        var venue: String { __data["venue"] }
        var address: String { __data["address"] }
        var startDate: AssemblyOpsAPI.DateTime { __data["startDate"] }
        var endDate: AssemblyOpsAPI.DateTime { __data["endDate"] }
      }
    }
  }

}