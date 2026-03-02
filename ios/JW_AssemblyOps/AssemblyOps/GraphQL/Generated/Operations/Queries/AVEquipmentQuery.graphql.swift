// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class AVEquipmentQuery: GraphQLQuery {
    static let operationName: String = "AVEquipment"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query AVEquipment($eventId: ID!, $category: AVEquipmentCategory, $areaId: ID) { avEquipment(eventId: $eventId, category: $category, areaId: $areaId) { __typename id name model serialNumber category condition location notes area { __typename id name } currentCheckout { __typename id checkedOutBy { __typename id user { __typename firstName lastName } } checkedOutAt session { __typename id name } notes } createdAt updatedAt } }"#
      ))

    public var eventId: ID
    public var category: GraphQLNullable<GraphQLEnum<AVEquipmentCategory>>
    public var areaId: GraphQLNullable<ID>

    public init(
      eventId: ID,
      category: GraphQLNullable<GraphQLEnum<AVEquipmentCategory>>,
      areaId: GraphQLNullable<ID>
    ) {
      self.eventId = eventId
      self.category = category
      self.areaId = areaId
    }

    public var __variables: Variables? { [
      "eventId": eventId,
      "category": category,
      "areaId": areaId
    ] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("avEquipment", [AvEquipment].self, arguments: [
          "eventId": .variable("eventId"),
          "category": .variable("category"),
          "areaId": .variable("areaId")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        AVEquipmentQuery.Data.self
      ] }

      var avEquipment: [AvEquipment] { __data["avEquipment"] }

      /// AvEquipment
      ///
      /// Parent Type: `AVEquipmentItem`
      struct AvEquipment: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.AVEquipmentItem }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("name", String.self),
          .field("model", String?.self),
          .field("serialNumber", String?.self),
          .field("category", GraphQLEnum<AssemblyOpsAPI.AVEquipmentCategory>.self),
          .field("condition", GraphQLEnum<AssemblyOpsAPI.AVEquipmentCondition>.self),
          .field("location", String?.self),
          .field("notes", String?.self),
          .field("area", Area?.self),
          .field("currentCheckout", CurrentCheckout?.self),
          .field("createdAt", String.self),
          .field("updatedAt", String.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          AVEquipmentQuery.Data.AvEquipment.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var name: String { __data["name"] }
        var model: String? { __data["model"] }
        var serialNumber: String? { __data["serialNumber"] }
        var category: GraphQLEnum<AssemblyOpsAPI.AVEquipmentCategory> { __data["category"] }
        var condition: GraphQLEnum<AssemblyOpsAPI.AVEquipmentCondition> { __data["condition"] }
        var location: String? { __data["location"] }
        var notes: String? { __data["notes"] }
        var area: Area? { __data["area"] }
        var currentCheckout: CurrentCheckout? { __data["currentCheckout"] }
        var createdAt: String { __data["createdAt"] }
        var updatedAt: String { __data["updatedAt"] }

        /// AvEquipment.Area
        ///
        /// Parent Type: `Area`
        struct Area: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Area }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("name", String.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            AVEquipmentQuery.Data.AvEquipment.Area.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
        }

        /// AvEquipment.CurrentCheckout
        ///
        /// Parent Type: `AVEquipmentCheckout`
        struct CurrentCheckout: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.AVEquipmentCheckout }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("checkedOutBy", CheckedOutBy.self),
            .field("checkedOutAt", String.self),
            .field("session", Session?.self),
            .field("notes", String?.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            AVEquipmentQuery.Data.AvEquipment.CurrentCheckout.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var checkedOutBy: CheckedOutBy { __data["checkedOutBy"] }
          var checkedOutAt: String { __data["checkedOutAt"] }
          var session: Session? { __data["session"] }
          var notes: String? { __data["notes"] }

          /// AvEquipment.CurrentCheckout.CheckedOutBy
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
              AVEquipmentQuery.Data.AvEquipment.CurrentCheckout.CheckedOutBy.self
            ] }

            var id: AssemblyOpsAPI.ID { __data["id"] }
            var user: User { __data["user"] }

            /// AvEquipment.CurrentCheckout.CheckedOutBy.User
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
                AVEquipmentQuery.Data.AvEquipment.CurrentCheckout.CheckedOutBy.User.self
              ] }

              var firstName: String { __data["firstName"] }
              var lastName: String { __data["lastName"] }
            }
          }

          /// AvEquipment.CurrentCheckout.Session
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
              AVEquipmentQuery.Data.AvEquipment.CurrentCheckout.Session.self
            ] }

            var id: AssemblyOpsAPI.ID { __data["id"] }
            var name: String { __data["name"] }
          }
        }
      }
    }
  }

}