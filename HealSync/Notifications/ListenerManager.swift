//
//  ListenerManager.swift
//  HealSync
//
//  Created by Arfa on 09/03/2026.
//
//
import UIKit
import FirebaseAuth
import FirebaseFirestore
 
 
class ListenerManager {
    static let shared = ListenerManager()
    private var bookingListener:  ListenerRegistration?
    private var patientListener:  ListenerRegistration?
 
    func startListening() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        stopListening()
 
        Firestore.firestore().collection("users").document(uid).getDocument { [weak self] snapshot, _ in
            guard let role = snapshot?.data()?["role"] as? String else { return }
            if role == "therapist" {
                self?.startTherapistListener(uid: uid)
            } else {
                self?.startPatientListener(uid: uid)
            }
        }
    }
 
    // MARK: - Patient listener
    // Watches the patient's mySessions for changes made by the therapist
    // (e.g. therapist cancels) and fires a local notification on the patient's device.
    private func startPatientListener(uid: String) {
        _ = Timestamp(date: Date())
        // Track which docs we already notified to avoid duplicates
        var notifiedIds = Set<String>()
 
        patientListener = Firestore.firestore()
            .collection("users").document(uid)
            .collection("mySessions")
            .addSnapshotListener { snapshot, _ in
                snapshot?.documentChanges.forEach { change in
                    let data        = change.document.data()
                    let cancelledBy = data["cancelledBy"] as? String ?? ""
                    let status      = data["status"]      as? String ?? ""
                    let docId       = change.document.documentID
 
                    // Handle both .modified (real-time) and .added (app opened after cancel)
                    guard change.type == .modified || change.type == .added else { return }
                    guard status == "cancelled", cancelledBy == "therapist" else { return }
                    guard !notifiedIds.contains(docId) else { return }
 
                    // For .added: only fire if cancelledAt is recent (within last 24hrs)
                    // so we don't banner old cancellations on every app launch
                    if let cancelledAt = data["cancelledAt"] as? Timestamp {
                        let age = Date().timeIntervalSince(cancelledAt.dateValue())
                        // .modified: always fire (it just happened)
                        // .added: only fire if cancelled within the last 10 minutes
                        if change.type == .added && age > 600 { return }
                    } else if change.type == .added {
                        return // no cancelledAt means it was cancelled long ago
                    }
 
                    notifiedIds.insert(docId)
                    let bookingId = data["bookingId"] as? String ?? UUID().uuidString
                    let therapistName = data["therapistName"] as? String ?? "your therapist"
 
                    scheduleLocalNotification(
                        identifier: "\(uid)_\(bookingId)_cancelled_by_therapist_local",
                        title: "Session Cancelled by Therapist",
                        body: "Your session with Dr. \(therapistName) was cancelled. A full refund has been initiated.",
                        seconds: 1
                    )
                }
            }
    }
 
    private func startTherapistListener(uid: String) {
        let listenStartTime = Timestamp(date: Date())
        var notifiedDocIds  = Set<String>()
 
        bookingListener = Firestore.firestore()
            .collection("users").document(uid)
            .collection("bookedSessions")
            .addSnapshotListener { snapshot, _ in
                snapshot?.documentChanges.forEach { change in
                    let data  = change.document.data()
                    let docId = change.document.documentID
 
                    switch change.type {
 
                    case .added:
                        guard let createdAt = data["createdAt"] as? Timestamp,
                              createdAt.seconds >= listenStartTime.seconds else { return }
                        // Skip rescheduled docs — saveTherapistNotification(.rescheduled)
                        // already wrote the Firestore entry from the patient's device.
                        // We just need the banner here.
                        let rescheduleCount = data["rescheduleCount"] as? Int ?? 0
                        let bannerKey = docId + "_booked"
                        guard !notifiedDocIds.contains(bannerKey) else { return }
                        notifiedDocIds.insert(bannerKey)
 
                        if rescheduleCount > 0 {
                            // Rescheduled — fire banner only (Firestore already written)
                            let patientName   = data["patientName"]    as? String ?? "A patient"
                            let therapistName = data["therapistName"]  as? String ?? ""
                            if let ts = data["sessionDateTime"] as? Timestamp {
                                let df = DateFormatter()
                                df.dateFormat = "dd MMM yyyy, h:mm a"
                                df.timeZone   = .current
                                let time = df.string(from: ts.dateValue())
                                scheduleLocalNotification(
                                    identifier: docId + "_reschedule_banner",
                                    title: "Session Rescheduled",
                                    body: "\(patientName) has rescheduled their session to \(time).",
                                    seconds: 1
                                )
                            }
                        } else {
                            // New booking — fire banner (saveTherapistNotification already wrote Firestore)
                            notifyTherapist(therapistId: uid, session: data, type: .booked)
                        }
 
                    case .modified:
                        guard let status    = data["status"]      as? String else { return }
                        let cancelledBy     = data["cancelledBy"] as? String ?? ""
                        let bannerKey       = docId + "_cancelled"
                        guard !notifiedDocIds.contains(bannerKey) else { return }
 
                        if status == "cancelled" && cancelledBy == "patient" {
                            notifiedDocIds.insert(bannerKey)
                            notifyTherapist(therapistId: uid, session: data, type: .cancelled)
                        }
 
                    default:
                        break
                    }
                }
            }
    }
 
    func stopListening() {
        bookingListener?.remove()
        bookingListener = nil
        patientListener?.remove()
        patientListener = nil
    }
}
