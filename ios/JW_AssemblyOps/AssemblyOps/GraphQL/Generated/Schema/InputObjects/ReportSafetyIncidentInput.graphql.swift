// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct ReportSafetyIncidentInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      eventId: ID,
      type: GraphQLEnum<SafetyIncidentType>,
      description: String,
      location: GraphQLNullable<String> = nil,
      postId: GraphQLNullable<ID> = nil,
      sessionId: GraphQLNullable<ID> = nil
    ) {
      __data = InputDict([
        "eventId": eventId,
        "type": type,
        "description": description,
        "location": location,
        "postId": postId,
        "sessionId": sessionId
      ])
    }

    var eventId: ID {
      get { __data["eventId"] }
      set { __data["eventId"] = newValue }
    }

    var type: GraphQLEnum<SafetyIncidentType> {
      get { __data["type"] }
      set { __data["type"] = newValue }
    }

    var description: String {
      get { __data["description"] }
      set { __data["description"] = newValue }
    }

    var location: GraphQLNullable<String> {
      get { __data["location"] }
      set { __data["location"] = newValue }
    }

    var postId: GraphQLNullable<ID> {
      get { __data["postId"] }
      set { __data["postId"] = newValue }
    }

    var sessionId: GraphQLNullable<ID> {
      get { __data["sessionId"] }
      set { __data["sessionId"] = newValue }
    }
  }

}