// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension AssemblyOpsAPI {
  struct UpdateVolunteerInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      firstName: GraphQLNullable<String> = nil,
      lastName: GraphQLNullable<String> = nil,
      email: GraphQLNullable<String> = nil,
      phone: GraphQLNullable<String> = nil,
      congregation: GraphQLNullable<String> = nil,
      appointmentStatus: GraphQLNullable<GraphQLEnum<AppointmentStatus>> = nil,
      notes: GraphQLNullable<String> = nil,
      departmentId: GraphQLNullable<ID> = nil,
      roleId: GraphQLNullable<ID> = nil
    ) {
      __data = InputDict([
        "firstName": firstName,
        "lastName": lastName,
        "email": email,
        "phone": phone,
        "congregation": congregation,
        "appointmentStatus": appointmentStatus,
        "notes": notes,
        "departmentId": departmentId,
        "roleId": roleId
      ])
    }

    var firstName: GraphQLNullable<String> {
      get { __data["firstName"] }
      set { __data["firstName"] = newValue }
    }

    var lastName: GraphQLNullable<String> {
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

    var congregation: GraphQLNullable<String> {
      get { __data["congregation"] }
      set { __data["congregation"] = newValue }
    }

    var appointmentStatus: GraphQLNullable<GraphQLEnum<AppointmentStatus>> {
      get { __data["appointmentStatus"] }
      set { __data["appointmentStatus"] = newValue }
    }

    var notes: GraphQLNullable<String> {
      get { __data["notes"] }
      set { __data["notes"] = newValue }
    }

    var departmentId: GraphQLNullable<ID> {
      get { __data["departmentId"] }
      set { __data["departmentId"] = newValue }
    }

    var roleId: GraphQLNullable<ID> {
      get { __data["roleId"] }
      set { __data["roleId"] = newValue }
    }
  }

}