// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct SendDepartmentMessageInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      departmentId: ID,
      subject: GraphQLNullable<String> = nil,
      body: String
    ) {
      __data = InputDict([
        "departmentId": departmentId,
        "subject": subject,
        "body": body
      ])
    }

    var departmentId: ID {
      get { __data["departmentId"] }
      set { __data["departmentId"] = newValue }
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