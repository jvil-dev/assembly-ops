// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct CreatePostInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      name: String,
      description: GraphQLNullable<String> = nil,
      location: GraphQLNullable<String> = nil,
      capacity: GraphQLNullable<Int> = nil
    ) {
      __data = InputDict([
        "name": name,
        "description": description,
        "location": location,
        "capacity": capacity
      ])
    }

    var name: String {
      get { __data["name"] }
      set { __data["name"] = newValue }
    }

    var description: GraphQLNullable<String> {
      get { __data["description"] }
      set { __data["description"] = newValue }
    }

    var location: GraphQLNullable<String> {
      get { __data["location"] }
      set { __data["location"] = newValue }
    }

    var capacity: GraphQLNullable<Int> {
      get { __data["capacity"] }
      set { __data["capacity"] = newValue }
    }
  }

}