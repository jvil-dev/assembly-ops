// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct SendMultiMessageInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      volunteerIds: [ID],
      subject: GraphQLNullable<String> = nil,
      body: String,
      eventId: ID
    ) {
      __data = InputDict([
        "volunteerIds": volunteerIds,
        "subject": subject,
        "body": body,
        "eventId": eventId
      ])
    }

    var volunteerIds: [ID] {
      get { __data["volunteerIds"] }
      set { __data["volunteerIds"] = newValue }
    }

    var subject: GraphQLNullable<String> {
      get { __data["subject"] }
      set { __data["subject"] = newValue }
    }

    var body: String {
      get { __data["body"] }
      set { __data["body"] = newValue }
    }

    var eventId: ID {
      get { __data["eventId"] }
      set { __data["eventId"] = newValue }
    }
  }

}