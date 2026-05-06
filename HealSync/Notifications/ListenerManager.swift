//
//  ListenerManager.swift
//  HealSync
//
//  Created by Arfa on 09/03/2026.
//
import UIKit
import FirebaseAuth
import FirebaseFirestore


class ListenerManager {
    static let shared = ListenerManager()
    private var bookingListener: ListenerRegistration?

    func startListening() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        stopListening()

        Firestore.firestore().collection("users").document(uid).getDocument { [weak self] snapshot, _ in
            guard let role = snapshot?.data()?["role"] as? String,
                  role == "therapist" else { return }
            self?.startTherapistListener(uid: uid)
        }
    }

    private func startTherapistListener(uid: String) {
        let listenStartTime = Timestamp(date: Date())

        bookingListener = Firestore.firestore()
            .collection("users").document(uid)
            .collection("bookedSessions")
            .addSnapshotListener { snapshot, _ in
                snapshot?.documentChanges.forEach { change in
                    let data = change.document.data()

                    switch change.type {

                    case .added:
                        // New booking arrived — only process docs created after listener started
                        guard let createdAt = data["createdAt"] as? Timestamp,
                              createdAt.seconds >= listenStartTime.seconds else { return }
                        // Fire local banner + schedule reminder on therapist's device
                        notifyTherapist(therapistId: uid, session: data, type: .booked)

                    case .modified:
                        // Status changed to cancelled — fire cancellation banner
                        guard let status = data["status"] as? String,
                              status == "cancelled" else { return }
                        notifyTherapist(therapistId: uid, session: data, type: .cancelled)

                    default:
                        break
                    }
                }
            }
    }

    func stopListening() {
        bookingListener?.remove()
        bookingListener = nil
    }
}
