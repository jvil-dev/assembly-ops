// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class AVEquipmentSummaryQuery: GraphQLQuery {
    static let operationName: String = "AVEquipmentSummary"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query AVEquipmentSummary($eventId: ID!) { avEquipmentSummary(eventId: $eventId) { __typename totalItems checkedOutCount needsRepairCount outOfServiceCount byCategory { __typename category count checkedOutCount } } }"#
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
        .field("avEquipmentSummary", AvEquipmentSummary.self, arguments: ["eventId": .variable("eventId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        AVEquipmentSummaryQuery.Data.self
      ] }

      var avEquipmentSummary: AvEquipmentSummary { __data["avEquipmentSummary"] }

      /// AvEquipmentSummary
      ///
      /// Parent Type: `AVEquipmentSummary`
      struct AvEquipmentSummary: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.AVEquipmentSummary }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("totalItems", Int.self),
          .field("checkedOutCount", Int.self),
          .field("needsRepairCount", Int.self),
          .field("outOfServiceCount", Int.self),
          .field("byCategory", [ByCategory].self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          AVEquipmentSummaryQuery.Data.AvEquipmentSummary.self
        ] }

        var totalItems: Int { __data["totalItems"] }
        var checkedOutCount: Int { __data["checkedOutCount"] }
        var needsRepairCount: Int { __data["needsRepairCount"] }
        var outOfServiceCount: Int { __data["outOfServiceCount"] }
        var byCategory: [ByCategory] { __data["byCategory"] }

        /// AvEquipmentSummary.ByCategory
        ///
        /// Parent Type: `AVCategorySummary`
        struct ByCategory: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.AVCategorySummary }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("category", GraphQLEnum<AssemblyOpsAPI.AVEquipmentCategory>.self),
            .field("count", Int.self),
            .field("checkedOutCount", Int.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            AVEquipmentSummaryQuery.Data.AvEquipmentSummary.ByCategory.self
          ] }

          var category: GraphQLEnum<AssemblyOpsAPI.AVEquipmentCategory> { __data["category"] }
          var count: Int { __data["count"] }
          var checkedOutCount: Int { __data["checkedOutCount"] }
        }
      }
    }
  }

}