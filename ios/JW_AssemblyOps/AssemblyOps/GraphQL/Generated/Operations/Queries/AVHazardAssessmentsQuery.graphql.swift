// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class AVHazardAssessmentsQuery: GraphQLQuery {
    static let operationName: String = "AVHazardAssessments"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query AVHazardAssessments($eventId: ID!) { avHazardAssessments(eventId: $eventId) { __typename id title hazardType description controls ppeRequired completedBy { __typename id firstName lastName } session { __typename id name } completedAt } }"#
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
        .field("avHazardAssessments", [AvHazardAssessment].self, arguments: ["eventId": .variable("eventId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        AVHazardAssessmentsQuery.Data.self
      ] }

      var avHazardAssessments: [AvHazardAssessment] { __data["avHazardAssessments"] }

      /// AvHazardAssessment
      ///
      /// Parent Type: `AVHazardAssessment`
      struct AvHazardAssessment: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.AVHazardAssessment }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("title", String.self),
          .field("hazardType", GraphQLEnum<AssemblyOpsAPI.AVHazardType>.self),
          .field("description", String.self),
          .field("controls", String.self),
          .field("ppeRequired", [String].self),
          .field("completedBy", CompletedBy.self),
          .field("session", Session?.self),
          .field("completedAt", String.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          AVHazardAssessmentsQuery.Data.AvHazardAssessment.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var title: String { __data["title"] }
        var hazardType: GraphQLEnum<AssemblyOpsAPI.AVHazardType> { __data["hazardType"] }
        var description: String { __data["description"] }
        var controls: String { __data["controls"] }
        var ppeRequired: [String] { __data["ppeRequired"] }
        var completedBy: CompletedBy { __data["completedBy"] }
        var session: Session? { __data["session"] }
        var completedAt: String { __data["completedAt"] }

        /// AvHazardAssessment.CompletedBy
        ///
        /// Parent Type: `User`
        struct CompletedBy: AssemblyOpsAPI.SelectionSet {
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
            AVHazardAssessmentsQuery.Data.AvHazardAssessment.CompletedBy.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var firstName: String { __data["firstName"] }
          var lastName: String { __data["lastName"] }
        }

        /// AvHazardAssessment.Session
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
            AVHazardAssessmentsQuery.Data.AvHazardAssessment.Session.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
        }
      }
    }
  }

}