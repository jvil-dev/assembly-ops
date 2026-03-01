// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct SubmitWalkThroughCompletionInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      eventId: ID,
      sessionId: ID,
      itemCount: Int,
      notes: GraphQLNullable<String> = nil,
      checklistType: GraphQLNullable<String> = nil
    ) {
      __data = InputDict([
        "eventId": eventId,
        "sessionId": sessionId,
        "itemCount": itemCount,
        "notes": notes,
        "checklistType": checklistType
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

    var itemCount: Int {
      get { __data["itemCount"] }
      set { __data["itemCount"] = newValue }
    }

    var notes: GraphQLNullable<String> {
      get { __data["notes"] }
      set { __data["notes"] = newValue }
    }

    var checklistType: GraphQLNullable<String> {
      get { __data["checklistType"] }
      set { __data["checklistType"] = newValue }
    }
  }

}