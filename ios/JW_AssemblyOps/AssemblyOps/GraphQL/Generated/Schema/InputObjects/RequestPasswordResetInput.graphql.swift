// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct RequestPasswordResetInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      email: String
    ) {
      __data = InputDict([
        "email": email
      ])
    }

    var email: String {
      get { __data["email"] }
      set { __data["email"] = newValue }
    }
  }

}