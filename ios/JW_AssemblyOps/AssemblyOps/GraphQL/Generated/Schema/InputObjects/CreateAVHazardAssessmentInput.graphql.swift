// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct CreateAVHazardAssessmentInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      eventId: ID,
      title: String,
      hazardType: GraphQLEnum<AVHazardType>,
      description: String,
      controls: String,
      ppeRequired: [String],
      sessionId: GraphQLNullable<ID> = nil
    ) {
      __data = InputDict([
        "eventId": eventId,
        "title": title,
        "hazardType": hazardType,
        "description": description,
        "controls": controls,
        "ppeRequired": ppeRequired,
        "sessionId": sessionId
      ])
    }

    var eventId: ID {
      get { __data["eventId"] }
      set { __data["eventId"] = newValue }
    }

    var title: String {
      get { __data["title"] }
      set { __data["title"] = newValue }
    }

    var hazardType: GraphQLEnum<AVHazardType> {
      get { __data["hazardType"] }
      set { __data["hazardType"] = newValue }
    }

    var description: String {
      get { __data["description"] }
      set { __data["description"] = newValue }
    }

    var controls: String {
      get { __data["controls"] }
      set { __data["controls"] = newValue }
    }

    var ppeRequired: [String] {
      get { __data["ppeRequired"] }
      set { __data["ppeRequired"] = newValue }
    }

    var sessionId: GraphQLNullable<ID> {
      get { __data["sessionId"] }
      set { __data["sessionId"] = newValue }
    }
  }

}