// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct SendMessageInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      volunteerId: GraphQLNullable<ID> = nil,
      recipientType: GraphQLNullable<GraphQLEnum<MessageSenderType>> = nil,
      recipientId: GraphQLNullable<ID> = nil,
      eventId: GraphQLNullable<ID> = nil,
      subject: GraphQLNullable<String> = nil,
      body: String
    ) {
      __data = InputDict([
        "volunteerId": volunteerId,
        "recipientType": recipientType,
        "recipientId": recipientId,
        "eventId": eventId,
        "subject": subject,
        "body": body
      ])
    }

    var volunteerId: GraphQLNullable<ID> {
      get { __data["volunteerId"] }
      set { __data["volunteerId"] = newValue }
    }

    var recipientType: GraphQLNullable<GraphQLEnum<MessageSenderType>> {
      get { __data["recipientType"] }
      set { __data["recipientType"] = newValue }
    }

    var recipientId: GraphQLNullable<ID> {
      get { __data["recipientId"] }
      set { __data["recipientId"] = newValue }
    }

    var eventId: GraphQLNullable<ID> {
      get { __data["eventId"] }
      set { __data["eventId"] = newValue }
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