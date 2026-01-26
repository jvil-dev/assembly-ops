//
//  VolunteerLoginView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 12/27/25.
//

// MARK: - Login View
//
// Volunteer login screen with credential entry form.
// Volunteers receive their ID and token from their overseer.
//
// Components:
//   - Header: App logo and branding
//   - Form: Volunteer ID and Token fields with auto-capitalization
//   - Error display: Shows authentication errors
//   - Login button: Disabled until form is valid
//   - Help text: Instructions for obtaining credentials
//
// Behavior:
//   - Fields auto-capitalize and trim whitespace
//   - Keyboard navigation: ID → Token → Submit
//   - Button shows loading spinner during login
//   - On success: AppState.isLoggedIn triggers navigation to MainTabView
//
// Dependencies:
//   - LoginViewModel: Handles form state and API calls
//
// Used by: JW_AssemblyOpsApp.swift (when not logged in)

import SwiftUI

struct UnderlineTextField: View {
    @Environment(\.colorScheme) var colorScheme
    
    let label: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var isFocused: Bool
    var onSubmit: () -> Void = {}
    
    var autocapitalization: TextInputAutocapitalization = .characters
    var keyboardType: UIKeyboardType = .default
    var isMonospaced: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Floating label
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(isFocused ? Color("ThemeColor") : Color.gray)
                .animation(.easeInOut(duration: 0.2), value: isFocused)
            
            // Text field
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .submitLabel(.go)
                        .onSubmit(onSubmit)
                } else {
                    TextField(placeholder, text: $text)
                        .submitLabel(.next)
                        .onSubmit(onSubmit)
                }
            }
            .font(isMonospaced 
                ? .system(size: 17, weight: .regular, design: .monospaced)
                : .system(size: 17, weight: .regular, design: .default))
            .foregroundStyle(colorScheme == .dark ? .white : .black)
            .textInputAutocapitalization(autocapitalization)
            .keyboardType(keyboardType)
            .autocorrectionDisabled()
            .tint(Color("ThemeColor"))
            
            // Animated underline
            Rectangle()
                .fill(isFocused ? Color("ThemeColor").opacity(0.3) : Color.clear)
                .frame(height: isFocused ? 2 : 1)
                .animation(.easeInOut(duration: 0.25), value: isFocused)
        }
    }
}


struct VolunteerLoginView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = VolunteerLoginViewModel()
    @FocusState private var focusedField: Field?
    @State private var hasAppeared = false

    private enum Field {
        case volunteerId
        case token
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
                        Spacer(minLength: geometry.size.height * 0.12)
                        
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
        VStack(spacing: 32) {
            headerSection
            formSection
            errorSection
            loginButton
            helpText
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 40)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 8)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 20)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 160, height: 160)
                .shadow(color: Color("ThemeColor").opacity(0.15), radius: 12, x: 0, y: 4)

            Text("AssemblyOps")
                .font(.system(size: 28, weight: .semibold, design: .default))
                .foregroundStyle(Color("ThemeColor"))
                .tracking(0.5)

            Text("Sign in to view your assignments")
                .font(.subheadline)
                .foregroundStyle(textSecondary)
        }
    }

    // MARK: - Form

    private var formSection: some View {
        VStack(spacing: 24) {
            // Volunteer ID field with prefix
            VStack(alignment: .leading, spacing: 6) {
                Text("VOLUNTEER ID")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(focusedField == .volunteerId ? Color("ThemeColor") : Color.gray)
                    .animation(.easeInOut(duration: 0.2), value: focusedField)

                HStack(spacing: 4) {
                    // Fixed prefix
                    Text("VOL-")
                        .font(.system(size: 17, weight: .medium, design: .monospaced))
                        .foregroundStyle(colorScheme == .dark ? .white.opacity(0.6) : .gray)

                    // User input
                    TextField("XXXXXX", text: $viewModel.volunteerId)
                        .font(.system(size: 17, weight: .regular, design: .monospaced))
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .tint(Color("ThemeColor"))
                        .focused($focusedField, equals: .volunteerId)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .token }
                }

                // Underline
                Rectangle()
                    .fill(focusedField == .volunteerId ? Color("ThemeColor").opacity(0.3) : Color.clear)
                    .frame(height: focusedField == .volunteerId ? 2 : 1)
                    .animation(.easeInOut(duration: 0.25), value: focusedField)
            }

            // Token field (unchanged)
            UnderlineTextField(
                label: "TOKEN",
                placeholder: "Enter your token",
                text: $viewModel.token,
                isSecure: true,
                isFocused: focusedField == .token,
                onSubmit: { Task { viewModel.login() } }
            )
            .focused($focusedField, equals: .token)
        }
    }


    // MARK: - Error

    @ViewBuilder
    private var errorSection: some View {
        if let error = viewModel.errorMessage {
            HStack(spacing: 8) {
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

    private var loginButton: some View {
        Button {
            Task { viewModel.login() }
        } label: {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Sign In")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(viewModel.isFormValid ? Color("ThemeColor") : Color("ThemeColor").opacity(0.4))
        )
        .foregroundStyle(.white)
        .disabled(!viewModel.isFormValid || viewModel.isLoading)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isFormValid)
    }

    // MARK: - Help

    private var helpText: some View {
        Text("Need help? Ask your department overseer")
            .font(.footnote)
            .foregroundStyle(textSecondary)
            .multilineTextAlignment(.center)
    }
}

#Preview {
    VolunteerLoginView()
}
