//
//  TherapistHomeVC.swift
//  HealSync
//
//  Created by Arfa on 20/02/2026.
//

import UIKit

class TherapistMainTabBarController: UITabBarController {

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
        
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular, scale: .medium)

        // Home
        let homeVC = UINavigationController(rootViewController: TherapistHomeVC())
        homeVC.tabBarItem = UITabBarItem(
            title: "Home",
            image: UIImage(systemName: "house.fill", withConfiguration: iconConfig),
            tag: 0
        )

        // Sessions
        let sessionsVC = UINavigationController(rootViewController: TherapistSessionsVC())
        sessionsVC.tabBarItem = UITabBarItem(
            title: "Sessions",
            image: UIImage(systemName: "calendar", withConfiguration: iconConfig),
            tag: 1
        )

        // Clients
        let clientsVC = UINavigationController(rootViewController: TherapistClientsVC())
        clientsVC.tabBarItem = UITabBarItem(
            title: "Clients",
            image: UIImage(systemName: "person.2.fill", withConfiguration: iconConfig),
            tag: 2
        )

        // Chat
        let chatVC = UINavigationController(rootViewController: ChatListVC())
        chatVC.tabBarItem = UITabBarItem(
            title: "Chat",
            image: UIImage(systemName: "bubble.left.and.bubble.right", withConfiguration: iconConfig),
            tag: 3
        )

        // Me / Profile
        let profileVC = UINavigationController(rootViewController: TherapistProfileTabVC())
        profileVC.tabBarItem = UITabBarItem(
            title: "Me",
            image: UIImage(systemName: "person", withConfiguration: iconConfig),
            tag: 4
        )
        
        tabBar.tintColor = UIColor.systemCyan
        viewControllers = [homeVC, sessionsVC, clientsVC, chatVC, profileVC]
    }

}



