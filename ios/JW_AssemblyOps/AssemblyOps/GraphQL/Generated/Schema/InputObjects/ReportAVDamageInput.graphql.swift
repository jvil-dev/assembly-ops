// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct ReportAVDamageInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      equipmentId: ID,
      description: String,
      severity: GraphQLEnum<AVDamageSeverity>,
      sessionId: GraphQLNullable<ID> = nil
    ) {
      __data = InputDict([
        "equipmentId": equipmentId,
        "description": description,
        "severity": severity,
        "sessionId": sessionId
      ])
    }

    var equipmentId: ID {
      get { __data["equipmentId"] }
      set { __data["equipmentId"] = newValue }
    }

    var description: String {
      get { __data["description"] }
      set { __data["description"] = newValue }
    }

    var severity: GraphQLEnum<AVDamageSeverity> {
      get { __data["severity"] }
      set { __data["severity"] = newValue }
    }

    var sessionId: GraphQLNullable<ID> {
      get { __data["sessionId"] }
      set { __data["sessionId"] = newValue }
    }
  }

}