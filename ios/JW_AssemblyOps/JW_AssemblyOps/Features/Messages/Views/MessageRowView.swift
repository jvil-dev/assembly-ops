//
//  MessageRowView.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 1/13/26.
//

// MARK: - Message Row View
//
// List row component for displaying a single message preview.
//
// Features:
//   - Blue dot indicator for unread messages
//   - Icon based on recipient type (person/group/megaphone)
//   - Subject with bold styling for unread
//   - Sender name and timestamp
//   - Body preview (2 lines)
//
// Dependencies:
//   - Message: Data model
//
// Used by: MessagesView

import SwiftUI

struct MessageRowView: View {
    let message: Message
    
    var body: some View {
        HStack(spacing: 12) {
            // Unread indicator
            Circle()
                .fill(message.isRead ? Color.clear : Color.blue)
                .frame(width: 10, height: 10)
            
            // Message type icon
            Image(systemName: message.recipientType.icon)
                .font(.title3)
                .foregroundStyle(message.isRead ? .secondary : .primary)
                .frame(width: 30)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(message.displaySubject)
                        .font(.headline)
                        .fontWeight(message.isRead ? .regular : .semibold)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(message.formattedDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                if let sender = message.senderName {
                    Text("From: \(sender)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text(message.body)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

#Preview {
    List {
        MessageRowView(message: .preview)
        MessageRowView(message: .previewRead)
        MessageRowView(message: .previewDepartment)
    }
}
