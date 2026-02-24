// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct UpdateFacilityLocationInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      name: GraphQLNullable<String> = nil,
      location: GraphQLNullable<String> = nil,
      description: GraphQLNullable<String> = nil,
      sortOrder: GraphQLNullable<Int> = nil
    ) {
      __data = InputDict([
        "name": name,
        "location": location,
        "description": description,
        "sortOrder": sortOrder
      ])
    }

    var name: GraphQLNullable<String> {
      get { __data["name"] }
      set { __data["name"] = newValue }
    }

    var location: GraphQLNullable<String> {
      get { __data["location"] }
      set { __data["location"] = newValue }
    }

    var description: GraphQLNullable<String> {
      get { __data["description"] }
      set { __data["description"] = newValue }
    }

    var sortOrder: GraphQLNullable<Int> {
      get { __data["sortOrder"] }
      set { __data["sortOrder"] = newValue }
    }
  }

}