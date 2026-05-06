//
//  MainTabBarController.swift
//  HealSync
//
//  Created by Arfa on 10/02/2026.
//

import UIKit

class ClientMainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        ChatBadgeManager.shared.startListening(tabBar: tabBar, chatTabIndex: 3)
    }
    
    deinit {
        ChatBadgeManager.shared.stopListening()
    }
    
    private func setupTabs() {
        view.backgroundColor = .systemBackground
        
        let iconConfiguration = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular, scale: .medium)
        
        let homeVC = UINavigationController(rootViewController: ClientHomeVC())
        homeVC.tabBarItem = UITabBarItem(
            title: "Home",
            image: UIImage(systemName: "house.fill", withConfiguration: iconConfiguration),
            tag: 0
        )
        
        let sessionsVC = UINavigationController(rootViewController: ClientSessionsVC())
        sessionsVC.tabBarItem = UITabBarItem(
            title: "Sessions",
            image: UIImage(systemName: "calendar", withConfiguration: iconConfiguration),
            tag: 1
        )
        
        let therapistVC = UINavigationController(rootViewController: ClientTherapistVC())
        therapistVC.tabBarItem = UITabBarItem(
            title: "Therapist",
            image: UIImage(systemName: "stethoscope", withConfiguration: iconConfiguration),
            tag: 2
        )
        
        let chatVC = UINavigationController(rootViewController: ChatListVC())
        chatVC.tabBarItem = UITabBarItem(
            title: "Chat",
            image: UIImage(systemName: "bubble.left.and.bubble.right", withConfiguration: iconConfiguration),
            tag: 3
        )
        
        let profileVC = UINavigationController(rootViewController: ClientProfileVC())
        profileVC.tabBarItem = UITabBarItem(
            title: "Me",
            image: UIImage(systemName: "person", withConfiguration: iconConfiguration),
            tag: 4
        )
        
        tabBar.tintColor = UIColor.systemCyan
        viewControllers = [homeVC, sessionsVC, therapistVC, chatVC, profileVC]
    }
    
}
