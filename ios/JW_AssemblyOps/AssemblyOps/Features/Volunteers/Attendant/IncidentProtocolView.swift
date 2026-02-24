//
//  IncidentProtocolView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/23/26.
//

// MARK: - Incident Protocol View
//
// Full-screen emergency protocol guidance shown after reporting
// a critical safety incident (bomb threat, violent individual,
// active shooter). Content sourced from CO-23 §17, §23-26.
//
// Presented via .fullScreenCover after a successful report.
// No network calls — purely informational.

import SwiftUI

struct IncidentProtocolView: View {
    let incidentType: SafetyIncidentTypeItem
    let onDismiss: () -> Void

    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false

    var body: some View {
        ZStack {
            protocolColor.opacity(0.08)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    headerCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                    stepsCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                    dismissButton
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.xxl)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
        }
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            Image(systemName: protocolIcon)
                .font(.system(size: 48))
                .foregroundStyle(protocolColor)

            Text(protocolTitle)
                .font(AppTheme.Typography.title)
                .fontWeight(.bold)
                .foregroundStyle(protocolColor)
                .multilineTextAlignment(.center)

            Text("attendant.protocol.subtitle".localized)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .cardPadding()
        .padding(.vertical, AppTheme.Spacing.l)
        .background(protocolColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                .strokeBorder(protocolColor.opacity(0.3), lineWidth: 2)
        )
    }

    // MARK: - Steps Card

    private var stepsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.l) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "list.number")
                    .foregroundStyle(protocolColor)
                Text("attendant.protocol.steps".localized.uppercased())
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            ForEach(Array(protocolSteps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: AppTheme.Spacing.m) {
                    Text("\(index + 1)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(protocolColor)
                        .clipShape(Circle())

                    Text(step)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Dismiss Button

    private var dismissButton: some View {
        Button {
            HapticManager.shared.lightTap()
            onDismiss()
        } label: {
            Text("attendant.protocol.acknowledge".localized)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.ButtonHeight.large / 2.5)
                .background(protocolColor)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Protocol Content

    private var protocolColor: Color {
        switch incidentType {
        case .activeShooter: return .red
        case .bombThreat: return .orange
        case .violentIndividual: return .orange
        default: return AppTheme.StatusColors.warning
        }
    }

    private var protocolIcon: String {
        switch incidentType {
        case .activeShooter: return "exclamationmark.shield.fill"
        case .bombThreat: return "flame.fill"
        case .violentIndividual: return "hand.raised.fill"
        default: return "exclamationmark.triangle.fill"
        }
    }

    private var protocolTitle: String {
        switch incidentType {
        case .bombThreat: return "attendant.protocol.bombThreat.title".localized
        case .violentIndividual: return "attendant.protocol.violentIndividual.title".localized
        case .activeShooter: return "attendant.protocol.activeShooter.title".localized
        default: return ""
        }
    }

    private var protocolSteps: [String] {
        switch incidentType {
        case .bombThreat:
            return [
                "attendant.protocol.bombThreat.step1".localized,
                "attendant.protocol.bombThreat.step2".localized,
                "attendant.protocol.bombThreat.step3".localized,
                "attendant.protocol.bombThreat.step4".localized
            ]
        case .violentIndividual:
            return [
                "attendant.protocol.violentIndividual.step1".localized,
                "attendant.protocol.violentIndividual.step2".localized,
                "attendant.protocol.violentIndividual.step3".localized,
                "attendant.protocol.violentIndividual.step4".localized,
                "attendant.protocol.violentIndividual.step5".localized
            ]
        case .activeShooter:
            return [
                "attendant.protocol.activeShooter.step1".localized,
                "attendant.protocol.activeShooter.step2".localized,
                "attendant.protocol.activeShooter.step3".localized,
                "attendant.protocol.activeShooter.step4".localized,
                "attendant.protocol.activeShooter.step5".localized,
                "attendant.protocol.activeShooter.step6".localized
            ]
        default:
            return []
        }
    }
}

// MARK: - Protocol Card Trigger Extension

extension SafetyIncidentTypeItem {
    var requiresProtocolCard: Bool {
        switch self {
        case .bombThreat, .violentIndividual, .activeShooter: return true
        default: return false
        }
    }
}

#Preview("Bomb Threat") {
    IncidentProtocolView(incidentType: .bombThreat) { }
}

#Preview("Active Shooter") {
    IncidentProtocolView(incidentType: .activeShooter) { }
}

#Preview("Violent Individual") {
    IncidentProtocolView(incidentType: .violentIndividual) { }
}
