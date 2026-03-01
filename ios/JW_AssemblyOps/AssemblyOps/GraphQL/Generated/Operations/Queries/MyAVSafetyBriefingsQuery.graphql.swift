// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class MyAVSafetyBriefingsQuery: GraphQLQuery {
    static let operationName: String = "MyAVSafetyBriefings"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query MyAVSafetyBriefings($eventId: ID!) { myAVSafetyBriefings(eventId: $eventId) { __typename id topic notes conductedBy { __typename id firstName lastName } conductedAt attendeeCount } }"#
      ))

    public var eventId: ID

    public init(eventId: ID) {
      self.eventId = eventId
    }

    public var __variables: Variables? { ["eventId": eventId] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("myAVSafetyBriefings", [MyAVSafetyBriefing].self, arguments: ["eventId": .variable("eventId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        MyAVSafetyBriefingsQuery.Data.self
      ] }

      var myAVSafetyBriefings: [MyAVSafetyBriefing] { __data["myAVSafetyBriefings"] }

      /// MyAVSafetyBriefing
      ///
      /// Parent Type: `AVSafetyBriefing`
      struct MyAVSafetyBriefing: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.AVSafetyBriefing }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("topic", String.self),
          .field("notes", String?.self),
          .field("conductedBy", ConductedBy.self),
          .field("conductedAt", String.self),
          .field("attendeeCount", Int.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          MyAVSafetyBriefingsQuery.Data.MyAVSafetyBriefing.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var topic: String { __data["topic"] }
        var notes: String? { __data["notes"] }
        var conductedBy: ConductedBy { __data["conductedBy"] }
        var conductedAt: String { __data["conductedAt"] }
        var attendeeCount: Int { __data["attendeeCount"] }

        /// MyAVSafetyBriefing.ConductedBy
        ///
        /// Parent Type: `User`
        struct ConductedBy: AssemblyOpsAPI.SelectionSet {
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
            MyAVSafetyBriefingsQuery.Data.MyAVSafetyBriefing.ConductedBy.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var firstName: String { __data["firstName"] }
          var lastName: String { __data["lastName"] }
        }
      }
    }
  }

}