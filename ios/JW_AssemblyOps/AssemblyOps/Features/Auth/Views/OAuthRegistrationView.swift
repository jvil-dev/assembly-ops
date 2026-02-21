//
//  OAuthRegistrationView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/24/26.
//

// MARK: - OAuth Registration View
//
// Full-screen form for completing overseer registration after OAuth authentication.
// Displayed when a new user signs in via Apple/Google and needs to provide additional info.
//
// Parameters:
//   - email: Pre-filled from OAuth provider (read-only display)
//   - firstName/lastName: Pre-filled if provided by OAuth, otherwise editable
//   - pendingOAuthToken: Token from backend to complete registration
//
// Fields:
//   - First Name: Required, editable
//   - Last Name: Required, editable
//   - Phone: Optional contact number
//   - Congregation: Required congregation name
//
// Features:
//   - Adaptive colors for light/dark mode
//   - Animated card appearance on load
//   - Swipe-to-dismiss gesture
//   - Form validation before submission
//   - CompleteOAuthRegistrationMutation on submit
//
// Flow:
//   1. User arrives from OAuth sign-in with pendingOAuthToken
//   2. Fills in required fields (name already pre-filled if available)
//   3. On submit: Calls CompleteOAuthRegistrationMutation
//   4. On success: AppState.didLoginAsOverseer() logs user in
//

import SwiftUI
import Apollo

struct OAuthRegistrationView: View {
    let email: String
    let firstName: String?
    let lastName: String?
    let pendingOAuthToken: String

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @FocusState private var focusedField: Field?
    @State private var hasAppeared = false

    @State private var firstNameField: String
    @State private var lastNameField: String
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    private let appState = AppState.shared

    private enum Field {
        case firstName
        case lastName
    }

    init(email: String, firstName: String?, lastName: String?, pendingOAuthToken: String) {
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.pendingOAuthToken = pendingOAuthToken
        _firstNameField = State(initialValue: firstName ?? "")
        _lastNameField = State(initialValue: lastName ?? "")
    }

    // MARK: - Adaptive Colors

    private var backgroundTop: Color {
        colorScheme == .dark
            ? Color(white: 0.1)
            : Color(red: 0.98, green: 0.97, blue: 0.95)
    }

    private var backgroundBottom: Color {
        colorScheme == .dark
            ? Color(white: 0.08)
            : Color(red: 0.96, green: 0.94, blue: 0.91)
    }

    private var cardBackground: Color {
        colorScheme == .dark
            ? Color(white: 0.15)
            : Color.white
    }

    private var textSecondary: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.6)
            : Color(red: 0.45, green: 0.45, blue: 0.45)
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundGradient

                ScrollView {
                    VStack(spacing: 0) {
                        Spacer(minLength: geometry.size.height * 0.08)

                        cardContent
                            .padding(.horizontal, 28)

                        Spacer(minLength: geometry.size.height * 0.08)
                    }
                    .frame(minHeight: geometry.size.height)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.width > 100 && abs(value.translation.height) < 100 {
                        dismiss()
                    }
                }
        )
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [backgroundTop, backgroundBottom],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Card

    private var cardContent: some View {
        VStack(spacing: 28) {
            headerSection
            formSection
            errorSection
            registerButton
            helpText
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 36)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 8)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 20)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .shadow(color: Color("ThemeColor").opacity(0.15), radius: 12, x: 0, y: 4)

            Text("Complete Registration")
                .font(.system(size: 24, weight: .semibold, design: .default))
                .foregroundStyle(Color("ThemeColor"))
                .tracking(0.3)

            Text("Just a few more details to get started")
                .font(.subheadline)
                .foregroundStyle(textSecondary)
        }
    }

    // MARK: - Form

    private var formSection: some View {
        VStack(spacing: 20) {
            // Email display (read-only)
            VStack(alignment: .leading, spacing: 6) {
                Text("EMAIL")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.gray)

                Text(email)
                    .font(.system(size: 17, weight: .regular, design: .default))
                    .foregroundStyle(textSecondary)

                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 1)
            }

            // First Name
            UnderlineTextField(
                label: "FIRST NAME",
                placeholder: "Enter your first name",
                text: $firstNameField,
                isSecure: false,
                isFocused: focusedField == .firstName,
                onSubmit: { focusedField = .lastName },
                autocapitalization: .words,
                keyboardType: .default,
                isMonospaced: false
            )
            .focused($focusedField, equals: .firstName)

            // Last Name
            UnderlineTextField(
                label: "LAST NAME",
                placeholder: "Enter your last name",
                text: $lastNameField,
                isSecure: false,
                isFocused: focusedField == .lastName,
                onSubmit: { register() },
                autocapitalization: .words,
                keyboardType: .default,
                isMonospaced: false
            )
            .focused($focusedField, equals: .lastName)
        }
    }

    // MARK: - Error

    @ViewBuilder
    private var errorSection: some View {
        if let error = errorMessage {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.subheadline)
                Text(error)
                    .font(.subheadline)
            }
            .foregroundStyle(Color(red: 0.8, green: 0.25, blue: 0.2))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 0.8, green: 0.25, blue: 0.2).opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }

    // MARK: - Button

    private var registerButton: some View {
        Button {
            register()
        } label: {
            Group {
                if isSubmitting {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Complete Registration")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isFormValid ? Color("ThemeColor") : Color("ThemeColor").opacity(0.4))
        )
        .foregroundStyle(.white)
        .disabled(!isFormValid || isSubmitting)
        .animation(.easeInOut(duration: 0.2), value: isFormValid)
    }

    // MARK: - Help

    private var helpText: some View {
        Text("Your information is used for event coordination only")
            .font(.footnote)
            .foregroundStyle(textSecondary)
            .multilineTextAlignment(.center)
    }

    // MARK: - Validation

    private var isFormValid: Bool {
        !firstNameField.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastNameField.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Registration

    private func register() {
        guard isFormValid else { return }

        isSubmitting = true
        errorMessage = nil

        let input = AssemblyOpsAPI.CompleteOAuthRegistrationInput(
            pendingOAuthToken: pendingOAuthToken,
            firstName: firstNameField.trimmingCharacters(in: .whitespaces),
            lastName: lastNameField.trimmingCharacters(in: .whitespaces)
        )

        NetworkClient.shared.apollo.perform(
            mutation: AssemblyOpsAPI.CompleteOAuthRegistrationMutation(input: input)
        ) { result in
            Task { @MainActor in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.completeOAuthRegistration {
                        let overseer = OverseerInfo(
                            id: data.admin.id,
                            email: data.admin.email,
                            fullName: data.admin.fullName,
                            firstName: data.admin.firstName,
                            lastName: data.admin.lastName,
                            phone: nil,
                            congregationId: nil,
                            circuitId: nil,
                            overseerType: ""
                        )
                        appState.didLoginAsOverseer(
                            overseer: overseer,
                            accessToken: data.accessToken,
                            refreshToken: data.refreshToken,
                            expiresIn: data.expiresIn
                        )
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        errorMessage = errors.first?.localizedDescription ?? "Registration failed"
                    }
                case .failure:
                    errorMessage = "Unable to connect. Please try again."
                }
                isSubmitting = false
            }
        }
    }
}

#Preview {
    OAuthRegistrationView(
        email: "",
        firstName: "",
        lastName: nil,
        pendingOAuthToken: "token"
    )
}
