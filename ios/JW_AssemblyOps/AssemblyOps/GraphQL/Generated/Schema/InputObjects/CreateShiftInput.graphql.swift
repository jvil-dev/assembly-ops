// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct CreateShiftInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      sessionId: ID,
      postId: ID,
      startTime: String,
      endTime: String
    ) {
      __data = InputDict([
        "sessionId": sessionId,
        "postId": postId,
        "startTime": startTime,
        "endTime": endTime
      ])
    }

    var sessionId: ID {
      get { __data["sessionId"] }
      set { __data["sessionId"] = newValue }
    }

    var postId: ID {
      get { __data["postId"] }
      set { __data["postId"] = newValue }
    }

    var startTime: String {
      get { __data["startTime"] }
      set { __data["startTime"] = newValue }
    }

    var endTime: String {
      get { __data["endTime"] }
      set { __data["endTime"] = newValue }
    }
  }

}