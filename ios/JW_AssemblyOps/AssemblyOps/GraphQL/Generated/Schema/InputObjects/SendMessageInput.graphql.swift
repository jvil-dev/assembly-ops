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
      volunteerId: ID,
      subject: GraphQLNullable<String> = nil,
      body: String
    ) {
      __data = InputDict([
        "volunteerId": volunteerId,
        "subject": subject,
        "body": body
      ])
    }

    var volunteerId: ID {
      get { __data["volunteerId"] }
      set { __data["volunteerId"] = newValue }
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