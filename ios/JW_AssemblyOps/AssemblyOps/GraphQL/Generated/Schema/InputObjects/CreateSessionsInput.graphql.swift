// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct CreateSessionsInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      eventId: ID,
      sessions: [CreateSessionInput]
    ) {
      __data = InputDict([
        "eventId": eventId,
        "sessions": sessions
      ])
    }

    var eventId: ID {
      get { __data["eventId"] }
      set { __data["eventId"] = newValue }
    }

    var sessions: [CreateSessionInput] {
      get { __data["sessions"] }
      set { __data["sessions"] = newValue }
    }
  }

}