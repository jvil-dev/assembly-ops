// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct StartConversationInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      eventId: ID,
      recipientType: GraphQLEnum<MessageSenderType>,
      recipientId: ID,
      subject: GraphQLNullable<String> = nil,
      body: String
    ) {
      __data = InputDict([
        "eventId": eventId,
        "recipientType": recipientType,
        "recipientId": recipientId,
        "subject": subject,
        "body": body
      ])
    }

    var eventId: ID {
      get { __data["eventId"] }
      set { __data["eventId"] = newValue }
    }

    var recipientType: GraphQLEnum<MessageSenderType> {
      get { __data["recipientType"] }
      set { __data["recipientType"] = newValue }
    }

    var recipientId: ID {
      get { __data["recipientId"] }
      set { __data["recipientId"] = newValue }
    }

    var subject: GraphQLNullable<String> {
      get { __data["subject"] }
      set { __data["subject"] = newValue }
    }

    var body: String {
      get { __data["body"] }
      set { __data["body"] = newValue }
    }
  }

}