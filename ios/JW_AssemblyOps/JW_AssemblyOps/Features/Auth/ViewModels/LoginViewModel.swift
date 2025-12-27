//
//  LoginViewModel.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/27/25.
//


import Foundation
import SwiftUI
import Combine
import Apollo

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var volunteerId: String = ""
    @Published var token: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let appState: AppState
    
    init(appState: AppState = .shared) {
        self.appState = appState
    }
    
    var isFormValid: Bool {
        !volunteerId.trimmingCharacters(in: .whitespaces).isEmpty &&
        !token.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    func login() {
        guard isFormValid else { return }
        
        isLoading = true
        errorMessage = nil
        
        let input = AssemblyOpsAPI.LoginVolunteerInput(
            volunteerId: volunteerId.uppercased().trimmingCharacters(in: .whitespaces),
            token: token.uppercased().trimmingCharacters(in: .whitespaces)
        )
        
        NetworkClient.shared.apollo.perform(
            mutation: AssemblyOpsAPI.LoginVolunteerMutation(input: input)
        ) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.loginVolunteer {
                         let volunteer = VolunteerInfo(
                             id: data.volunteer.id,
                             volunteerId: data.volunteer.volunteerId,
                             firstName: data.volunteer.firstName,
                             lastName: data.volunteer.lastName,
                             fullName: data.volunteer.fullName,
                             congregation: data.volunteer.congregation,
                             eventName: data.volunteer.event.name,
                             departmentName: data.volunteer.department?.name
                         )
                         self?.appState.didLogin(
                             volunteer: volunteer,
                             accessToken: data.accessToken,
                             refreshToken: data.refreshToken,
                             expiresIn: data.expiresIn
                         )
                     } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        self?.errorMessage = errors.first?.localizedDescription ?? "Login failed"
                    }
                case .failure(let error):
                    self?.errorMessage = "Unable to connect. Please check your internet connection."
                    print("Login error: \(error)")
                }
                self?.isLoading = false
            }
        }
    }
}
