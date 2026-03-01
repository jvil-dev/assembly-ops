// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class AVEquipmentCheckoutsQuery: GraphQLQuery {
    static let operationName: String = "AVEquipmentCheckouts"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query AVEquipmentCheckouts($eventId: ID!, $checkedIn: Boolean) { avEquipmentCheckouts(eventId: $eventId, checkedIn: $checkedIn) { __typename id equipment { __typename id name category } checkedOutBy { __typename id user { __typename firstName lastName } } checkedOutAt checkedInAt session { __typename id name } notes } }"#
      ))

    public var eventId: ID
    public var checkedIn: GraphQLNullable<Bool>

    public init(
      eventId: ID,
      checkedIn: GraphQLNullable<Bool>
    ) {
      self.eventId = eventId
      self.checkedIn = checkedIn
    }

    public var __variables: Variables? { [
      "eventId": eventId,
      "checkedIn": checkedIn
    ] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("avEquipmentCheckouts", [AvEquipmentCheckout].self, arguments: [
          "eventId": .variable("eventId"),
          "checkedIn": .variable("checkedIn")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        AVEquipmentCheckoutsQuery.Data.self
      ] }

      var avEquipmentCheckouts: [AvEquipmentCheckout] { __data["avEquipmentCheckouts"] }

      /// AvEquipmentCheckout
      ///
      /// Parent Type: `AVEquipmentCheckout`
      struct AvEquipmentCheckout: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.AVEquipmentCheckout }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("equipment", Equipment.self),
          .field("checkedOutBy", CheckedOutBy.self),
          .field("checkedOutAt", String.self),
          .field("checkedInAt", String?.self),
          .field("session", Session?.self),
          .field("notes", String?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          AVEquipmentCheckoutsQuery.Data.AvEquipmentCheckout.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var equipment: Equipment { __data["equipment"] }
        var checkedOutBy: CheckedOutBy { __data["checkedOutBy"] }
        var checkedOutAt: String { __data["checkedOutAt"] }
        var checkedInAt: String? { __data["checkedInAt"] }
        var session: Session? { __data["session"] }
        var notes: String? { __data["notes"] }

        /// AvEquipmentCheckout.Equipment
        ///
        /// Parent Type: `AVEquipmentItem`
        struct Equipment: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.AVEquipmentItem }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("name", String.self),
            .field("category", GraphQLEnum<AssemblyOpsAPI.AVEquipmentCategory>.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            AVEquipmentCheckoutsQuery.Data.AvEquipmentCheckout.Equipment.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
          var category: GraphQLEnum<AssemblyOpsAPI.AVEquipmentCategory> { __data["category"] }
        }

        /// AvEquipmentCheckout.CheckedOutBy
        ///
        /// Parent Type: `EventVolunteer`
        struct CheckedOutBy: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.EventVolunteer }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("user", User.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            AVEquipmentCheckoutsQuery.Data.AvEquipmentCheckout.CheckedOutBy.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var user: User { __data["user"] }

          /// AvEquipmentCheckout.CheckedOutBy.User
          ///
          /// Parent Type: `User`
          struct User: AssemblyOpsAPI.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.User }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("firstName", String.self),
              .field("lastName", String.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              AVEquipmentCheckoutsQuery.Data.AvEquipmentCheckout.CheckedOutBy.User.self
            ] }

            var firstName: String { __data["firstName"] }
            var lastName: String { __data["lastName"] }
          }
        }

        /// AvEquipmentCheckout.Session
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
            AVEquipmentCheckoutsQuery.Data.AvEquipmentCheckout.Session.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
        }
      }
    }
  }

}