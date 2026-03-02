//
//  OAuthRegistrationView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/24/26.
//

// MARK: - OAuth Registration View
//
// Full-screen form for completing registration after OAuth authentication.
// Displayed when a new user signs in via Apple/Google and needs to provide name info.
//
// Parameters:
//   - email: Pre-filled from OAuth provider (read-only display)
//   - firstName/lastName: Pre-filled if provided by OAuth, otherwise editable
//   - pendingOAuthToken: Token from backend to complete registration
//
// Features:
//   - AppTheme-compliant colors (no local computed color properties)
//   - Animated card appearance
//   - Overseer toggle
//   - CompleteOAuthRegistrationMutation on submit

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
    @State private var isOverseer: Bool = false
    @State private var congregationName: String = ""
    @State private var congregationId: String?
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showError = false

    private let appState = AppState.shared

    private enum Field {
        case firstName, lastName
    }

    init(email: String, firstName: String?, lastName: String?, pendingOAuthToken: String) {
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.pendingOAuthToken = pendingOAuthToken
        _firstNameField = State(initialValue: firstName ?? "")
        _lastNameField = State(initialValue: lastName ?? "")
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                AppTheme.backgroundGradient(for: colorScheme)
                    .ignoresSafeArea()

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
        .onChange(of: errorMessage) { _, error in
            showError = error != nil
        }
        .alert("Registration Failed", isPresented: $showError) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Card

    private var cardContent: some View {
        VStack(spacing: 28) {
            headerSection
            formSection
            overseerToggle
            registerButton
            helpText
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 36)
        .background(AppTheme.cardBackground(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
        .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 8)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 20)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.themeColor.opacity(colorScheme == .dark ? 0.22 : 0.1))
                    .frame(width: 88, height: 88)
                Image(systemName: "person.fill")
                    .font(.system(size: 38, weight: .medium))
                    .foregroundStyle(AppTheme.themeColor)
            }

            Text("auth.oauth.completeRegistration".localized)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(AppTheme.themeColor)

            Text("auth.oauth.subtitle".localized)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
    }

    // MARK: - Form

    private var formSection: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("EMAIL")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))

                HStack {
                    Text(email)
                        .font(.system(size: 17))
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    Spacer()
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }
                .padding(.bottom, 8)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(AppTheme.dividerColor(for: colorScheme))
                        .frame(height: 1)
                }
            }

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

            UnderlineTextField(
                label: "LAST NAME",
                placeholder: "Enter your last name",
                text: $lastNameField,
                isSecure: false,
                isFocused: focusedField == .lastName,
                onSubmit: { focusedField = nil },
                autocapitalization: .words,
                keyboardType: .default,
                isMonospaced: false
            )
            .focused($focusedField, equals: .lastName)

            VStack(alignment: .leading, spacing: 6) {
                Text("CONGREGATION")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))

                CongregationSearchField(
                    selectedName: $congregationName,
                    selectedId: $congregationId
                )
            }
        }
    }

    // MARK: - Overseer Toggle

    private var overseerToggle: some View {
        Toggle(isOn: $isOverseer) {
            VStack(alignment: .leading, spacing: 2) {
                Text(NSLocalizedString("auth.isOverseer.toggle", comment: ""))
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                if isOverseer {
                    Text(NSLocalizedString("auth.isOverseer.explainer", comment: ""))
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.themeColor)
                        .transition(.opacity)
                }
            }
        }
        .tint(AppTheme.themeColor)
        .animation(.easeInOut(duration: 0.2), value: isOverseer)
    }

    // MARK: - Button

    private var registerButton: some View {
        Button {
            register()
        } label: {
            Group {
                if isSubmitting {
                    ProgressView().tint(.white)
                } else {
                    Text("auth.oauth.completeRegistration".localized)
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: AppTheme.ButtonHeight.large)
        }
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                .fill(isFormValid ? AppTheme.themeColor : AppTheme.themeColor.opacity(0.4))
                .shadow(color: AppTheme.themeColor.opacity(isFormValid ? 0.3 : 0),
                        radius: 10, x: 0, y: 3)
        )
        .foregroundStyle(.white)
        .disabled(!isFormValid || isSubmitting)
        .animation(AppTheme.quickAnimation, value: isFormValid)
    }

    // MARK: - Help

    private var helpText: some View {
        Text("auth.privacyNote".localized)
            .font(.footnote)
            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
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
            lastName: lastNameField.trimmingCharacters(in: .whitespaces),
            isOverseer: isOverseer ? .some(true) : .none,
            congregation: congregationName.isEmpty ? .none : .some(congregationName),
            congregationId: congregationId.map { .some($0) } ?? .none
        )

        NetworkClient.shared.apollo.perform(
            mutation: AssemblyOpsAPI.CompleteOAuthRegistrationMutation(input: input)
        ) { result in
            Task { @MainActor in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.completeOAuthRegistration {
                        let user = UserInfo(
                            id: data.user.id,
                            userId: data.user.userId,
                            email: data.user.email,
                            firstName: data.user.firstName,
                            lastName: data.user.lastName,
                            fullName: data.user.fullName,
                            phone: nil,
                            congregation: data.user.congregation,
                            congregationId: data.user.congregationId,
                            circuitCode: data.user.congregationRef?.circuit.code,
                            circuitId: data.user.congregationRef?.circuit.id,
                            appointmentStatus: nil,
                            isOverseer: data.user.isOverseer
                        )
                        self.appState.didLogin(
                            user: user,
                            accessToken: data.accessToken,
                            refreshToken: data.refreshToken,
                            expiresIn: data.expiresIn
                        )
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        self.errorMessage = errors.first?.message ?? "Registration failed"
                    }
                case .failure:
                    self.errorMessage = "Unable to connect. Please try again."
                }
                self.isSubmitting = false
            }
        }
    }
}

#Preview {
    OAuthRegistrationView(
        email: "user@example.com",
        firstName: "Jorge",
        lastName: nil,
        pendingOAuthToken: "token"
    )
}
