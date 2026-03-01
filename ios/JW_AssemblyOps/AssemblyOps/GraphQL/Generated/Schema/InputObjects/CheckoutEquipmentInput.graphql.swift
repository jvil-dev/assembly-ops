// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct CheckoutEquipmentInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      equipmentId: ID,
      checkedOutById: ID,
      sessionId: GraphQLNullable<ID> = nil,
      notes: GraphQLNullable<String> = nil
    ) {
      __data = InputDict([
        "equipmentId": equipmentId,
        "checkedOutById": checkedOutById,
        "sessionId": sessionId,
        "notes": notes
      ])
    }

    var equipmentId: ID {
      get { __data["equipmentId"] }
      set { __data["equipmentId"] = newValue }
    }

    var checkedOutById: ID {
      get { __data["checkedOutById"] }
      set { __data["checkedOutById"] = newValue }
    }

    var sessionId: GraphQLNullable<ID> {
      get { __data["sessionId"] }
      set { __data["sessionId"] = newValue }
    }

    var notes: GraphQLNullable<String> {
      get { __data["notes"] }
      set { __data["notes"] = newValue }
    }
  }

}