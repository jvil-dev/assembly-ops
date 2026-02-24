// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct RemoveAreaCaptainInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      areaId: ID,
      sessionId: ID
    ) {
      __data = InputDict([
        "areaId": areaId,
        "sessionId": sessionId
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
  }

}