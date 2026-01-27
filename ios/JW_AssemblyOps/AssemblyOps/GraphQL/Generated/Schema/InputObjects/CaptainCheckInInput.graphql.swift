// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct CaptainCheckInInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      assignmentId: ID,
      notes: GraphQLNullable<String> = nil
    ) {
      __data = InputDict([
        "assignmentId": assignmentId,
        "notes": notes
      ])
    }

    var assignmentId: ID {
      get { __data["assignmentId"] }
      set { __data["assignmentId"] = newValue }
    }

    var notes: GraphQLNullable<String> {
      get { __data["notes"] }
      set { __data["notes"] = newValue }
    }
  }

}