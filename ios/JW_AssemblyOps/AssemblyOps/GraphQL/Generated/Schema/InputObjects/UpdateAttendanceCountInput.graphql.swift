// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct UpdateAttendanceCountInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      count: GraphQLNullable<Int> = nil,
      notes: GraphQLNullable<String> = nil
    ) {
      __data = InputDict([
        "count": count,
        "notes": notes
      ])
    }

    var count: GraphQLNullable<Int> {
      get { __data["count"] }
      set { __data["count"] = newValue }
    }

    var notes: GraphQLNullable<String> {
      get { __data["notes"] }
      set { __data["notes"] = newValue }
    }
  }

}