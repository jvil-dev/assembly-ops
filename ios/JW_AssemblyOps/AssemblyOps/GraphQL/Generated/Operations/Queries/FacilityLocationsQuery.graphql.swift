// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class FacilityLocationsQuery: GraphQLQuery {
    static let operationName: String = "FacilityLocations"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query FacilityLocations($eventId: ID!) { facilityLocations(eventId: $eventId) { __typename id name location description sortOrder } }"#
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
        .field("facilityLocations", [FacilityLocation].self, arguments: ["eventId": .variable("eventId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        FacilityLocationsQuery.Data.self
      ] }

      var facilityLocations: [FacilityLocation] { __data["facilityLocations"] }

      /// FacilityLocation
      ///
      /// Parent Type: `FacilityLocation`
      struct FacilityLocation: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.FacilityLocation }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("name", String.self),
          .field("location", String.self),
          .field("description", String?.self),
          .field("sortOrder", Int.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          FacilityLocationsQuery.Data.FacilityLocation.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var name: String { __data["name"] }
        var location: String { __data["location"] }
        var description: String? { __data["description"] }
        var sortOrder: Int { __data["sortOrder"] }
      }
    }
  }

}