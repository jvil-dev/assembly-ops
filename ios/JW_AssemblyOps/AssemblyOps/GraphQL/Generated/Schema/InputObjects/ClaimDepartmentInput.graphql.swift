// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct ClaimDepartmentInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      eventId: ID,
      departmentType: GraphQLEnum<DepartmentType>
    ) {
      __data = InputDict([
        "eventId": eventId,
        "departmentType": departmentType
      ])
    }

    var eventId: ID {
      get { __data["eventId"] }
      set { __data["eventId"] = newValue }
    }

    var departmentType: GraphQLEnum<DepartmentType> {
      get { __data["departmentType"] }
      set { __data["departmentType"] = newValue }
    }
  }

}