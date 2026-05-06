//
//  NotificationService.swift
//  HealSync
//
//  Created by Arfa on 06/03/2026.
//


import Foundation
import FirebaseFirestore

class NotificationService {
    
    static let shared = NotificationService()
    private let db = Firestore.firestore()
    
    private init() {}

    func createNotification(forUser userId: String,
                            title: String,
                            message: String,
                            type: String,
                            identifier: String) {

        let docRef = db.collection("users")
            .document(userId)
            .collection("notifications")
            .document() // keeps Firestore document unique

        let data: [String: Any] = [
            "title": title,
            "message": message,
            "type": type,
            "identifier": identifier,           
            "createdAt": Timestamp(date: Date()),
            "isRead": false
        ]

        docRef.setData(data) { error in
            if let error = error {
                print("Error creating notification: \(error)")
            } else {
                print("Notification saved for user: \(userId) with identifier \(identifier)")
            }
        }
    }
    
}
