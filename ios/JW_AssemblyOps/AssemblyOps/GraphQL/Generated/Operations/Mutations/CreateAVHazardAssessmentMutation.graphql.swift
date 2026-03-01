// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class CreateAVHazardAssessmentMutation: GraphQLMutation {
    static let operationName: String = "CreateAVHazardAssessment"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation CreateAVHazardAssessment($input: CreateAVHazardAssessmentInput!) { createAVHazardAssessment(input: $input) { __typename id title hazardType description controls ppeRequired completedBy { __typename id firstName lastName } session { __typename id name } completedAt } }"#
      ))

    public var input: CreateAVHazardAssessmentInput

    public init(input: CreateAVHazardAssessmentInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("createAVHazardAssessment", CreateAVHazardAssessment.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CreateAVHazardAssessmentMutation.Data.self
      ] }

      var createAVHazardAssessment: CreateAVHazardAssessment { __data["createAVHazardAssessment"] }

      /// CreateAVHazardAssessment
      ///
      /// Parent Type: `AVHazardAssessment`
      struct CreateAVHazardAssessment: AssemblyOpsAPI.SelectionSet {
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
          CreateAVHazardAssessmentMutation.Data.CreateAVHazardAssessment.self
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

        /// CreateAVHazardAssessment.CompletedBy
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
            CreateAVHazardAssessmentMutation.Data.CreateAVHazardAssessment.CompletedBy.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var firstName: String { __data["firstName"] }
          var lastName: String { __data["lastName"] }
        }

        /// CreateAVHazardAssessment.Session
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
            CreateAVHazardAssessmentMutation.Data.CreateAVHazardAssessment.Session.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
        }
      }
    }
  }

}