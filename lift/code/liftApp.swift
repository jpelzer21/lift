//
//  liftApp.swift
//  lift
//
//  Created by Josh Pelzer on 2/20/25.
//

import SwiftUI
import Firebase
import FirebaseCore
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        FirebaseApp.configure()
        
        UNUserNotificationCenter.current().delegate = self
        requestNotificationPermission()
        
        return true
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    // Handle notifications while app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               willPresent notification: UNNotification,
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification taps
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               didReceive response: UNNotificationResponse,
                               withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle deep links or navigation here if needed
        completionHandler()
    }
}


@main
struct liftApp: App {
    let persistenceController = PersistenceController.shared
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            LoginView()
        }
    }
}
