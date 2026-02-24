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
      capacity: GraphQLNullable<Int> = nil,
      category: GraphQLNullable<String> = nil,
      sortOrder: GraphQLNullable<Int> = nil,
      areaId: GraphQLNullable<ID> = nil
    ) {
      __data = InputDict([
        "name": name,
        "description": description,
        "location": location,
        "capacity": capacity,
        "category": category,
        "sortOrder": sortOrder,
        "areaId": areaId
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

    var category: GraphQLNullable<String> {
      get { __data["category"] }
      set { __data["category"] = newValue }
    }

    var sortOrder: GraphQLNullable<Int> {
      get { __data["sortOrder"] }
      set { __data["sortOrder"] = newValue }
    }

    var areaId: GraphQLNullable<ID> {
      get { __data["areaId"] }
      set { __data["areaId"] = newValue }
    }
  }

}