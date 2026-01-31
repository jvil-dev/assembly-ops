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
      volunteerProfileId: ID,
      eventId: ID,
      departmentId: GraphQLNullable<ID> = nil,
      roleId: GraphQLNullable<ID> = nil
    ) {
      __data = InputDict([
        "volunteerProfileId": volunteerProfileId,
        "eventId": eventId,
        "departmentId": departmentId,
        "roleId": roleId
      ])
    }

    var volunteerProfileId: ID {
      get { __data["volunteerProfileId"] }
      set { __data["volunteerProfileId"] = newValue }
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