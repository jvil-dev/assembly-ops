// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct CreateAttendantMeetingInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      eventId: ID,
      sessionId: ID,
      meetingDate: String,
      notes: GraphQLNullable<String> = nil,
      attendeeIds: [ID]
    ) {
      __data = InputDict([
        "eventId": eventId,
        "sessionId": sessionId,
        "meetingDate": meetingDate,
        "notes": notes,
        "attendeeIds": attendeeIds
      ])
    }

    var eventId: ID {
      get { __data["eventId"] }
      set { __data["eventId"] = newValue }
    }

    var sessionId: ID {
      get { __data["sessionId"] }
      set { __data["sessionId"] = newValue }
    }

    var meetingDate: String {
      get { __data["meetingDate"] }
      set { __data["meetingDate"] = newValue }
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