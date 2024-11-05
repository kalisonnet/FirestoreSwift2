//
//  FirestoreSwiftApp.swift
//  FirestoreSwift
//
//  Created by Kamran Alison on 8/6/24.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseMessaging
import UserNotifications

@main
struct FirestoreSwiftApp: App {
    
    // Register AppDelegate for push notifications
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
            WindowGroup {
                NavigationStack {
                    WelcomeView() // The first screen in the navigation flow
                }
            }
        }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Register for push notifications
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
            if granted {
                print("Notification permission granted.")
            } else {
                print("Notification permission denied: \(String(describing: error))")
            }
        }
        application.registerForRemoteNotifications()

        // Set up Firebase Messaging delegate
        Messaging.messaging().delegate = self
        
        // Ensure FCM token is refreshed
        Messaging.messaging().token { token, error in
            if let error = error {
                print("Error fetching FCM token: \(error.localizedDescription)")
                return
            }

            if let token = token {
                print("FCM token from launch: \(token)")
                // Store the token for your user when it is first generated
            }
        }

        return true
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else {
            print("Failed to retrieve FCM token")
            return
        }
        
        print("Firebase Cloud Messaging token: \(fcmToken)")
        // Store this token in Realtime Database
        if let userId = Auth.auth().currentUser?.uid {
            registerFCMToken(userId: userId, fcmToken: fcmToken)
        }
    }

    // Store FCM token in Firebase Realtime Database
    func registerFCMToken(userId: String, fcmToken: String) {
        let ref = Database.database().reference().child("users").child(userId)
        ref.updateChildValues(["fcmToken": fcmToken]) { (error, _) in
            if let error = error {
                print("Failed to store FCM token: \(error.localizedDescription)")
            } else {
                print("FCM Token updated in Realtime Database: \(fcmToken)")
            }
        }
    }

    // Handle push notifications when app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound])
        } else {
            completionHandler([.alert, .sound])
        }
    }

    // Handle when a user taps a notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}

