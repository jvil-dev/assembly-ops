// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct DeclineAreaCaptainInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      areaCaptainId: ID,
      reason: GraphQLNullable<String> = nil
    ) {
      __data = InputDict([
        "areaCaptainId": areaCaptainId,
        "reason": reason
      ])
    }

    var areaCaptainId: ID {
      get { __data["areaCaptainId"] }
      set { __data["areaCaptainId"] = newValue }
    }

    var reason: GraphQLNullable<String> {
      get { __data["reason"] }
      set { __data["reason"] = newValue }
    }
  }

}