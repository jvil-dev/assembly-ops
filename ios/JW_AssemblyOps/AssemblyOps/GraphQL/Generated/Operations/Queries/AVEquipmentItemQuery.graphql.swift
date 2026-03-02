// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class AVEquipmentItemQuery: GraphQLQuery {
    static let operationName: String = "AVEquipmentItem"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query AVEquipmentItem($id: ID!) { avEquipmentItem(id: $id) { __typename id name model serialNumber category condition location notes area { __typename id name } currentCheckout { __typename id checkedOutBy { __typename id user { __typename firstName lastName } } checkedOutAt session { __typename id name } notes } checkoutHistory { __typename id checkedOutBy { __typename id user { __typename firstName lastName } } checkedOutAt checkedInAt session { __typename id name } notes } damageReports { __typename id description severity resolved resolvedAt resolutionNotes reportedBy { __typename id user { __typename firstName lastName } } session { __typename id name } createdAt } createdAt updatedAt } }"#
      ))

    public var id: ID

    public init(id: ID) {
      self.id = id
    }

    public var __variables: Variables? { ["id": id] }

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("avEquipmentItem", AvEquipmentItem?.self, arguments: ["id": .variable("id")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        AVEquipmentItemQuery.Data.self
      ] }

      var avEquipmentItem: AvEquipmentItem? { __data["avEquipmentItem"] }

      /// AvEquipmentItem
      ///
      /// Parent Type: `AVEquipmentItem`
      struct AvEquipmentItem: AssemblyOpsAPI.SelectionSet {
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
          .field("checkoutHistory", [CheckoutHistory].self),
          .field("damageReports", [DamageReport].self),
          .field("createdAt", String.self),
          .field("updatedAt", String.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          AVEquipmentItemQuery.Data.AvEquipmentItem.self
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
        var checkoutHistory: [CheckoutHistory] { __data["checkoutHistory"] }
        var damageReports: [DamageReport] { __data["damageReports"] }
        var createdAt: String { __data["createdAt"] }
        var updatedAt: String { __data["updatedAt"] }

        /// AvEquipmentItem.Area
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
            AVEquipmentItemQuery.Data.AvEquipmentItem.Area.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
        }

        /// AvEquipmentItem.CurrentCheckout
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
            AVEquipmentItemQuery.Data.AvEquipmentItem.CurrentCheckout.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var checkedOutBy: CheckedOutBy { __data["checkedOutBy"] }
          var checkedOutAt: String { __data["checkedOutAt"] }
          var session: Session? { __data["session"] }
          var notes: String? { __data["notes"] }

          /// AvEquipmentItem.CurrentCheckout.CheckedOutBy
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
              AVEquipmentItemQuery.Data.AvEquipmentItem.CurrentCheckout.CheckedOutBy.self
            ] }

            var id: AssemblyOpsAPI.ID { __data["id"] }
            var user: User { __data["user"] }

            /// AvEquipmentItem.CurrentCheckout.CheckedOutBy.User
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
                AVEquipmentItemQuery.Data.AvEquipmentItem.CurrentCheckout.CheckedOutBy.User.self
              ] }

              var firstName: String { __data["firstName"] }
              var lastName: String { __data["lastName"] }
            }
          }

          /// AvEquipmentItem.CurrentCheckout.Session
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
              AVEquipmentItemQuery.Data.AvEquipmentItem.CurrentCheckout.Session.self
            ] }

            var id: AssemblyOpsAPI.ID { __data["id"] }
            var name: String { __data["name"] }
          }
        }

        /// AvEquipmentItem.CheckoutHistory
        ///
        /// Parent Type: `AVEquipmentCheckout`
        struct CheckoutHistory: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.AVEquipmentCheckout }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("checkedOutBy", CheckedOutBy.self),
            .field("checkedOutAt", String.self),
            .field("checkedInAt", String?.self),
            .field("session", Session?.self),
            .field("notes", String?.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            AVEquipmentItemQuery.Data.AvEquipmentItem.CheckoutHistory.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var checkedOutBy: CheckedOutBy { __data["checkedOutBy"] }
          var checkedOutAt: String { __data["checkedOutAt"] }
          var checkedInAt: String? { __data["checkedInAt"] }
          var session: Session? { __data["session"] }
          var notes: String? { __data["notes"] }

          /// AvEquipmentItem.CheckoutHistory.CheckedOutBy
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
              AVEquipmentItemQuery.Data.AvEquipmentItem.CheckoutHistory.CheckedOutBy.self
            ] }

            var id: AssemblyOpsAPI.ID { __data["id"] }
            var user: User { __data["user"] }

            /// AvEquipmentItem.CheckoutHistory.CheckedOutBy.User
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
                AVEquipmentItemQuery.Data.AvEquipmentItem.CheckoutHistory.CheckedOutBy.User.self
              ] }

              var firstName: String { __data["firstName"] }
              var lastName: String { __data["lastName"] }
            }
          }

          /// AvEquipmentItem.CheckoutHistory.Session
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
              AVEquipmentItemQuery.Data.AvEquipmentItem.CheckoutHistory.Session.self
            ] }

            var id: AssemblyOpsAPI.ID { __data["id"] }
            var name: String { __data["name"] }
          }
        }

        /// AvEquipmentItem.DamageReport
        ///
        /// Parent Type: `AVDamageReport`
        struct DamageReport: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.AVDamageReport }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("description", String.self),
            .field("severity", GraphQLEnum<AssemblyOpsAPI.AVDamageSeverity>.self),
            .field("resolved", Bool.self),
            .field("resolvedAt", String?.self),
            .field("resolutionNotes", String?.self),
            .field("reportedBy", ReportedBy.self),
            .field("session", Session?.self),
            .field("createdAt", String.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            AVEquipmentItemQuery.Data.AvEquipmentItem.DamageReport.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var description: String { __data["description"] }
          var severity: GraphQLEnum<AssemblyOpsAPI.AVDamageSeverity> { __data["severity"] }
          var resolved: Bool { __data["resolved"] }
          var resolvedAt: String? { __data["resolvedAt"] }
          var resolutionNotes: String? { __data["resolutionNotes"] }
          var reportedBy: ReportedBy { __data["reportedBy"] }
          var session: Session? { __data["session"] }
          var createdAt: String { __data["createdAt"] }

          /// AvEquipmentItem.DamageReport.ReportedBy
          ///
          /// Parent Type: `EventVolunteer`
          struct ReportedBy: AssemblyOpsAPI.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.EventVolunteer }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", AssemblyOpsAPI.ID.self),
              .field("user", User.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              AVEquipmentItemQuery.Data.AvEquipmentItem.DamageReport.ReportedBy.self
            ] }

            var id: AssemblyOpsAPI.ID { __data["id"] }
            var user: User { __data["user"] }

            /// AvEquipmentItem.DamageReport.ReportedBy.User
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
                AVEquipmentItemQuery.Data.AvEquipmentItem.DamageReport.ReportedBy.User.self
              ] }

              var firstName: String { __data["firstName"] }
              var lastName: String { __data["lastName"] }
            }
          }

          /// AvEquipmentItem.DamageReport.Session
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
              AVEquipmentItemQuery.Data.AvEquipmentItem.DamageReport.Session.self
            ] }

            var id: AssemblyOpsAPI.ID { __data["id"] }
            var name: String { __data["name"] }
          }
        }
      }
    }
  }

}