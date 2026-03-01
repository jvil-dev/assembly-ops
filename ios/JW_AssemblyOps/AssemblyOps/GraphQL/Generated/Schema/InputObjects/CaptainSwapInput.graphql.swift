// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct CaptainSwapInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      assignmentId: ID,
      newEventVolunteerId: ID
    ) {
      __data = InputDict([
        "assignmentId": assignmentId,
        "newEventVolunteerId": newEventVolunteerId
      ])
    }

    var assignmentId: ID {
      get { __data["assignmentId"] }
      set { __data["assignmentId"] = newValue }
    }

    var newEventVolunteerId: ID {
      get { __data["newEventVolunteerId"] }
      set { __data["newEventVolunteerId"] = newValue }
    }
  }

}