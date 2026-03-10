// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct CreateAssignmentInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      volunteerId: ID,
      postId: ID,
      sessionId: ID,
      shiftId: GraphQLNullable<ID> = nil,
      isCaptain: GraphQLNullable<Bool> = nil,
      canCount: GraphQLNullable<Bool> = nil,
      force: GraphQLNullable<Bool> = nil
    ) {
      __data = InputDict([
        "volunteerId": volunteerId,
        "postId": postId,
        "sessionId": sessionId,
        "shiftId": shiftId,
        "isCaptain": isCaptain,
        "canCount": canCount,
        "force": force
      ])
    }

    var volunteerId: ID {
      get { __data["volunteerId"] }
      set { __data["volunteerId"] = newValue }
    }

    var postId: ID {
      get { __data["postId"] }
      set { __data["postId"] = newValue }
    }

    var sessionId: ID {
      get { __data["sessionId"] }
      set { __data["sessionId"] = newValue }
    }

    var shiftId: GraphQLNullable<ID> {
      get { __data["shiftId"] }
      set { __data["shiftId"] = newValue }
    }

    var isCaptain: GraphQLNullable<Bool> {
      get { __data["isCaptain"] }
      set { __data["isCaptain"] = newValue }
    }

    var canCount: GraphQLNullable<Bool> {
      get { __data["canCount"] }
      set { __data["canCount"] = newValue }
    }

    var force: GraphQLNullable<Bool> {
      get { __data["force"] }
      set { __data["force"] = newValue }
    }
  }

}