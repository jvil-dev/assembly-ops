// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct AddVolunteerToEventInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      userId: ID,
      eventId: ID,
      departmentId: GraphQLNullable<ID> = nil,
      roleId: GraphQLNullable<ID> = nil
    ) {
      __data = InputDict([
        "userId": userId,
        "eventId": eventId,
        "departmentId": departmentId,
        "roleId": roleId
      ])
    }

    var userId: ID {
      get { __data["userId"] }
      set { __data["userId"] = newValue }
    }

    var eventId: ID {
      get { __data["eventId"] }
      set { __data["eventId"] = newValue }
    }

    var departmentId: GraphQLNullable<ID> {
      get { __data["departmentId"] }
      set { __data["departmentId"] = newValue }
    }

    var roleId: GraphQLNullable<ID> {
      get { __data["roleId"] }
      set { __data["roleId"] = newValue }
    }
  }

}