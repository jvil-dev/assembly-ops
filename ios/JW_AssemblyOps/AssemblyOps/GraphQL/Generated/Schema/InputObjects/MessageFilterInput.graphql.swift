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
      senderId: GraphQLNullable<ID> = nil,
      senderType: GraphQLNullable<GraphQLEnum<MessageSenderType>> = nil,
      recipientType: GraphQLNullable<GraphQLEnum<RecipientType>> = nil,
      search: GraphQLNullable<String> = nil
    ) {
      __data = InputDict([
        "isRead": isRead,
        "senderId": senderId,
        "senderType": senderType,
        "recipientType": recipientType,
        "search": search
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

    var senderType: GraphQLNullable<GraphQLEnum<MessageSenderType>> {
      get { __data["senderType"] }
      set { __data["senderType"] = newValue }
    }

    var recipientType: GraphQLNullable<GraphQLEnum<RecipientType>> {
      get { __data["recipientType"] }
      set { __data["recipientType"] = newValue }
    }

    var search: GraphQLNullable<String> {
      get { __data["search"] }
      set { __data["search"] = newValue }
    }
  }

}