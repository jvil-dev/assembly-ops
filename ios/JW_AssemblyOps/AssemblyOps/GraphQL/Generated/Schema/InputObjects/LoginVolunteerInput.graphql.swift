// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct LoginVolunteerInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      volunteerId: String,
      token: String
    ) {
      __data = InputDict([
        "volunteerId": volunteerId,
        "token": token
      ])
    }

    var volunteerId: String {
      get { __data["volunteerId"] }
      set { __data["volunteerId"] = newValue }
    }

    var token: String {
      get { __data["token"] }
      set { __data["token"] = newValue }
    }
  }

}