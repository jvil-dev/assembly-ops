// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct RegisterUserInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      email: String,
      password: String,
      firstName: String,
      lastName: String,
      phone: GraphQLNullable<String> = nil,
      congregation: GraphQLNullable<String> = nil,
      congregationId: GraphQLNullable<ID> = nil,
      appointmentStatus: GraphQLNullable<GraphQLEnum<AppointmentStatus>> = nil,
      isOverseer: GraphQLNullable<Bool> = nil
    ) {
      __data = InputDict([
        "email": email,
        "password": password,
        "firstName": firstName,
        "lastName": lastName,
        "phone": phone,
        "congregation": congregation,
        "congregationId": congregationId,
        "appointmentStatus": appointmentStatus,
        "isOverseer": isOverseer
      ])
    }

    var email: String {
      get { __data["email"] }
      set { __data["email"] = newValue }
    }

    var password: String {
      get { __data["password"] }
      set { __data["password"] = newValue }
    }

    var firstName: String {
      get { __data["firstName"] }
      set { __data["firstName"] = newValue }
    }

    var lastName: String {
      get { __data["lastName"] }
      set { __data["lastName"] = newValue }
    }

    var phone: GraphQLNullable<String> {
      get { __data["phone"] }
      set { __data["phone"] = newValue }
    }

    var congregation: GraphQLNullable<String> {
      get { __data["congregation"] }
      set { __data["congregation"] = newValue }
    }

    var congregationId: GraphQLNullable<ID> {
      get { __data["congregationId"] }
      set { __data["congregationId"] = newValue }
    }

    var appointmentStatus: GraphQLNullable<GraphQLEnum<AppointmentStatus>> {
      get { __data["appointmentStatus"] }
      set { __data["appointmentStatus"] = newValue }
    }

    var isOverseer: GraphQLNullable<Bool> {
      get { __data["isOverseer"] }
      set { __data["isOverseer"] = newValue }
    }
  }

}