// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct ResetPasswordInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      resetToken: String,
      newPassword: String
    ) {
      __data = InputDict([
        "resetToken": resetToken,
        "newPassword": newPassword
      ])
    }

    var resetToken: String {
      get { __data["resetToken"] }
      set { __data["resetToken"] = newValue }
    }

    var newPassword: String {
      get { __data["newPassword"] }
      set { __data["newPassword"] = newValue }
    }
  }

}