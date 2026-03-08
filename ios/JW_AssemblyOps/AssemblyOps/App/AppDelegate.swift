//
//  AppDelegate.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 3/7/26.
//

// MARK: - App Delegate
//
// UIApplicationDelegate adaptor for Firebase Cloud Messaging (FCM).
// Required because push notification registration uses UIKit delegate methods.
//
// Responsibilities:
//   - Initialize Firebase on app launch
//   - Forward APNs device token to Firebase Messaging
//   - Receive FCM registration token and pass to PushNotificationManager
//   - Display notifications in foreground (banner + sound)
//   - Handle notification tap → PushNotificationManager deep link
//
// Dependencies:
//   - FirebaseCore, FirebaseMessaging
//   - PushNotificationManager

import UIKit
import FirebaseCore
import FirebaseMessaging

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()

        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self

        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }

    // MARK: - MessagingDelegate

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        Task {
            await PushNotificationManager.shared.didReceiveFCMToken(token)
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    // Show notifications when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        Task {
            await PushNotificationManager.shared.handleNotificationTap(userInfo: userInfo)
        }
        completionHandler()
    }
}
