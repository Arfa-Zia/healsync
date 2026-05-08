////
////  SceneDelegate.swift
////  HealSync
////
////  Created by Arfa on 08/01/2026.
////
//
//import UIKit
//import GoogleSignIn
//import FirebaseAuth
//import FirebaseFirestore
//
//class SceneDelegate: UIResponder, UIWindowSceneDelegate {
//
//    var window: UIWindow?
//
//
//    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
//        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
//        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
//        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
//        // inside scene(_ scene:willConnectTo:options:)
//        
//        guard let windowScene = (scene as? UIWindowScene) else { return }
//        let window = UIWindow(windowScene: windowScene)
//        
//        self.window = window
//        window.makeKeyAndVisible()
//        checkAuthAndRoute(window: window)
//        
////        let firstVC = TherapistOnboardingSchedulingVC()
////        let navController = UINavigationController(rootViewController: firstVC)
////        window.rootViewController = navController
//    }
//    
//    private func checkAuthAndRoute(window: UIWindow) {
//        if let user = Auth.auth().currentUser {
//            let db = Firestore.firestore()
//            db.collection("users").document(user.uid).getDocument { document, error in
//                guard let data = document?.data() else {
//                    // Firestore doc missing entirely — send back to start
//                    DispatchQueue.main.async {
//                        window.rootViewController = UINavigationController(rootViewController: GetStartedVC())
//                    }
//                    return
//                }
//
//                let role = data["role"] as? String ?? ""
//                let isComplete = data["isOnboardingComplete"] as? Bool ?? false
//
//                DispatchQueue.main.async {
//                    if isComplete {
//                        if role == "patient" {
//                            window.rootViewController = UINavigationController(rootViewController: ClientMainTabBarController())
//                        } else {
//                            ListenerManager.shared.startListening()
//                            window.rootViewController = UINavigationController(rootViewController: TherapistMainTabBarController())
//                        }
//                    } else if !role.isEmpty {
//                        // Auth exists, role chosen, but onboarding incomplete
//                        if role == "patient" {
//                            window.rootViewController = UINavigationController(rootViewController: ClientWelcomeVC())
//                        } else {
//                            window.rootViewController = UINavigationController(rootViewController: TherapistWelcomeVC())
//                        }
//                    } else {
//                        // Auth exists but no role — send to choose role
//                        window.rootViewController = UINavigationController(rootViewController: ChooseRoleVC())
//                    }
//                }
//            }
//        } else {
//            // Not logged in at all
//            window.rootViewController = UINavigationController(rootViewController: GetStartedVC())
//        }
//    }
//    func scene(_ scene: UIScene,
//               openURLContexts URLContexts: Set<UIOpenURLContext>) {
//        
//        guard let url = URLContexts.first?.url else { return }
//        
//        GIDSignIn.sharedInstance.handle(url)
//    }
//    
//    func sceneDidDisconnect(_ scene: UIScene) {
//        // Called as the scene is being released by the system.
//        // This occurs shortly after the scene enters the background, or when its session is discarded.
//        // Release any resources associated with this scene that can be re-created the next time the scene connects.
//        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
//    }
//
//    func sceneDidBecomeActive(_ scene: UIScene) {
//        // Called when the scene has moved from an inactive state to an active state.
//        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
//    }
//
//    func sceneWillResignActive(_ scene: UIScene) {
//        // Called when the scene will move from an active state to an inactive state.
//        // This may occur due to temporary interruptions (ex. an incoming phone call).
//    }
//
//    func sceneDidEnterBackground(_ scene: UIScene) {
//        if let uid = Auth.auth().currentUser?.uid {
//            ChatService.shared.setOnline(false, userId: uid)
//        }
//    }
//    func sceneWillEnterForeground(_ scene: UIScene) {
//        if let uid = Auth.auth().currentUser?.uid {
//            ChatService.shared.setOnline(true, userId: uid)
//        }
//    }
//
//
//}
//

//
//  SceneDelegate.swift
//  HealSync
//
//  Created by Arfa on 08/01/2026.
//

import UIKit
import GoogleSignIn
import FirebaseAuth
import FirebaseFirestore

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        // inside scene(_ scene:willConnectTo:options:)
        
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        
        self.window = window
        window.makeKeyAndVisible()
        checkAuthAndRoute(window: window)
        
//        let firstVC = TherapistOnboardingSchedulingVC()
//        let navController = UINavigationController(rootViewController: firstVC)
//        window.rootViewController = navController
    }
    
    private func checkAuthAndRoute(window: UIWindow) {
        if let user = Auth.auth().currentUser {
            let db = Firestore.firestore()
            db.collection("users").document(user.uid).getDocument { document, error in
                guard let data = document?.data() else {
                    // Firestore doc missing entirely — send back to start
                    DispatchQueue.main.async {
                        window.rootViewController = UINavigationController(rootViewController: GetStartedVC())
                    }
                    return
                }

                let role = data["role"] as? String ?? ""
                let isComplete = data["isOnboardingComplete"] as? Bool ?? false

                DispatchQueue.main.async {
                    if isComplete {
                        if role == "patient" {
                            ListenerManager.shared.startListening()
                            window.rootViewController = UINavigationController(rootViewController: ClientMainTabBarController())
                        } else {
                            ListenerManager.shared.startListening()
                            window.rootViewController = UINavigationController(rootViewController: TherapistMainTabBarController())
                        }
                    } else if !role.isEmpty {
                        // Auth exists, role chosen, but onboarding incomplete
                        if role == "patient" {
                            window.rootViewController = UINavigationController(rootViewController: ClientWelcomeVC())
                        } else {
                            window.rootViewController = UINavigationController(rootViewController: TherapistWelcomeVC())
                        }
                    } else {
                        // Auth exists but no role — send to choose role
                        window.rootViewController = UINavigationController(rootViewController: ChooseRoleVC())
                    }
                }
            }
        } else {
            // Not logged in at all
            window.rootViewController = UINavigationController(rootViewController: GetStartedVC())
        }
    }
    func scene(_ scene: UIScene,
               openURLContexts URLContexts: Set<UIOpenURLContext>) {
        
        guard let url = URLContexts.first?.url else { return }
        
        GIDSignIn.sharedInstance.handle(url)
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        if let uid = Auth.auth().currentUser?.uid {
            ChatService.shared.setOnline(false, userId: uid)
        }
    }
    func sceneWillEnterForeground(_ scene: UIScene) {
        if let uid = Auth.auth().currentUser?.uid {
            ChatService.shared.setOnline(true, userId: uid)
        }
    }


}
