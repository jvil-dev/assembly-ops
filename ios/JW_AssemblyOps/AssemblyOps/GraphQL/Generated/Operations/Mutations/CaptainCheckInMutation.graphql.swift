// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class CaptainCheckInMutation: GraphQLMutation {
    static let operationName: String = "CaptainCheckIn"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation CaptainCheckIn($input: CaptainCheckInInput!) { captainCheckIn(input: $input) { __typename id status isCaptain checkIn { __typename id status checkInTime notes } } }"#
      ))

    public var input: CaptainCheckInInput

    public init(input: CaptainCheckInInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("captainCheckIn", CaptainCheckIn.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CaptainCheckInMutation.Data.self
      ] }

      var captainCheckIn: CaptainCheckIn { __data["captainCheckIn"] }

      /// CaptainCheckIn
      ///
      /// Parent Type: `ScheduleAssignment`
      struct CaptainCheckIn: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.ScheduleAssignment }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("status", GraphQLEnum<AssemblyOpsAPI.AssignmentStatus>.self),
          .field("isCaptain", Bool.self),
          .field("checkIn", CheckIn?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          CaptainCheckInMutation.Data.CaptainCheckIn.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var status: GraphQLEnum<AssemblyOpsAPI.AssignmentStatus> { __data["status"] }
        var isCaptain: Bool { __data["isCaptain"] }
        var checkIn: CheckIn? { __data["checkIn"] }

        /// CaptainCheckIn.CheckIn
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
            .field("notes", String?.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            CaptainCheckInMutation.Data.CaptainCheckIn.CheckIn.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var status: GraphQLEnum<AssemblyOpsAPI.CheckInStatus> { __data["status"] }
          var checkInTime: AssemblyOpsAPI.DateTime { __data["checkInTime"] }
          var notes: String? { __data["notes"] }
        }
      }
    }
  }

}