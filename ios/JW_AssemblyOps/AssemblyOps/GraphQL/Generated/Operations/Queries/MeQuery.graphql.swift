// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension AssemblyOpsAPI {
  class MeQuery: GraphQLQuery {
    static let operationName: String = "Me"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query Me { me { __typename id userId email firstName lastName fullName phone congregation congregationId appointmentStatus isOverseer congregationRef { __typename id name city state circuit { __typename id code } } } }"#
      ))

    public init() {}

    struct Data: AssemblyOpsAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("me", Me?.self),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        MeQuery.Data.self
      ] }

      var me: Me? { __data["me"] }

      /// Me
      ///
      /// Parent Type: `User`
      struct Me: AssemblyOpsAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.User }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", AssemblyOpsAPI.ID.self),
          .field("userId", String.self),
          .field("email", String.self),
          .field("firstName", String.self),
          .field("lastName", String.self),
          .field("fullName", String.self),
          .field("phone", String?.self),
          .field("congregation", String?.self),
          .field("congregationId", AssemblyOpsAPI.ID?.self),
          .field("appointmentStatus", GraphQLEnum<AssemblyOpsAPI.AppointmentStatus>?.self),
          .field("isOverseer", Bool.self),
          .field("congregationRef", CongregationRef?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          MeQuery.Data.Me.self
        ] }

        var id: AssemblyOpsAPI.ID { __data["id"] }
        var userId: String { __data["userId"] }
        var email: String { __data["email"] }
        var firstName: String { __data["firstName"] }
        var lastName: String { __data["lastName"] }
        var fullName: String { __data["fullName"] }
        var phone: String? { __data["phone"] }
        var congregation: String? { __data["congregation"] }
        var congregationId: AssemblyOpsAPI.ID? { __data["congregationId"] }
        var appointmentStatus: GraphQLEnum<AssemblyOpsAPI.AppointmentStatus>? { __data["appointmentStatus"] }
        var isOverseer: Bool { __data["isOverseer"] }
        var congregationRef: CongregationRef? { __data["congregationRef"] }

        /// Me.CongregationRef
        ///
        /// Parent Type: `Congregation`
        struct CongregationRef: AssemblyOpsAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Congregation }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", AssemblyOpsAPI.ID.self),
            .field("name", String.self),
            .field("city", String.self),
            .field("state", String.self),
            .field("circuit", Circuit.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            MeQuery.Data.Me.CongregationRef.self
          ] }

          var id: AssemblyOpsAPI.ID { __data["id"] }
          var name: String { __data["name"] }
          var city: String { __data["city"] }
          var state: String { __data["state"] }
          var circuit: Circuit { __data["circuit"] }

          /// Me.CongregationRef.Circuit
          ///
          /// Parent Type: `Circuit`
          struct Circuit: AssemblyOpsAPI.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { AssemblyOpsAPI.Objects.Circuit }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", AssemblyOpsAPI.ID.self),
              .field("code", String.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              MeQuery.Data.Me.CongregationRef.Circuit.self
            ] }

            var id: AssemblyOpsAPI.ID { __data["id"] }
            var code: String { __data["code"] }
          }
        }
      }
    }
  }

}