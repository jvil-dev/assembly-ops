// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct MessageFilterInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      isRead: GraphQLNullable<Bool> = nil,
      senderId: GraphQLNullable<ID> = nil
    ) {
      __data = InputDict([
        "isRead": isRead,
        "senderId": senderId
      ])
    }

    var isRead: GraphQLNullable<Bool> {
      get { __data["isRead"] }
      set { __data["isRead"] = newValue }
    }

    var senderId: GraphQLNullable<ID> {
      get { __data["senderId"] }
      set { __data["senderId"] = newValue }
    }
  }

}