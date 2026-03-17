// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct CopySessionAssignmentsInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      sourceSessionId: ID,
      targetSessionId: ID,
      departmentId: ID,
      areaIds: GraphQLNullable<[ID]> = nil,
      postIds: GraphQLNullable<[ID]> = nil,
      copyIsCaptain: GraphQLNullable<Bool> = nil,
      copyCanCount: GraphQLNullable<Bool> = nil,
      copyAreaCaptains: GraphQLNullable<Bool> = nil,
      forceAssign: GraphQLNullable<Bool> = nil
    ) {
      __data = InputDict([
        "sourceSessionId": sourceSessionId,
        "targetSessionId": targetSessionId,
        "departmentId": departmentId,
        "areaIds": areaIds,
        "postIds": postIds,
        "copyIsCaptain": copyIsCaptain,
        "copyCanCount": copyCanCount,
        "copyAreaCaptains": copyAreaCaptains,
        "forceAssign": forceAssign
      ])
    }

    var sourceSessionId: ID {
      get { __data["sourceSessionId"] }
      set { __data["sourceSessionId"] = newValue }
    }

    var targetSessionId: ID {
      get { __data["targetSessionId"] }
      set { __data["targetSessionId"] = newValue }
    }

    var departmentId: ID {
      get { __data["departmentId"] }
      set { __data["departmentId"] = newValue }
    }

    var areaIds: GraphQLNullable<[ID]> {
      get { __data["areaIds"] }
      set { __data["areaIds"] = newValue }
    }

    var postIds: GraphQLNullable<[ID]> {
      get { __data["postIds"] }
      set { __data["postIds"] = newValue }
    }

    var copyIsCaptain: GraphQLNullable<Bool> {
      get { __data["copyIsCaptain"] }
      set { __data["copyIsCaptain"] = newValue }
    }

    var copyCanCount: GraphQLNullable<Bool> {
      get { __data["copyCanCount"] }
      set { __data["copyCanCount"] = newValue }
    }

    var copyAreaCaptains: GraphQLNullable<Bool> {
      get { __data["copyAreaCaptains"] }
      set { __data["copyAreaCaptains"] = newValue }
    }

    var forceAssign: GraphQLNullable<Bool> {
      get { __data["forceAssign"] }
      set { __data["forceAssign"] = newValue }
    }
  }

}