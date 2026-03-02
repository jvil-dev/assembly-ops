// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class ShiftReminderStatusQuery: GraphQLQuery {
    static let operationName: String = "ShiftReminderStatus"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query ShiftReminderStatus($shiftId: ID!) { shiftReminderStatus(shiftId: $shiftId) { __typename shiftId shiftName totalAssigned totalConfirmed confirmations { __typename eventVolunteerId firstName lastName confirmed confirmedAt } } }"#
      ))

    public var shiftId: ID

    public init(shiftId: ID) {
      self.shiftId = shiftId
    }

    public var __variables: Variables? { ["shiftId": shiftId] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("shiftReminderStatus", ShiftReminderStatus.self, arguments: ["shiftId": .variable("shiftId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        ShiftReminderStatusQuery.Data.self
      ] }

      var shiftReminderStatus: ShiftReminderStatus { __data["shiftReminderStatus"] }

      /// ShiftReminderStatus
      ///
      /// Parent Type: `ShiftReminderStatus`
      struct ShiftReminderStatus: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.ShiftReminderStatus }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("shiftId", AssemblyOpsAPI.ID.self),
          .field("shiftName", String.self),
          .field("totalAssigned", Int.self),
          .field("totalConfirmed", Int.self),
          .field("confirmations", [Confirmation].self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          ShiftReminderStatusQuery.Data.ShiftReminderStatus.self
        ] }

        var shiftId: AssemblyOpsAPI.ID { __data["shiftId"] }
        var shiftName: String { __data["shiftName"] }
        var totalAssigned: Int { __data["totalAssigned"] }
        var totalConfirmed: Int { __data["totalConfirmed"] }
        var confirmations: [Confirmation] { __data["confirmations"] }

        /// ShiftReminderStatus.Confirmation
        ///
        /// Parent Type: `ReminderVolunteerStatus`
        struct Confirmation: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.ReminderVolunteerStatus }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("eventVolunteerId", AssemblyOpsAPI.ID.self),
            .field("firstName", String.self),
            .field("lastName", String.self),
            .field("confirmed", Bool.self),
            .field("confirmedAt", AssemblyOpsAPI.DateTime?.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            ShiftReminderStatusQuery.Data.ShiftReminderStatus.Confirmation.self
          ] }

          var eventVolunteerId: AssemblyOpsAPI.ID { __data["eventVolunteerId"] }
          var firstName: String { __data["firstName"] }
          var lastName: String { __data["lastName"] }
          var confirmed: Bool { __data["confirmed"] }
          var confirmedAt: AssemblyOpsAPI.DateTime? { __data["confirmedAt"] }
        }
      }
    }
  }

}