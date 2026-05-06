//
//  ChatBadgeManager.swift
//  HealSync
//
//  Created by Arfa on 19/03/2026.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

// MARK: - ChatBadgeManager
// Attach this to any tab bar controller to get a live unread chat badge.
// Call startListening(tabBar:chatTabIndex:) once in viewDidLoad.
// Call stopListening() in deinit.

class ChatBadgeManager {

    static let shared = ChatBadgeManager()
    private init() {}

    private var patientListener:   ListenerRegistration?
    private var therapistListener: ListenerRegistration?
    private weak var tabBar: UITabBar?
    private var chatTabIndex: Int = 3

    // MARK: - Start
    func startListening(tabBar: UITabBar, chatTabIndex: Int = 3) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        self.tabBar       = tabBar
        self.chatTabIndex = chatTabIndex

        stopListening()

        let db = Firestore.firestore()
        var patientTotal:   Int = 0
        var therapistTotal: Int = 0

        // Listen to chats where user is patient
        patientListener = db.collection("chats")
            .whereField("patientId", isEqualTo: uid)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self = self else { return }
                patientTotal = self.totalUnread(from: snapshot, userId: uid)
                self.updateBadge(patientTotal + therapistTotal)
            }

        // Listen to chats where user is therapist
        therapistListener = db.collection("chats")
            .whereField("therapistId", isEqualTo: uid)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self = self else { return }
                therapistTotal = self.totalUnread(from: snapshot, userId: uid)
                self.updateBadge(patientTotal + therapistTotal)
            }
    }

    // MARK: - Stop
    func stopListening() {
        patientListener?.remove()
        therapistListener?.remove()
        patientListener   = nil
        therapistListener = nil
    }

    // MARK: - Helpers
    private func totalUnread(from snapshot: QuerySnapshot?, userId: String) -> Int {
        snapshot?.documents.reduce(0) { total, doc in
            let data       = doc.data()
            let hiddenFor  = data["hiddenFor"]  as? [String] ?? []
            guard !hiddenFor.contains(userId) else { return total }
            let unreadMap  = data["unreadCount"] as? [String: Int] ?? [:]
            return total + (unreadMap[userId] ?? 0)
        } ?? 0
    }

    private func updateBadge(_ count: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let tabBar = self.tabBar,
                  let items  = tabBar.items,
                  self.chatTabIndex < items.count else { return }
            items[self.chatTabIndex].badgeValue = count > 0 ? "\(count)" : nil
        }
    }
}
