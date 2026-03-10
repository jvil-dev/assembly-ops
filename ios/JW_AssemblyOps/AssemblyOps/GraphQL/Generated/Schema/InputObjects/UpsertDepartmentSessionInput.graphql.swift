// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct UpsertDepartmentSessionInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      startTime: GraphQLNullable<String> = nil,
      endTime: GraphQLNullable<String> = nil,
      notes: GraphQLNullable<String> = nil
    ) {
      __data = InputDict([
        "startTime": startTime,
        "endTime": endTime,
        "notes": notes
      ])
    }

    var startTime: GraphQLNullable<String> {
      get { __data["startTime"] }
      set { __data["startTime"] = newValue }
    }

    var endTime: GraphQLNullable<String> {
      get { __data["endTime"] }
      set { __data["endTime"] = newValue }
    }

    var notes: GraphQLNullable<String> {
      get { __data["notes"] }
      set { __data["notes"] = newValue }
    }
  }

}