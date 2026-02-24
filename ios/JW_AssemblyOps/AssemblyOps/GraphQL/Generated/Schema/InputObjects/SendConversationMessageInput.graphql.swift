// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct SendConversationMessageInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      conversationId: ID,
      body: String
    ) {
      __data = InputDict([
        "conversationId": conversationId,
        "body": body
      ])
    }

    var conversationId: ID {
      get { __data["conversationId"] }
      set { __data["conversationId"] = newValue }
    }

    var body: String {
      get { __data["body"] }
      set { __data["body"] = newValue }
    }
  }

}