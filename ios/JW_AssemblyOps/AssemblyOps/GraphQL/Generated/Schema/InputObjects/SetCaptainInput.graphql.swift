// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct SetCaptainInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      assignmentId: ID,
      isCaptain: Bool
    ) {
      __data = InputDict([
        "assignmentId": assignmentId,
        "isCaptain": isCaptain
      ])
    }

    var assignmentId: ID {
      get { __data["assignmentId"] }
      set { __data["assignmentId"] = newValue }
    }

    var isCaptain: Bool {
      get { __data["isCaptain"] }
      set { __data["isCaptain"] = newValue }
    }
  }

}