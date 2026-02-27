// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct CompleteOAuthRegistrationInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      pendingOAuthToken: String,
      firstName: String,
      lastName: String,
      isOverseer: GraphQLNullable<Bool> = nil,
      congregation: GraphQLNullable<String> = nil,
      congregationId: GraphQLNullable<ID> = nil
    ) {
      __data = InputDict([
        "pendingOAuthToken": pendingOAuthToken,
        "firstName": firstName,
        "lastName": lastName,
        "isOverseer": isOverseer,
        "congregation": congregation,
        "congregationId": congregationId
      ])
    }

    var pendingOAuthToken: String {
      get { __data["pendingOAuthToken"] }
      set { __data["pendingOAuthToken"] = newValue }
    }

    var firstName: String {
      get { __data["firstName"] }
      set { __data["firstName"] = newValue }
    }

    var lastName: String {
      get { __data["lastName"] }
      set { __data["lastName"] = newValue }
    }

    var isOverseer: GraphQLNullable<Bool> {
      get { __data["isOverseer"] }
      set { __data["isOverseer"] = newValue }
    }

    var congregation: GraphQLNullable<String> {
      get { __data["congregation"] }
      set { __data["congregation"] = newValue }
    }

    var congregationId: GraphQLNullable<ID> {
      get { __data["congregationId"] }
      set { __data["congregationId"] = newValue }
    }
  }

}