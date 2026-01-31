// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct RegisterAdminInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      email: String,
      password: String,
      firstName: String,
      lastName: String
    ) {
      __data = InputDict([
        "email": email,
        "password": password,
        "firstName": firstName,
        "lastName": lastName
      ])
    }

    var email: String {
      get { __data["email"] }
      set { __data["email"] = newValue }
    }

    var password: String {
      get { __data["password"] }
      set { __data["password"] = newValue }
    }

    var firstName: String {
      get { __data["firstName"] }
      set { __data["firstName"] = newValue }
    }

    var lastName: String {
      get { __data["lastName"] }
      set { __data["lastName"] = newValue }
    }
  }

}