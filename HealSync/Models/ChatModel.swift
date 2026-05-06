//
//  ChatModel.swift
//  HealSync
//
//  Created by Arfa on 18/03/2026.
//
import Foundation
import FirebaseFirestore
import FirebaseAuth


// MARK: - Chat Model
struct Chat {
    let chatId:        String
    let type:          ChatType
    let patientId:     String
    let therapistId:   String
    let patientName:   String
    let therapistName: String
    let lastMessage:   String
    let lastMessageTime: Date?
    let unreadCount:   [String: Int]   // [userId: count]
    let bookingId:     String?         // only for session chats
    let createdAt:     Date
    let hiddenFor:     [String]         // userIds who "deleted" this chat
    let deletedAt:     [String: Date]   // userId -> timestamp when they deleted

    enum ChatType: String {
        case general = "general"
        case session = "session"
    }

    // The OTHER participant's name from the perspective of currentUser
    func otherName(currentUserId: String) -> String {
        currentUserId == patientId ? therapistName : patientName
    }

    func unread(for userId: String) -> Int {
        unreadCount[userId] ?? 0
    }

    init?(id: String, data: [String: Any]) {
        guard let patientId    = data["patientId"]    as? String,
              let therapistId  = data["therapistId"]  as? String,
              let patientName  = data["patientName"]  as? String,
              let therapistName = data["therapistName"] as? String,
              let typeRaw      = data["type"]         as? String,
              let type         = ChatType(rawValue: typeRaw) else { return nil }

        self.chatId        = id
        self.type          = type
        self.patientId     = patientId
        self.therapistId   = therapistId
        self.patientName   = patientName
        self.therapistName = therapistName
        self.lastMessage   = data["lastMessage"]  as? String ?? ""
        self.lastMessageTime = (data["lastMessageTime"] as? Timestamp)?.dateValue()
        self.unreadCount   = data["unreadCount"]  as? [String: Int] ?? [:]
        self.bookingId     = data["bookingId"]    as? String
        self.createdAt     = (data["createdAt"]   as? Timestamp)?.dateValue() ?? Date()
        self.hiddenFor     = data["hiddenFor"]    as? [String] ?? []
        let deletedAtRaw   = data["deletedAt"]    as? [String: Timestamp] ?? [:]
        self.deletedAt     = deletedAtRaw.mapValues { $0.dateValue() }
    }
}
