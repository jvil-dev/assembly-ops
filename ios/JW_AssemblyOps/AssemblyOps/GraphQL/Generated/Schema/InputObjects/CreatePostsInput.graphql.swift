// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct CreatePostsInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      departmentId: ID,
      posts: [CreatePostInput]
    ) {
      __data = InputDict([
        "departmentId": departmentId,
        "posts": posts
      ])
    }

    var departmentId: ID {
      get { __data["departmentId"] }
      set { __data["departmentId"] = newValue }
    }

    var posts: [CreatePostInput] {
      get { __data["posts"] }
      set { __data["posts"] = newValue }
    }
  }

}