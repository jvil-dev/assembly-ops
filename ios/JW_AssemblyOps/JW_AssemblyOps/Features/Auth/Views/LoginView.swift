//
//  LoginView.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/27/25.
//


import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @FocusState private var focusedField: Field?
    
    private enum Field {
        case volunteerId
        case token
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "person.badge.clock")
                            .font(.system(size: 60))
                            .foregroundStyle(Color("ThemeColor"))
                        
                        Text("JW AssemblyOps")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Volunteer Check-In")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // Login Form
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Volunteer ID")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            TextField("VOL-XXXXXX", text: $viewModel.volunteerId)
                                .textFieldStyle(.roundedBorder)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .volunteerId)
                                .submitLabel(.next)
                                .onSubmit { focusedField = .token }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Token")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            SecureField("XXXXXXXX", text: $viewModel.token)
                                .textFieldStyle(.roundedBorder)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .token)
                                .submitLabel(.go)
                                .onSubmit {
                                    Task { viewModel.login() }
                                }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Error Message
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    
                    // Login Button
                    Button {
                        Task { viewModel.login() }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Log In")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(viewModel.isFormValid ? Color("ThemeColor") : Color.gray)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 24)
                    .disabled(!viewModel.isFormValid || viewModel.isLoading)
                    
                    // Help Text
                    Text("Your overseer will provide your login credentials")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    LoginView()
}
