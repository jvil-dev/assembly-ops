//
//  PushNotificationManager.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 3/7/26.
//

// MARK: - Push Notification Manager
//
// Coordinates push notification lifecycle: permission, token registration, and deep linking.
//
// Properties:
//   - pendingDeepLink: Set when a notification is tapped, consumed by EventsHomeView
//
// Methods:
//   - requestPermissionIfNeeded(): Request notification auth + register for remote notifications
//   - didReceiveFCMToken(_:): Called from AppDelegate when FCM token is received/refreshed
//   - registerCurrentToken(): Called after login to register any existing FCM token
//   - unregisterCurrentToken(): Called on logout to remove token from backend
//   - handleNotificationTap(userInfo:): Parse notification data and set pendingDeepLink
//
// Dependencies:
//   - PushNotificationService: GraphQL client for token registration
//   - KeychainManager: Check login state
//   - FirebaseMessaging: FCM token retrieval

import Foundation
import UIKit
import UserNotifications
import FirebaseMessaging
import Combine

@MainActor
final class PushNotificationManager: ObservableObject {
    static let shared = PushNotificationManager()

    @Published var pendingDeepLink: NotificationDeepLink?

    private var currentFCMToken: String?

    private init() {}

    // MARK: - Permission Request

    func requestPermissionIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                if settings.authorizationStatus == .notDetermined {
                    UNUserNotificationCenter.current().requestAuthorization(
                        options: [.alert, .sound, .badge]
                    ) { granted, _ in
                        if granted {
                            DispatchQueue.main.async {
                                UIApplication.shared.registerForRemoteNotifications()
                            }
                        }
                    }
                } else if settings.authorizationStatus == .authorized {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }

    // MARK: - Token Management

    func didReceiveFCMToken(_ token: String) {
        guard token != currentFCMToken else { return }
        currentFCMToken = token

        guard KeychainManager.shared.isLoggedIn else { return }

        Task {
            await registerTokenWithBackend(token)
        }
    }

    /// Called after login to register any existing FCM token
    func registerCurrentToken() {
        Messaging.messaging().token { [weak self] token, error in
            guard let token = token, error == nil else { return }
            Task { @MainActor in
                self?.currentFCMToken = token
                await self?.registerTokenWithBackend(token)
            }
        }
    }

    /// Called on logout to remove the current device token
    func unregisterCurrentToken() {
        guard let token = currentFCMToken else { return }
        let tokenCopy = token
        currentFCMToken = nil
        Task {
            await unregisterTokenWithBackend(tokenCopy)
        }
    }

    // MARK: - Notification Tap Handling

    func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        guard let type = userInfo["type"] as? String,
              let eventId = userInfo["eventId"] as? String else { return }

        let assignmentId = userInfo["assignmentId"] as? String
        let requestId = userInfo["requestId"] as? String
        let messageId = userInfo["messageId"] as? String
        let conversationId = userInfo["conversationId"] as? String

        pendingDeepLink = NotificationDeepLink(
            type: type,
            eventId: eventId,
            assignmentId: assignmentId,
            requestId: requestId,
            messageId: messageId,
            conversationId: conversationId
        )
    }

    // MARK: - Backend Registration

    private func registerTokenWithBackend(_ token: String) async {
        do {
            _ = try await PushNotificationService.shared.registerDeviceToken(token: token)
        } catch {
            #if DEBUG
            print("Failed to register device token: \(error)")
            #endif
        }
    }

    private func unregisterTokenWithBackend(_ token: String) async {
        do {
            _ = try await PushNotificationService.shared.unregisterDeviceToken(token: token)
        } catch {
            #if DEBUG
            print("Failed to unregister device token: \(error)")
            #endif
        }
    }
}

// MARK: - NotificationDeepLink

struct NotificationDeepLink: Equatable {
    let type: String
    let eventId: String
    let assignmentId: String?
    let requestId: String?
    let messageId: String?
    let conversationId: String?

    /// Whether this deep link targets a messaging flow
    var isMessageType: Bool {
        ["NEW_MESSAGE", "DEPARTMENT_MESSAGE", "BROADCAST", "CONVERSATION_MESSAGE"].contains(type)
    }
}
