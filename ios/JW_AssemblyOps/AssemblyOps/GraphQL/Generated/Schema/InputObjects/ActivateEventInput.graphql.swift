// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct ActivateEventInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      templateId: ID
    ) {
      __data = InputDict([
        "templateId": templateId
      ])
    }

    var templateId: ID {
      get { __data["templateId"] }
      set { __data["templateId"] = newValue }
    }
  }

}