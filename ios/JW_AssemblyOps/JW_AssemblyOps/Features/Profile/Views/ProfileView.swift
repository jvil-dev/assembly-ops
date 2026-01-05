//
//  ProfileView.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 1/3/26.
//

// MARK: - Profile View
//
// Displays volunteer profile information and provides logout functionality.
//
// Components:
//   - Profile header: Avatar with initials, name, congregation, appointment status
//   - Department card: Department name with lanyard color indicator
//   - Event card: Event name, venue, address, dates
//   - Contact card: Phone and email (if available)
//   - Logout button: Confirms and logs out volunteer
//
// Dependencies:
//   - ProfileViewModel: Fetches volunteer data from GraphQL
//   - AppState: Handles logout
//   - DepartmentColor: Provides department color mapping
//
// Used by: MainTabView.swift (Profile tab)

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject private var appState: AppState
    @State private var showingLogoutAlert = false
    
    var body: some View {
        NavigationStack {
            Group {
                if !viewModel.hasLoaded {
                    LoadingView(message: "Loading profile...")
                } else if let error = viewModel.errorMessage, viewModel.volunteer == nil {
                    ErrorView(message: error) {
                        viewModel.refresh()
                    }
                } else if let volunteer = viewModel.volunteer {
                    profileContent(volunteer: volunteer)
                } else {
                    EmptyView()
                }
            }
            .navigationTitle("Profile")
            .refreshable {
                viewModel.refresh()
            }
            .task {
                if !viewModel.hasLoaded {
                    viewModel.fetchProfile()
                }
            }
            .alert("Log Out", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Log Out", role: .destructive) {
                    Task {
                        appState.logout()
                    }
                }
            } message: {
                Text("Are you sure you want to log out?")
            }
        }
    }
    
    private func profileContent(volunteer: Volunteer) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile header
                profileHeader(volunteer: volunteer)
                
                // Department card
                if let deptName = volunteer.departmentName,
                   let deptType = volunteer.departmentType {
                    departmentCard(name: deptName, type: deptType)
                }
                
                // Event info
                eventCard(volunteer: volunteer)
                
                // Contact info
                if volunteer.phone != nil || volunteer.email != nil {
                    contactCard(volunteer: volunteer)
                }
                
                // Logout button
                logoutButton
                
                // App version
                appVersion
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Subviews
    
    private func profileHeader(volunteer: Volunteer) -> some View {
        VStack(spacing: 16) {
            // Avatar with initials
            ZStack {
                Circle()
                    .fill(volunteer.departmentColor.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Text(volunteer.initials)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(volunteer.departmentColor)
            }
            
            VStack(spacing: 4) {
                Text(volunteer.fullName)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(volunteer.congregation)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                if let appointment = volunteer.appointmentStatus {
                    Text(formatAppointment(appointment))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func departmentCard(name: String, type: String) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(DepartmentColor.color(for: type))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: departmentIcon(for: type))
                        .foregroundStyle(.white)
                        .font(.system(size: 18, weight: .medium))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Department")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(name)
                    .font(.headline)
            }
            
            Spacer()
            
            // Lanyard color indicator
            VStack(spacing: 2) {
                Text(DepartmentColor.colorName(for: type))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("Lanyard")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func eventCard(volunteer: Volunteer) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Event", systemImage: "calendar")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(volunteer.eventName)
                .font(.headline)
            
            if let venue = volunteer.eventVenue {
                HStack(spacing: 6) {
                    Image(systemName: "building.2")
                        .font(.caption)
                    Text(venue)
                        .font(.subheadline)
                }
                .foregroundStyle(.secondary)
            }
            
            if let address = volunteer.eventAddress {
                HStack(spacing: 6) {
                    Image(systemName: "location")
                        .font(.caption)
                    Text(address)
                        .font(.subheadline)
                }
                .foregroundStyle(.secondary)
            }
            
            if let dateRange = volunteer.eventDateRange {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text(dateRange)
                        .font(.subheadline)
                }
                .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func contactCard(volunteer: Volunteer) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Contact Info", systemImage: "person.text.rectangle")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if let phone = volunteer.phone {
                HStack(spacing: 6) {
                    Image(systemName: "phone")
                        .font(.caption)
                    Text(phone)
                        .font(.subheadline)
                }
            }
            
            if let email = volunteer.email {
                HStack(spacing: 6) {
                    Image(systemName: "envelope")
                        .font(.caption)
                    Text(email)
                        .font(.subheadline)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var logoutButton: some View {
        Button(role: .destructive) {
            showingLogoutAlert = true
        } label: {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Log Out")
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
        }
        .buttonStyle(.bordered)
        .tint(.red)
    }
    
    private var appVersion: some View {
        VStack(spacing: 4) {
            Text("AssemblyOps")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Version 1.0.0 (Beta)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Helpers
    
    private func formatAppointment(_ status: String) -> String {
        switch status.uppercased() {
        case "ELDER": return "Elder"
        case "MINISTERIAL_SERVANT": return "Ministerial Servant"
        case "PUBLISHER": return "Publisher"
        default: return status
        }
    }
    
    private func departmentIcon(for type: String) -> String {
        switch type.uppercased() {
        case "PARKING": return "car"
        case "ATTENDANT": return "person.badge.shield.checkmark"
        case "AUDIO_VIDEO", "AV": return "video"
        case "CLEANING": return "sparkles"
        case "COMMITTEE": return "person.3"
        case "FIRST_AID", "FIRSTAID": return "cross"
        case "BAPTISM": return "drop"
        case "INFORMATION", "INFORMATION_VOLUNTEER_SERVICE": return "info.circle"
        case "ACCOUNTS": return "dollarsign.circle"
        case "INSTALLATION": return "hammer"
        case "LOST_FOUND", "LOST_AND_FOUND", "LOST_FOUND_CHECKROOM": return "tray"
        case "ROOMING": return "bed.double"
        case "TRUCKING", "TRUCKING_EQUIPMENT": return "truck.box"
        default: return "person"
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppState.shared)
}
