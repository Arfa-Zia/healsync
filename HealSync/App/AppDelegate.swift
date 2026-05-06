//
//  AppDelegate.swift
//  HealSync
//
//  Created by Arfa on 08/01/2026.
//

import UIKit
import Firebase
import UserNotifications
import FirebaseAuth

@main
class AppDelegate: UIResponder, UIApplicationDelegate{

    override init() {
            super.init()
            UIFont.swizzleSystemFonts()
        }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        requestNotificationPermission()
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    func requestNotificationPermission() {
        
        let center = UNUserNotificationCenter.current()
        
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            
            if granted {
                print("Notifications permission granted")
            } else {
                print("Notifications permission denied")
            }
        }
    }
    


}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

        let content = notification.request.content
        let identifier = notification.request.identifier
        let type = content.userInfo["type"] as? String ?? "reminder"
        let targetUserId = content.userInfo["userId"] as? String ?? Auth.auth().currentUser?.uid

        if let uid = targetUserId {
            let db = Firestore.firestore()
            
            db.collection("users").document(uid).collection("notifications")
                .whereField("identifier", isEqualTo: identifier)
                .getDocuments { snapshot, error in
                    if snapshot?.documents.isEmpty == true {
                        NotificationService.shared.createNotification(
                            forUser: uid,
                            title: content.title,
                            message: content.body,
                            type: type,
                            identifier: identifier
                        )
                    }
                }
        }

        completionHandler([.banner, .sound])
    }
}

