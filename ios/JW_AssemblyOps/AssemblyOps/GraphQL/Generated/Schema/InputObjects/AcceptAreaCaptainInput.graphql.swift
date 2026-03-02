// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct AcceptAreaCaptainInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      areaCaptainId: ID
    ) {
      __data = InputDict([
        "areaCaptainId": areaCaptainId
      ])
    }

    var areaCaptainId: ID {
      get { __data["areaCaptainId"] }
      set { __data["areaCaptainId"] = newValue }
    }
  }

}