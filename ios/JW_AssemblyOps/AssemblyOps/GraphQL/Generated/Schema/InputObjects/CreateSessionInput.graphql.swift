// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct CreateSessionInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      name: String,
      date: DateTime,
      startTime: String,
      endTime: String
    ) {
      __data = InputDict([
        "name": name,
        "date": date,
        "startTime": startTime,
        "endTime": endTime
      ])
    }

    var name: String {
      get { __data["name"] }
      set { __data["name"] = newValue }
    }

    var date: DateTime {
      get { __data["date"] }
      set { __data["date"] = newValue }
    }

    var startTime: String {
      get { __data["startTime"] }
      set { __data["startTime"] = newValue }
    }

    var endTime: String {
      get { __data["endTime"] }
      set { __data["endTime"] = newValue }
    }
  }

}