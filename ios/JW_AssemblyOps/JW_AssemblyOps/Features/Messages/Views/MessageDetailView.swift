//
//  MessageDetailView.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 1/13/26.
//

// MARK: - Message Detail View
//
// Full-screen view for reading a single message.
//
// Features:
//   - Recipient type badge (Direct/Department/Announcement)
//   - Subject, sender, and timestamp
//   - Full message body
//   - Auto-marks message as read on appear
//
// Dependencies:
//   - Message: Data model
//   - onMarkRead callback: Called when view appears
//
// Used by: MessagesView (navigation destination)

import SwiftUI

struct MessageDetailView: View {
    let message: Message
    let onMarkRead: () async -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    // Type badge
                    HStack(spacing: 6) {
                        Image(systemName: message.recipientType.icon)
                        Text(message.recipientType.displayName)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(Capsule())
                    
                    // Subject
                    Text(message.displaySubject)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // Meta info
                    HStack {
                        if let sender = message.senderName {
                            Text("From: \(sender)")
                        }
                        
                        Spacer()
                        
                        Text(message.createdAt.formatted(date: .abbreviated, time: .shortened))
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                
                Divider()
                
                // Body
                Text(message.body)
                    .font(.body)
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Message")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if !message.isRead {
                await onMarkRead()
            }
        }
    }
}

#Preview {
    NavigationStack {
        MessageDetailView(message: .preview) {
            // Mark read action
        }
    }
}
