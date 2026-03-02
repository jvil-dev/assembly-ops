// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class CheckOutMutation: GraphQLMutation {
    static let operationName: String = "CheckOut"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation CheckOut($input: CheckOutInput!) { checkOut(input: $input) { __typename id status checkInTime checkOutTime assignment { __typename id isCheckedIn } } }"#
      ))

    public var input: CheckOutInput

    public init(input: CheckOutInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("checkOut", CheckOut.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CheckOutMutation.Data.self
      ] }

      var checkOut: CheckOut { __data["checkOut"] }

      /// CheckOut
      ///
      /// Parent Type: `CheckIn`
      struct CheckOut: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.CheckIn }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("status", GraphQLEnum<AssemblyOpsAPI.CheckInStatus>.self),
          .field("checkInTime", AssemblyOpsAPI.DateTime.self),
          .field("checkOutTime", AssemblyOpsAPI.DateTime?.self),
          .field("assignment", Assignment.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          CheckOutMutation.Data.CheckOut.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var status: GraphQLEnum<AssemblyOpsAPI.CheckInStatus> { __data["status"] }
        var checkInTime: AssemblyOpsAPI.DateTime { __data["checkInTime"] }
        var checkOutTime: AssemblyOpsAPI.DateTime? { __data["checkOutTime"] }
        var assignment: Assignment { __data["assignment"] }

        /// CheckOut.Assignment
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
            CheckOutMutation.Data.CheckOut.Assignment.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var isCheckedIn: Bool { __data["isCheckedIn"] }
        }
      }
    }
  }

}