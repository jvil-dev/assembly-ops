// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct UpdateAVEquipmentInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      name: GraphQLNullable<String> = nil,
      category: GraphQLNullable<GraphQLEnum<AVEquipmentCategory>> = nil,
      condition: GraphQLNullable<GraphQLEnum<AVEquipmentCondition>> = nil,
      model: GraphQLNullable<String> = nil,
      serialNumber: GraphQLNullable<String> = nil,
      location: GraphQLNullable<String> = nil,
      notes: GraphQLNullable<String> = nil,
      areaId: GraphQLNullable<ID> = nil
    ) {
      __data = InputDict([
        "name": name,
        "category": category,
        "condition": condition,
        "model": model,
        "serialNumber": serialNumber,
        "location": location,
        "notes": notes,
        "areaId": areaId
      ])
    }

    var name: GraphQLNullable<String> {
      get { __data["name"] }
      set { __data["name"] = newValue }
    }

    var category: GraphQLNullable<GraphQLEnum<AVEquipmentCategory>> {
      get { __data["category"] }
      set { __data["category"] = newValue }
    }

    var condition: GraphQLNullable<GraphQLEnum<AVEquipmentCondition>> {
      get { __data["condition"] }
      set { __data["condition"] = newValue }
    }

    var model: GraphQLNullable<String> {
      get { __data["model"] }
      set { __data["model"] = newValue }
    }

    var serialNumber: GraphQLNullable<String> {
      get { __data["serialNumber"] }
      set { __data["serialNumber"] = newValue }
    }

    var location: GraphQLNullable<String> {
      get { __data["location"] }
      set { __data["location"] = newValue }
    }

    var notes: GraphQLNullable<String> {
      get { __data["notes"] }
      set { __data["notes"] = newValue }
    }

    var areaId: GraphQLNullable<ID> {
      get { __data["areaId"] }
      set { __data["areaId"] = newValue }
    }
  }

}