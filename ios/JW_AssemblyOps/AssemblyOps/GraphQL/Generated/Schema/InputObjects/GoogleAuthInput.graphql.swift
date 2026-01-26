// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct GoogleAuthInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      idToken: String
    ) {
      __data = InputDict([
        "idToken": idToken
      ])
    }

    var idToken: String {
      get { __data["idToken"] }
      set { __data["idToken"] = newValue }
    }
  }

}