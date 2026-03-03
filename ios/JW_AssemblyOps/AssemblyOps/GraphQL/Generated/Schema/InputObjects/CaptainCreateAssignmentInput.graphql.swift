// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct CaptainCreateAssignmentInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      eventId: ID,
      eventVolunteerId: ID,
      postId: ID,
      sessionId: ID,
      shiftId: GraphQLNullable<ID> = nil,
      canCount: GraphQLNullable<Bool> = nil
    ) {
      __data = InputDict([
        "eventId": eventId,
        "eventVolunteerId": eventVolunteerId,
        "postId": postId,
        "sessionId": sessionId,
        "shiftId": shiftId,
        "canCount": canCount
      ])
    }

    var eventId: ID {
      get { __data["eventId"] }
      set { __data["eventId"] = newValue }
    }

    var eventVolunteerId: ID {
      get { __data["eventVolunteerId"] }
      set { __data["eventVolunteerId"] = newValue }
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

    var canCount: GraphQLNullable<Bool> {
      get { __data["canCount"] }
      set { __data["canCount"] = newValue }
    }
  }

}