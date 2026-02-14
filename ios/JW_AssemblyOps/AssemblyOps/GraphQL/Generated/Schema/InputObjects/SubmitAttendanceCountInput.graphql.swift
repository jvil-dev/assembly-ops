// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct SubmitAttendanceCountInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      sessionId: ID,
      section: GraphQLNullable<String> = nil,
      count: Int,
      notes: GraphQLNullable<String> = nil
    ) {
      __data = InputDict([
        "sessionId": sessionId,
        "section": section,
        "count": count,
        "notes": notes
      ])
    }

    var sessionId: ID {
      get { __data["sessionId"] }
      set { __data["sessionId"] = newValue }
    }

    var section: GraphQLNullable<String> {
      get { __data["section"] }
      set { __data["section"] = newValue }
    }

    var count: Int {
      get { __data["count"] }
      set { __data["count"] = newValue }
    }

    var notes: GraphQLNullable<String> {
      get { __data["notes"] }
      set { __data["notes"] = newValue }
    }
  }

}