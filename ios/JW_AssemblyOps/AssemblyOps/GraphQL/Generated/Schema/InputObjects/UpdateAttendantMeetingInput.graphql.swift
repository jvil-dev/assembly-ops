// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct UpdateAttendantMeetingInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      id: ID,
      name: GraphQLNullable<String> = nil,
      meetingDate: GraphQLNullable<String> = nil,
      notes: GraphQLNullable<String> = nil,
      attendeeIds: GraphQLNullable<[ID]> = nil
    ) {
      __data = InputDict([
        "id": id,
        "name": name,
        "meetingDate": meetingDate,
        "notes": notes,
        "attendeeIds": attendeeIds
      ])
    }

    var id: ID {
      get { __data["id"] }
      set { __data["id"] = newValue }
    }

    var name: GraphQLNullable<String> {
      get { __data["name"] }
      set { __data["name"] = newValue }
    }

    var meetingDate: GraphQLNullable<String> {
      get { __data["meetingDate"] }
      set { __data["meetingDate"] = newValue }
    }

    var notes: GraphQLNullable<String> {
      get { __data["notes"] }
      set { __data["notes"] = newValue }
    }

    var attendeeIds: GraphQLNullable<[ID]> {
      get { __data["attendeeIds"] }
      set { __data["attendeeIds"] = newValue }
    }
  }

}