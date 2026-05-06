//
//  Chat.swift
//  HealSync
//
//  Created by Arfa on 18/03/2026.
//
import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - Message Model
struct ChatMessage {
    let messageId:   String
    let senderId:    String
    let senderName:  String
    let text:        String
    let timestamp:   Date
    var isRead:      Bool

    var isFromCurrentUser: Bool {
        senderId == Auth.auth().currentUser?.uid
    }

    init?(id: String, data: [String: Any]) {
        guard let senderId   = data["senderId"]   as? String,
              let senderName = data["senderName"] as? String,
              let text       = data["text"]       as? String,
              let ts         = data["timestamp"]  as? Timestamp else { return nil }
        self.messageId  = id
        self.senderId   = senderId
        self.senderName = senderName
        self.text       = text
        self.timestamp  = ts.dateValue()
        self.isRead     = data["isRead"] as? Bool ?? false
    }
}

// MARK: - Chat Service
class ChatService {
    static let shared = ChatService()
    private let db = Firestore.firestore()

    // MARK: - Create or get a general chat between patient and therapist
    func getOrCreateGeneralChat(
        patientId: String, patientName: String,
        therapistId: String, therapistName: String,
        completion: @escaping (String) -> Void   // returns chatId
    ) {
        // Deterministic chatId — always the same for the same pair
        let chatId = "\(patientId)_\(therapistId)"
        let ref    = db.collection("chats").document(chatId)

        ref.getDocument { snapshot, _ in
            if snapshot?.exists == true {
                completion(chatId)
                return
            }
            // Create it
            let data: [String: Any] = [
                "type":            Chat.ChatType.general.rawValue,
                "patientId":       patientId,
                "therapistId":     therapistId,
                "patientName":     patientName,
                "therapistName":   therapistName,
                "lastMessage":     "",
                "lastMessageTime": Timestamp(),
                "unreadCount":     [patientId: 0, therapistId: 0],
                "hiddenFor":       [String](),
                "deletedAt":       [String: Any](),
                "createdAt":       Timestamp()
            ]
            ref.setData(data) { _ in completion(chatId) }
        }
    }

    // MARK: - Create or get a session chat tied to a booking
    func getOrCreateSessionChat(
        bookingId: String,
        patientId: String, patientName: String,
        therapistId: String, therapistName: String,
        completion: @escaping (String) -> Void
    ) {
        let chatId = "session_\(bookingId)"
        let ref    = db.collection("chats").document(chatId)

        ref.getDocument { snapshot, _ in
            if snapshot?.exists == true {
                completion(chatId)
                return
            }
            let data: [String: Any] = [
                "type":            Chat.ChatType.session.rawValue,
                "patientId":       patientId,
                "therapistId":     therapistId,
                "patientName":     patientName,
                "therapistName":   therapistName,
                "bookingId":       bookingId,
                "lastMessage":     "",
                "lastMessageTime": Timestamp(),
                "unreadCount":     [patientId: 0, therapistId: 0],
                "hiddenFor":       [String](),
                "deletedAt":       [String: Any](),
                "createdAt":       Timestamp()
            ]
            ref.setData(data) { _ in completion(chatId) }
        }
    }

    // MARK: - Send a message
    func sendMessage(
        chatId: String,
        senderId: String, senderName: String,
        text: String,
        otherUserId: String
    ) {
        let chatRef    = db.collection("chats").document(chatId)
        let messageRef = chatRef.collection("messages").document()

        let messageData: [String: Any] = [
            "senderId":   senderId,
            "senderName": senderName,
            "text":       text,
            "timestamp":  Timestamp(),
            "isRead":     false
        ]

        let batch = db.batch()
        batch.setData(messageData, forDocument: messageRef)

        // Update chat metadata + unhide for both users when a new message is sent
        batch.updateData([
            "lastMessage":     text,
            "lastMessageTime": Timestamp(),
            "unreadCount.\(otherUserId)": FieldValue.increment(Int64(1)),
            // Re-show chat for both participants when new message arrives
            "hiddenFor": FieldValue.arrayRemove([senderId, otherUserId])
        ], forDocument: chatRef)

        batch.commit { error in
            if let error = error { print("❌ Send message error: \(error)") }
        }
    }

    // MARK: - Listen to messages in a chat
    func listenToMessages(chatId: String,
                          currentUserId: String,
                          completion: @escaping ([ChatMessage]) -> Void) -> ListenerRegistration {
        return db.collection("chats").document(chatId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self = self else { return }
                // Check if user deleted this chat — only show messages after deletedAt
                self.db.collection("chats").document(chatId).getDocument { snap, _ in
                    let deletedAtRaw = snap?.data()?["deletedAt"] as? [String: Timestamp] ?? [:]
                    let cutoff = deletedAtRaw[currentUserId]?.dateValue()

                    let messages = snapshot?.documents.compactMap {
                        ChatMessage(id: $0.documentID, data: $0.data())
                    }.filter { msg in
                        guard let cutoff = cutoff else { return true }
                        return msg.timestamp > cutoff
                    } ?? []
                    completion(messages)
                }
            }
    }

    // MARK: - Listen to all chats for a user
    func listenToChats(userId: String,
                       completion: @escaping ([Chat]) -> Void) -> ListenerRegistration {
        return db.collection("chats")
            .whereField("participantIds", arrayContains: userId)
            .order(by: "lastMessageTime", descending: true)
            .addSnapshotListener { snapshot, _ in
                let chats = snapshot?.documents.compactMap {
                    Chat(id: $0.documentID, data: $0.data())
                } ?? []
                completion(chats)
            }
    }

    // MARK: - Mark messages as read
    func markMessagesRead(chatId: String, userId: String) {
        let chatRef = db.collection("chats").document(chatId)

        // Reset unread count for this user
        chatRef.updateData(["unreadCount.\(userId)": 0])

        // Fetch all unread messages and mark those NOT sent by current user as read
        // Avoids compound index requirement by filtering in-memory
        chatRef.collection("messages")
            .whereField("isRead", isEqualTo: false)
            .getDocuments { snapshot, _ in
                let batch = self.db.batch()
                snapshot?.documents
                    .filter { ($0.data()["senderId"] as? String) != userId }
                    .forEach { batch.updateData(["isRead": true], forDocument: $0.reference) }
                batch.commit()
            }
    }

    // MARK: - Update typing indicator
    func setTyping(_ isTyping: Bool, chatId: String, userId: String) {
        db.collection("chats").document(chatId)
            .updateData(["typing.\(userId)": isTyping])
    }

    // MARK: - Update online status
    func setOnline(_ isOnline: Bool, userId: String) {
        db.collection("users").document(userId)
            .updateData([
                "isOnline":   isOnline,
                "lastSeen":   Timestamp()
            ])
    }

    // MARK: - Listen to online status of another user
    func listenToOnlineStatus(userId: String,
                               completion: @escaping (Bool, Date?) -> Void) -> ListenerRegistration {
        return db.collection("users").document(userId)
            .addSnapshotListener { snapshot, _ in
                let isOnline  = snapshot?.data()?["isOnline"]  as? Bool ?? false
                let lastSeen  = (snapshot?.data()?["lastSeen"] as? Timestamp)?.dateValue()
                completion(isOnline, lastSeen)
            }
    }
}
