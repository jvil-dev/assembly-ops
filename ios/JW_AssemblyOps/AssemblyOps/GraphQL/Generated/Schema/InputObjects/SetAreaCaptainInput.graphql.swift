// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct SetAreaCaptainInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      areaId: ID,
      sessionId: ID,
      eventVolunteerId: ID
    ) {
      __data = InputDict([
        "areaId": areaId,
        "sessionId": sessionId,
        "eventVolunteerId": eventVolunteerId
      ])
    }

    var areaId: ID {
      get { __data["areaId"] }
      set { __data["areaId"] = newValue }
    }

    var sessionId: ID {
      get { __data["sessionId"] }
      set { __data["sessionId"] = newValue }
    }

    var eventVolunteerId: ID {
      get { __data["eventVolunteerId"] }
      set { __data["eventVolunteerId"] = newValue }
    }
  }

}