// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct UpdateUserProfileInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      firstName: GraphQLNullable<String> = nil,
      lastName: GraphQLNullable<String> = nil,
      phone: GraphQLNullable<String> = nil,
      congregation: GraphQLNullable<String> = nil,
      congregationId: GraphQLNullable<ID> = nil
    ) {
      __data = InputDict([
        "firstName": firstName,
        "lastName": lastName,
        "phone": phone,
        "congregation": congregation,
        "congregationId": congregationId
      ])
    }

    var firstName: GraphQLNullable<String> {
      get { __data["firstName"] }
      set { __data["firstName"] = newValue }
    }

    var lastName: GraphQLNullable<String> {
      get { __data["lastName"] }
      set { __data["lastName"] = newValue }
    }

    var phone: GraphQLNullable<String> {
      get { __data["phone"] }
      set { __data["phone"] = newValue }
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