// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct SetCanCountInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      assignmentId: ID,
      canCount: Bool
    ) {
      __data = InputDict([
        "assignmentId": assignmentId,
        "canCount": canCount
      ])
    }

    var assignmentId: ID {
      get { __data["assignmentId"] }
      set { __data["assignmentId"] = newValue }
    }

    var canCount: Bool {
      get { __data["canCount"] }
      set { __data["canCount"] = newValue }
    }
  }

}