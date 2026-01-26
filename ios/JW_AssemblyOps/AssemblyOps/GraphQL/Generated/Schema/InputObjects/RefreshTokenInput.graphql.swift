// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct RefreshTokenInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      refreshToken: String
    ) {
      __data = InputDict([
        "refreshToken": refreshToken
      ])
    }

    var refreshToken: String {
      get { __data["refreshToken"] }
      set { __data["refreshToken"] = newValue }
    }
  }

}