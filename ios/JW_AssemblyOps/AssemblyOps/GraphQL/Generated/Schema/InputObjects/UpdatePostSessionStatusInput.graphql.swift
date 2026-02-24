// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct UpdatePostSessionStatusInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      postId: ID,
      sessionId: ID,
      status: GraphQLEnum<SeatingSectionStatus>
    ) {
      __data = InputDict([
        "postId": postId,
        "sessionId": sessionId,
        "status": status
      ])
    }

    var postId: ID {
      get { __data["postId"] }
      set { __data["postId"] = newValue }
    }

    var sessionId: ID {
      get { __data["sessionId"] }
      set { __data["sessionId"] = newValue }
    }

    var status: GraphQLEnum<SeatingSectionStatus> {
      get { __data["status"] }
      set { __data["status"] = newValue }
    }
  }

}