// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct JoinDepartmentByCodeInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      accessCode: String
    ) {
      __data = InputDict([
        "accessCode": accessCode
      ])
    }

    var accessCode: String {
      get { __data["accessCode"] }
      set { __data["accessCode"] = newValue }
    }
  }

}