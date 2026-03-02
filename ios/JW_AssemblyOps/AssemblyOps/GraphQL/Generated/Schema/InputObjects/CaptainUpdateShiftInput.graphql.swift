// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct CaptainUpdateShiftInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      eventId: ID,
      startTime: GraphQLNullable<String> = nil,
      endTime: GraphQLNullable<String> = nil
    ) {
      __data = InputDict([
        "eventId": eventId,
        "startTime": startTime,
        "endTime": endTime
      ])
    }

    var eventId: ID {
      get { __data["eventId"] }
      set { __data["eventId"] = newValue }
    }

    var startTime: GraphQLNullable<String> {
      get { __data["startTime"] }
      set { __data["startTime"] = newValue }
    }

    var endTime: GraphQLNullable<String> {
      get { __data["endTime"] }
      set { __data["endTime"] = newValue }
    }
  }

}