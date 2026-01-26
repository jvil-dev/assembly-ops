// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct AppleAuthInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      identityToken: String,
      firstName: GraphQLNullable<String> = nil,
      lastName: GraphQLNullable<String> = nil
    ) {
      __data = InputDict([
        "identityToken": identityToken,
        "firstName": firstName,
        "lastName": lastName
      ])
    }

    var identityToken: String {
      get { __data["identityToken"] }
      set { __data["identityToken"] = newValue }
    }

    var firstName: GraphQLNullable<String> {
      get { __data["firstName"] }
      set { __data["firstName"] = newValue }
    }

    var lastName: GraphQLNullable<String> {
      get { __data["lastName"] }
      set { __data["lastName"] = newValue }
    }
  }

}