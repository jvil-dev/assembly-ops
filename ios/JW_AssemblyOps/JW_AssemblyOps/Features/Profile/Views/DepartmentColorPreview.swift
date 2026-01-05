//
//  DepartmentColorPreview.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 1/3/26.
//

// MARK: - Department Color Preview
//
// Developer reference view showing all 13 department colors with lanyard swatches.
// Useful for verifying color mapping and visual consistency.
//
// Not used in production - preview only.

import SwiftUI

struct DepartmentColorPreview: View {
    let departments = [
        ("PARKING", "Parking"),
        ("ATTENDANT", "Attendant"),
        ("AUDIO_VIDEO", "Audio/Video"),
        ("CLEANING", "Cleaning"),
        ("COMMITTEE", "Committee"),
        ("FIRST_AID", "First Aid"),
        ("BAPTISM", "Baptism"),
        ("INFORMATION", "Information"),
        ("ACCOUNTS", "Accounts"),
        ("INSTALLATION", "Installation"),
        ("LOST_FOUND", "Lost & Found"),
        ("ROOMING", "Rooming"),
        ("TRUCKING", "Trucking"),
    ]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(departments, id: \.0) { type, name in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(DepartmentColor.color(for: type))
                            .frame(width: 32, height: 32)
                        
                        VStack(alignment: .leading) {
                            Text(name)
                                .font(.headline)
                            Text(DepartmentColor.colorName(for: type))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        // Lanyard swatch
                        RoundedRectangle(cornerRadius: 4)
                            .fill(DepartmentColor.color(for: type))
                            .frame(width: 40, height: 60)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
                            )
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Department Colors")
        }
    }
}

#Preview {
    DepartmentColorPreview()
}
