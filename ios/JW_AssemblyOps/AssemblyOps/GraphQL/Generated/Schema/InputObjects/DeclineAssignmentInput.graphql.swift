// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct DeclineAssignmentInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      assignmentId: ID,
      reason: GraphQLNullable<String> = nil
    ) {
      __data = InputDict([
        "assignmentId": assignmentId,
        "reason": reason
      ])
    }

    var assignmentId: ID {
      get { __data["assignmentId"] }
      set { __data["assignmentId"] = newValue }
    }

    var reason: GraphQLNullable<String> {
      get { __data["reason"] }
      set { __data["reason"] = newValue }
    }
  }

}