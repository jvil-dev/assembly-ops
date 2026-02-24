// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct CreateAreaInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      name: String,
      description: GraphQLNullable<String> = nil,
      category: GraphQLNullable<String> = nil,
      sortOrder: GraphQLNullable<Int> = nil
    ) {
      __data = InputDict([
        "name": name,
        "description": description,
        "category": category,
        "sortOrder": sortOrder
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

    var category: GraphQLNullable<String> {
      get { __data["category"] }
      set { __data["category"] = newValue }
    }

    var sortOrder: GraphQLNullable<Int> {
      get { __data["sortOrder"] }
      set { __data["sortOrder"] = newValue }
    }
  }

}