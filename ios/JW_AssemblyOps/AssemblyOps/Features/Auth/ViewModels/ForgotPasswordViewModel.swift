//
//  ForgotPasswordViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 3/19/26.
//

// MARK: - Forgot Password View Model
//
// Manages the 3-step forgot password flow:
//   1. Enter email → request reset code
//   2. Enter 6-digit code → verify and get reset token
//   3. Enter new password → reset and auto-login
//
// Properties:
//   - step: Current flow step (.enterEmail / .enterCode / .newPassword)
//   - email/code/newPassword/confirmNewPassword: Form fields
//   - isLoading: True during network requests
//   - errorMessage: User-facing error text
//   - didResetSuccessfully: Triggers dismiss + auto-login
//
// Methods:
//   requestReset(): Send 6-digit code to email
//   - verifyCode(): Validate code and receive reset JWT
//   - resetPassword(): Set new password and auto-login
//   - resendCode(): Re-send the 6-digit code

import Foundation
import Combine
import Apollo

@MainActor
final class ForgotPasswordViewModel: ObservableObject {

    enum Step {
        case enterEmail
        case enterCode
        case newPassword
    }

    @Published var step: Step = .enterEmail
    @Published var email = ""
    @Published var code = ""
    @Published var newPassword = ""
    @Published var confirmNewPassword = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var didResetSuccessfully = false
    @Published var resendCooldown: Int = 0

    private var resetToken = ""
    private var cooldownTimer: Timer?
    private let appState = AppState.shared

    var canSendCode: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        email.contains("@")
    }

    var canVerifyCode: Bool {
        code.count == 6
    }

    var canResetPassword: Bool {
        newPassword.count >= 8 &&
        newPassword == confirmNewPassword
    }

    var passwordStrengthMet: Bool {
        newPassword.count >= 8
    }

    var passwordsMatch: Bool {
        confirmNewPassword.isEmpty || newPassword == confirmNewPassword
    }

    // MARK: - Step 1: Request Reset

    func requestReset() {
        guard canSendCode else { return }
        isLoading = true
        errorMessage = nil

        let input = AssemblyOpsAPI.RequestPasswordResetInput(
            email: email.lowercased().trimmingCharacters(in: .whitespaces)
        )

        NetworkClient.shared.apollo.perform(
            mutation: AssemblyOpsAPI.RequestPasswordResetMutation(input: input)
        ) { [weak self] result in
            Task { @MainActor in
                defer { self?.isLoading = false }
                switch result {
                case .success(let graphQLResult):
                    if graphQLResult.data?.requestPasswordReset.success == true {
                        self?.step = .enterCode
                        self?.startCooldownTimer()
                        HapticManager.shared.success()
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        self?.errorMessage = errors.first?.message
                    }
                case .failure:
                    self?.errorMessage = NSLocalizedString("common.connectionError", comment: "")
                    HapticManager.shared.error()
                }
            }
        }
    }

    // MARK: - Step 2: Verify Code

    func verifyCode() {
        guard canVerifyCode else { return }
        isLoading = true
        errorMessage = nil



        let input = AssemblyOpsAPI.VerifyResetCodeInput(
            email: email.lowercased().trimmingCharacters(in: .whitespaces),
            code: code
        )

        NetworkClient.shared.apollo.perform(
            mutation: AssemblyOpsAPI.VerifyResetCodeMutation(input: input)
        ) { [weak self] result in
            Task { @MainActor in
                defer { self?.isLoading = false }
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.verifyResetCode {
                        self?.resetToken = data.resetToken
                        self?.step = .newPassword
                        HapticManager.shared.success()
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        self?.errorMessage = errors.first?.message
                        HapticManager.shared.error()
                    }
                case .failure:
                    self?.errorMessage = NSLocalizedString("common.connectionError", comment: "")
                    HapticManager.shared.error()
                }
            }
        }
    }

    // MARK: - Step 3: Reset Password

    func resetPassword() {
        guard canResetPassword else { return }
        isLoading = true
        errorMessage = nil

        let input = AssemblyOpsAPI.ResetPasswordInput(
            resetToken: resetToken,
            newPassword: newPassword
        )

        NetworkClient.shared.apollo.perform(
            mutation: AssemblyOpsAPI.ResetPasswordMutation(input: input)
        ) { [weak self] result in
            Task { @MainActor in
                defer { self?.isLoading = false }
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.resetPassword {
                        let user = UserInfo(
                            id: data.user.id,
                            userId: data.user.userId,
                            email: data.user.email,
                            firstName: data.user.firstName,
                            lastName: data.user.lastName,
                            fullName: data.user.fullName,
                            phone: data.user.phone,
                            congregation: data.user.congregation,
                            congregationId: data.user.congregationId,
                            circuitCode: data.user.congregationRef?.circuit.code,
                            circuitId: data.user.congregationRef?.circuit.id,
                            appointmentStatus: data.user.appointmentStatus?.rawValue,
                            isOverseer: data.user.isOverseer
                        )
                        HapticManager.shared.success()
                        self?.appState.didLogin(
                            user: user,
                            accessToken: data.accessToken,
                            refreshToken: data.refreshToken,
                            expiresIn: data.expiresIn
                        )
                        self?.didResetSuccessfully = true
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        self?.errorMessage = errors.first?.message
                        HapticManager.shared.error()
                    }
                case .failure:
                    self?.errorMessage = NSLocalizedString("common.connectionError", comment: "")
                    HapticManager.shared.error()
                }
            }
        }
    }

    // MARK: - Resend Code

    func resendCode() {
        guard resendCooldown == 0 else { return }
        code = ""
        requestReset()
    }

    // MARK: - Cooldown Timer

    private func startCooldownTimer() {
        cooldownTimer?.invalidate()
        resendCooldown = 60
        cooldownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self else {
                    timer.invalidate()
                    return
                }
                self.resendCooldown -= 1
                if self.resendCooldown <= 0 {
                    self.resendCooldown = 0
                    timer.invalidate()
                }
            }
        }
    }

    deinit {
        cooldownTimer?.invalidate()
    }
}
