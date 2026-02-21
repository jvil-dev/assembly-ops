// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct CreateLostPersonAlertInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      eventId: ID,
      personName: String,
      age: GraphQLNullable<Int> = nil,
      description: String,
      lastSeenLocation: GraphQLNullable<String> = nil,
      lastSeenTime: GraphQLNullable<String> = nil,
      contactName: String,
      contactPhone: GraphQLNullable<String> = nil,
      sessionId: GraphQLNullable<ID> = nil
    ) {
      __data = InputDict([
        "eventId": eventId,
        "personName": personName,
        "age": age,
        "description": description,
        "lastSeenLocation": lastSeenLocation,
        "lastSeenTime": lastSeenTime,
        "contactName": contactName,
        "contactPhone": contactPhone,
        "sessionId": sessionId
      ])
    }

    var eventId: ID {
      get { __data["eventId"] }
      set { __data["eventId"] = newValue }
    }

    var personName: String {
      get { __data["personName"] }
      set { __data["personName"] = newValue }
    }

    var age: GraphQLNullable<Int> {
      get { __data["age"] }
      set { __data["age"] = newValue }
    }

    var description: String {
      get { __data["description"] }
      set { __data["description"] = newValue }
    }

    var lastSeenLocation: GraphQLNullable<String> {
      get { __data["lastSeenLocation"] }
      set { __data["lastSeenLocation"] = newValue }
    }

    var lastSeenTime: GraphQLNullable<String> {
      get { __data["lastSeenTime"] }
      set { __data["lastSeenTime"] = newValue }
    }

    var contactName: String {
      get { __data["contactName"] }
      set { __data["contactName"] = newValue }
    }

    var contactPhone: GraphQLNullable<String> {
      get { __data["contactPhone"] }
      set { __data["contactPhone"] = newValue }
    }

    var sessionId: GraphQLNullable<ID> {
      get { __data["sessionId"] }
      set { __data["sessionId"] = newValue }
    }
  }

}