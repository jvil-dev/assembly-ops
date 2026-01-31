// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct CreateVolunteerProfileInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      firstName: String,
      lastName: String,
      email: GraphQLNullable<String> = nil,
      phone: GraphQLNullable<String> = nil,
      appointmentStatus: GraphQLNullable<GraphQLEnum<AppointmentStatus>> = nil,
      notes: GraphQLNullable<String> = nil,
      congregationId: ID
    ) {
      __data = InputDict([
        "firstName": firstName,
        "lastName": lastName,
        "email": email,
        "phone": phone,
        "appointmentStatus": appointmentStatus,
        "notes": notes,
        "congregationId": congregationId
      ])
    }

    var firstName: String {
      get { __data["firstName"] }
      set { __data["firstName"] = newValue }
    }

    var lastName: String {
      get { __data["lastName"] }
      set { __data["lastName"] = newValue }
    }

    var email: GraphQLNullable<String> {
      get { __data["email"] }
      set { __data["email"] = newValue }
    }

    var phone: GraphQLNullable<String> {
      get { __data["phone"] }
      set { __data["phone"] = newValue }
    }

    var appointmentStatus: GraphQLNullable<GraphQLEnum<AppointmentStatus>> {
      get { __data["appointmentStatus"] }
      set { __data["appointmentStatus"] = newValue }
    }

    var notes: GraphQLNullable<String> {
      get { __data["notes"] }
      set { __data["notes"] = newValue }
    }

    var congregationId: ID {
      get { __data["congregationId"] }
      set { __data["congregationId"] = newValue }
    }
  }

}