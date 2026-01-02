// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct CheckInInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      assignmentId: ID
    ) {
      __data = InputDict([
        "assignmentId": assignmentId
      ])
    }

    var assignmentId: ID {
      get { __data["assignmentId"] }
      set { __data["assignmentId"] = newValue }
    }
  }

}