// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct VerifyResetCodeInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      email: String,
      code: String
    ) {
      __data = InputDict([
        "email": email,
        "code": code
      ])
    }

    var email: String {
      get { __data["email"] }
      set { __data["email"] = newValue }
    }

    var code: String {
      get { __data["code"] }
      set { __data["code"] = newValue }
    }
  }

}