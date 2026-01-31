// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct JoinEventInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      joinCode: String
    ) {
      __data = InputDict([
        "joinCode": joinCode
      ])
    }

    var joinCode: String {
      get { __data["joinCode"] }
      set { __data["joinCode"] = newValue }
    }
  }

}