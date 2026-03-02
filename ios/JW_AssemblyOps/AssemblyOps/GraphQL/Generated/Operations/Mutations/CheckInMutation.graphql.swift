// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class CheckInMutation: GraphQLMutation {
    static let operationName: String = "CheckIn"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation CheckIn($input: CheckInInput!) { checkIn(input: $input) { __typename id status checkInTime assignment { __typename id isCheckedIn } } }"#
      ))

    public var input: CheckInInput

    public init(input: CheckInInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("checkIn", CheckIn.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CheckInMutation.Data.self
      ] }

      var checkIn: CheckIn { __data["checkIn"] }

      /// CheckIn
      ///
      /// Parent Type: `CheckIn`
      struct CheckIn: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.CheckIn }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("status", GraphQLEnum<AssemblyOpsAPI.CheckInStatus>.self),
          .field("checkInTime", AssemblyOpsAPI.DateTime.self),
          .field("assignment", Assignment.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          CheckInMutation.Data.CheckIn.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var status: GraphQLEnum<AssemblyOpsAPI.CheckInStatus> { __data["status"] }
        var checkInTime: AssemblyOpsAPI.DateTime { __data["checkInTime"] }
        var assignment: Assignment { __data["assignment"] }

        /// CheckIn.Assignment
        ///
        /// Parent Type: `ScheduleAssignment`
        struct Assignment: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.ScheduleAssignment }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("isCheckedIn", Bool.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            CheckInMutation.Data.CheckIn.Assignment.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var isCheckedIn: Bool { __data["isCheckedIn"] }
        }
      }
    }
  }

}