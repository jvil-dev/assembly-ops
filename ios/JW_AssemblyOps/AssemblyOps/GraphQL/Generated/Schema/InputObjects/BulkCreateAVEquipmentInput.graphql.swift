// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct BulkCreateAVEquipmentInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      eventId: ID,
      items: [AVEquipmentItemInput]
    ) {
      __data = InputDict([
        "eventId": eventId,
        "items": items
      ])
    }

    var eventId: ID {
      get { __data["eventId"] }
      set { __data["eventId"] = newValue }
    }

    var items: [AVEquipmentItemInput] {
      get { __data["items"] }
      set { __data["items"] = newValue }
    }
  }

}