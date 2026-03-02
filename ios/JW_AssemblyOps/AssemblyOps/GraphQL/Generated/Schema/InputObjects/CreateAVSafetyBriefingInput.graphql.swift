// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct CreateAVSafetyBriefingInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      eventId: ID,
      topic: String,
      notes: GraphQLNullable<String> = nil,
      attendeeIds: [ID]
    ) {
      __data = InputDict([
        "eventId": eventId,
        "topic": topic,
        "notes": notes,
        "attendeeIds": attendeeIds
      ])
    }

    var eventId: ID {
      get { __data["eventId"] }
      set { __data["eventId"] = newValue }
    }

    var topic: String {
      get { __data["topic"] }
      set { __data["topic"] = newValue }
    }

    var notes: GraphQLNullable<String> {
      get { __data["notes"] }
      set { __data["notes"] = newValue }
    }

    var attendeeIds: [ID] {
      get { __data["attendeeIds"] }
      set { __data["attendeeIds"] = newValue }
    }
  }

}