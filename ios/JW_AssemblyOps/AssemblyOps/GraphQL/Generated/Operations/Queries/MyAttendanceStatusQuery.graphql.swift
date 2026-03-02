// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class MyAttendanceStatusQuery: GraphQLQuery {
    static let operationName: String = "MyAttendanceStatus"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query MyAttendanceStatus($eventId: ID!) { myAttendanceStatus(eventId: $eventId) { __typename session { __typename id name date startTime endTime } hasSubmitted postId postName } }"#
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
        .field("myAttendanceStatus", [MyAttendanceStatus].self, arguments: ["eventId": .variable("eventId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        MyAttendanceStatusQuery.Data.self
      ] }

      var myAttendanceStatus: [MyAttendanceStatus] { __data["myAttendanceStatus"] }

      /// MyAttendanceStatus
      ///
      /// Parent Type: `MyAttendanceStatus`
      struct MyAttendanceStatus: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.MyAttendanceStatus }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("session", Session.self),
          .field("hasSubmitted", Bool.self),
          .field("postId", AssemblyOpsAPI.ID?.self),
          .field("postName", String?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          MyAttendanceStatusQuery.Data.MyAttendanceStatus.self
        ] }

        var session: Session { __data["session"] }
        var hasSubmitted: Bool { __data["hasSubmitted"] }
        var postId: AssemblyOpsAPI.ID? { __data["postId"] }
        var postName: String? { __data["postName"] }

        /// MyAttendanceStatus.Session
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
            MyAttendanceStatusQuery.Data.MyAttendanceStatus.Session.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
          var date: AssemblyOpsAPI.DateTime { __data["date"] }
          var startTime: AssemblyOpsAPI.DateTime { __data["startTime"] }
          var endTime: AssemblyOpsAPI.DateTime { __data["endTime"] }
        }
      }
    }
  }

}