//
//  OverseerRegistrationView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/25/26.
//

// MARK: - Overseer Registration View
//
// Full registration form for creating a new overseer account.
// Supports email/password registration and OAuth (Apple/Google) sign-up.
//
// Sections:
//   - Header: Logo and title
//   - Registration Form: Email, password, name, phone, congregation fields
//   - OAuth Buttons: Sign in with Apple and Google options
//   - Error Display: Shows validation/submission errors
//
// Features:
//   - Form validation via OverseerRegistrationViewModel.isFormValid
//   - Password confirmation matching
//   - Minimum 8 character password requirement
//   - OAuth flow triggers OAuthRegistrationView for profile completion
//
// Navigation:
//   - Presented as navigation destination from LandingView
//   - Full screen cover for OAuthRegistrationView when OAuth user needs completion
//

import SwiftUI
import AuthenticationServices

struct OverseerRegistrationView: View {
    @StateObject private var viewModel = OverseerRegistrationViewModel()
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection

                // Email/Password Registration Form
                registrationForm

                // Divider
                dividerSection

                // OAuth Buttons
                oauthButtons

                // Error display
                if let error = viewModel.errorMessage {
                    errorSection(error)
                }
            }
            .padding()
        }
        .navigationTitle("Create Account")
        .fullScreenCover(isPresented: $viewModel.showOAuthRegistration) {
            if let data = viewModel.pendingOAuthData {
                OAuthRegistrationView(
                    email: data.email,
                    firstName: data.firstName,
                    lastName: data.lastName,
                    pendingOAuthToken: data.pendingToken
                )
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
            Text("Create Overseer Account")
                .font(.title2)
                .fontWeight(.semibold)
        }
    }

    private var registrationForm: some View {
        VStack(spacing: 16) {
            TextField("Email", text: $viewModel.email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .textContentType(.emailAddress)

            SecureField("Password (min 8 characters)", text: $viewModel.password)
                .textContentType(.newPassword)

            SecureField("Confirm Password", text: $viewModel.confirmPassword)
                .textContentType(.newPassword)

            TextField("First Name", text: $viewModel.firstName)
                .textContentType(.givenName)

            TextField("Last Name", text: $viewModel.lastName)
                .textContentType(.familyName)

            TextField("Phone (optional)", text: $viewModel.phone)
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)

            TextField("Congregation", text: $viewModel.congregation)

            Button {
                viewModel.register()
            } label: {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Create Account")
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(viewModel.isFormValid ? Color("ThemeColor") : Color.gray)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .disabled(!viewModel.isFormValid || viewModel.isLoading)
        }
        .textFieldStyle(.roundedBorder)
    }

    private var dividerSection: some View {
        HStack {
            Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 1)
            Text("or").foregroundStyle(.secondary)
            Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 1)
        }
    }

    private var oauthButtons: some View {
        VStack(spacing: 12) {
            SignInWithAppleButton(.signUp) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { _ in }
            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
            .frame(height: 52)
            .cornerRadius(14)
            .onTapGesture { viewModel.signInWithApple() }

            Button { viewModel.signInWithGoogle() } label: {
                HStack {
                    Image("GoogleLogo")
                        .resizable()
                        .frame(width: 20, height: 20)
                    Text("Sign up with Google")
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(RoundedRectangle(cornerRadius: 14).stroke(Color.gray.opacity(0.3)))
            }
            .foregroundStyle(colorScheme == .dark ? .white : .black)
        }
    }

    private func errorSection(_ error: String) -> some View {
        Text(error)
            .foregroundStyle(.red)
            .font(.caption)
    }
}

#Preview {
    OverseerRegistrationView()
}
