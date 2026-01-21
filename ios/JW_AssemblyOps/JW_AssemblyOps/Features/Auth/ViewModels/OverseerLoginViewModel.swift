//
//  OverseerLoginViewModel.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 1/17/26.
//


//
//  OverseerLoginViewModel.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 1/17/26.
//

import Foundation
import Combine
import Apollo
import SwiftUI

@MainActor
final class OverseerLoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let appState = AppState.shared
    
    var isFormValid: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        !password.isEmpty
    }
    
    func login() {
        guard isFormValid else { return }
        
        isLoading = true
        errorMessage = nil
        
        let input = AssemblyOpsAPI.LoginAdminInput(
            email: email.lowercased().trimmingCharacters(in: .whitespaces),
            password: password
        )
        
        NetworkClient.shared.apollo.perform(
            mutation: AssemblyOpsAPI.LoginAdminMutation(input: input)
        ) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.loginAdmin {
                        // TODO: Create OverseerInfo model and update AppState
                        // For now, we'll need to extend AppState to handle admin login
                        print("Admin logged in: \(data.admin.fullName)")
                        // self?.appState.didLoginAsAdmin(...)
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
