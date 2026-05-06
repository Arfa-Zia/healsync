//
//  NotificationModel.swift
//  HealSync
//
//  Created by Arfa on 06/03/2026.
//

import Foundation
import FirebaseFirestore

struct AppNotification {
    let id: String
    let title: String
    let message: String
    let type: String
    let createdAt: Date
    var isRead: Bool

    init?(document: [String: Any], id: String) {
        guard
            let title = document["title"] as? String,
            let message = document["message"] as? String,
            let type = document["type"] as? String,
            let timestamp = document["createdAt"] as? Timestamp,
            let isRead = document["isRead"] as? Bool
        else { return nil }

        self.id = id
        self.title = title
        self.message = message
        self.type = type
        self.createdAt = timestamp.dateValue()
        self.isRead = isRead
    }
}
