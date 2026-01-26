// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct CreateAssignmentInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      volunteerId: ID,
      postId: ID,
      sessionId: ID
    ) {
      __data = InputDict([
        "volunteerId": volunteerId,
        "postId": postId,
        "sessionId": sessionId
      ])
    }

    var volunteerId: ID {
      get { __data["volunteerId"] }
      set { __data["volunteerId"] = newValue }
    }

    var postId: ID {
      get { __data["postId"] }
      set { __data["postId"] = newValue }
    }

    var sessionId: ID {
      get { __data["sessionId"] }
      set { __data["sessionId"] = newValue }
    }
  }

}