// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct AssignHierarchyRoleInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      departmentId: ID,
      eventVolunteerId: ID,
      hierarchyRole: GraphQLEnum<HierarchyRole>
    ) {
      __data = InputDict([
        "departmentId": departmentId,
        "eventVolunteerId": eventVolunteerId,
        "hierarchyRole": hierarchyRole
      ])
    }

    var departmentId: ID {
      get { __data["departmentId"] }
      set { __data["departmentId"] = newValue }
    }

    var eventVolunteerId: ID {
      get { __data["eventVolunteerId"] }
      set { __data["eventVolunteerId"] = newValue }
    }

    var hierarchyRole: GraphQLEnum<HierarchyRole> {
      get { __data["hierarchyRole"] }
      set { __data["hierarchyRole"] = newValue }
    }
  }

}