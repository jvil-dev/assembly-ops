// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct PromoteToAppAdminInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      eventId: ID,
      adminId: ID
    ) {
      __data = InputDict([
        "eventId": eventId,
        "adminId": adminId
      ])
    }

    var eventId: ID {
      get { __data["eventId"] }
      set { __data["eventId"] = newValue }
    }

    var adminId: ID {
      get { __data["adminId"] }
      set { __data["adminId"] = newValue }
    }
  }

}