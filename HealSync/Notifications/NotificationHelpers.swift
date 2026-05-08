//
//  NotificationType.swift
//  HealSync
//
//  Created by Arfa on 06/03/2026.
//


import Foundation
import FirebaseCore
import FirebaseAuth
import UserNotifications
import FirebaseFirestore

enum NotificationType: String {
    case booked
    case cancelled
    case cancelledByTherapist   // therapist cancelled → patient gets refund notice
    case rescheduled            // patient rescheduled → therapist gets notified
    case reminder
}

class NotificationManager {
    static let shared = NotificationManager()

    func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}

func notifyUser(userId: String, session: [String: Any], type: NotificationType) {
    let sessionId     = session["bookingId"]     as? String ?? UUID().uuidString
    let therapistName = session["therapistName"] as? String ?? "your therapist"

    guard let sessionTimestamp = session["sessionDateTime"] as? Timestamp else {
        print("sessionDateTime missing")
        return
    }

    let sessionDate   = sessionTimestamp.dateValue()
    let formatter     = DateFormatter()
    formatter.dateFormat = "dd MMM yyyy, h:mm a"
    formatter.timeZone   = .current
    let formattedTime = formatter.string(from: sessionDate)

    switch type {

    case .booked:
        let title      = "Session Confirmed"
        let body       = "Your session with Dr. \(therapistName) on \(formattedTime) is confirmed."
        let identifier = "\(userId)_\(sessionId)_booked"
        NotificationService.shared.createNotification(
            forUser: userId, title: title, message: body,
            type: type.rawValue, identifier: identifier
        )
        scheduleLocalNotification(identifier: identifier, title: title, body: body, seconds: 1)

        // Schedule patient reminder 60 min before
        let secondsUntilReminder = sessionDate.addingTimeInterval(-3600).timeIntervalSinceNow
        if secondsUntilReminder > 0 {
            scheduleLocalNotification(
                identifier: "\(userId)_\(sessionId)_reminder_60",
                title: "Session Reminder",
                body: "Reminder: Your session with Dr. \(therapistName) starts in 60 minutes.",
                seconds: secondsUntilReminder
            )
        }

    case .cancelled:
        let title      = "Session Cancelled"
        let body       = "Your session with Dr. \(therapistName) scheduled for \(formattedTime) has been cancelled."
        let identifier = "\(userId)_\(sessionId)_cancelled"
        NotificationService.shared.createNotification(
            forUser: userId, title: title, message: body,
            type: type.rawValue, identifier: identifier
        )
        scheduleLocalNotification(identifier: identifier, title: title, body: body, seconds: 1)
        NotificationManager.shared.cancelNotification(identifier: "\(userId)_\(sessionId)_reminder_60")

    case .cancelledByTherapist:
        let title      = "Session Cancelled by Therapist"
        let body       = "Your session with Dr. \(therapistName) on \(formattedTime) was cancelled by the therapist. A full refund has been initiated."
        let identifier = "\(userId)_\(sessionId)_cancelled_by_therapist"
        // Save to Firestore only — do NOT schedule a local notification here
        // because this is called from the therapist's device. The patient will
        // see this in their notification feed when they open the app.
        NotificationService.shared.createNotification(
            forUser: userId, title: title, message: body,
            type: type.rawValue, identifier: identifier
        )
        NotificationManager.shared.cancelNotification(identifier: "\(userId)_\(sessionId)_reminder_60")

    case .rescheduled:
        let title      = "Session Rescheduled"
        let body       = "Your session with Dr. \(therapistName) has been rescheduled to \(formattedTime)."
        let identifier = "\(userId)_\(sessionId)_rescheduled"
        NotificationService.shared.createNotification(
            forUser: userId, title: title, message: body,
            type: type.rawValue, identifier: identifier
        )
        scheduleLocalNotification(identifier: identifier, title: title, body: body, seconds: 1)

    case .reminder:
        let secondsUntilTrigger = sessionDate.addingTimeInterval(-3600).timeIntervalSinceNow
        guard secondsUntilTrigger > 0 else { return }
        scheduleLocalNotification(
            identifier: "\(userId)_\(sessionId)_reminder_60",
            title: "Session Reminder",
            body: "Reminder: Your session with Dr. \(therapistName) starts in 60 minutes.",
            seconds: secondsUntilTrigger
        )
    }
}


func notifyTherapist(therapistId: String, session: [String: Any], type: NotificationType) {
    let sessionId   = session["bookingId"]   as? String ?? UUID().uuidString
    let patientName = session["patientName"] as? String ?? "A patient"

    guard let sessionTimestamp = session["sessionDateTime"] as? Timestamp else {
        print("sessionDateTime missing")
        return
    }

    let sessionDate   = sessionTimestamp.dateValue()
    let formatter     = DateFormatter()
    formatter.dateFormat = "dd MMM yyyy, h:mm a"
    formatter.timeZone   = .current
    let formattedTime = formatter.string(from: sessionDate)

    switch type {

    case .booked:
        let title      = "New Booking"
        let body       = "\(patientName) has booked a session on \(formattedTime)."
        let identifier = "\(therapistId)_\(sessionId)_therapist_booked"
        
        scheduleLocalNotification(identifier: identifier, title: title, body: body, seconds: 1)

        // Schedule therapist reminder 60 min before
        let secondsUntilReminder = sessionDate.addingTimeInterval(-3600).timeIntervalSinceNow
        if secondsUntilReminder > 0 {
            scheduleLocalNotification(
                identifier: "\(therapistId)_\(sessionId)_therapist_reminder_60",
                title: "Session Reminder",
                body: "You have a session with \(patientName) in 60 minutes.",
                seconds: secondsUntilReminder
            )
        }

    case .cancelled:
        let title      = "Session Cancelled"
        let body       = "\(patientName) has cancelled their session scheduled for \(formattedTime)."
        let identifier = "\(therapistId)_\(sessionId)_therapist_cancelled"

        scheduleLocalNotification(identifier: identifier, title: title, body: body, seconds: 1)
        NotificationManager.shared.cancelNotification(identifier: "\(therapistId)_\(sessionId)_therapist_reminder_60")

    case .cancelledByTherapist:
        break  // therapist is the actor, no self-notification needed

    case .rescheduled:
        let title      = "Session Rescheduled"
        let body       = "\(patientName) has rescheduled their session to \(formattedTime)."
        let identifier = "\(therapistId)_\(sessionId)_therapist_rescheduled"
        scheduleLocalNotification(identifier: identifier, title: title, body: body, seconds: 1)

    case .reminder:
        let secondsUntilTrigger = sessionDate.addingTimeInterval(-3600).timeIntervalSinceNow
        guard secondsUntilTrigger > 0 else { return }
        scheduleLocalNotification(
            identifier: "\(therapistId)_\(sessionId)_therapist_reminder_60",
            title: "Session Reminder",
            body: "You have a session with \(patientName) in 60 minutes.",
            seconds: secondsUntilTrigger
        )
    }
}

func saveTherapistNotification(therapistId: String, session: [String: Any], type: NotificationType) {
    let sessionId   = session["bookingId"]   as? String ?? UUID().uuidString
    let patientName = session["patientName"] as? String ?? "A patient"

    guard let sessionTimestamp = session["sessionDateTime"] as? Timestamp else { return }

    let sessionDate   = sessionTimestamp.dateValue()
    let formatter     = DateFormatter()
    formatter.dateFormat = "dd MMM yyyy, h:mm a"
    formatter.timeZone   = .current
    let formattedTime = formatter.string(from: sessionDate)

    let title: String
    let body: String
    let identifier: String

    switch type {
    case .booked:
        title      = "New Booking"
        body       = "\(patientName) has booked a session on \(formattedTime)."
        identifier = "\(therapistId)_\(sessionId)_therapist_booked"
    case .cancelled:
        title      = "Session Cancelled"
        body       = "\(patientName) has cancelled their session scheduled for \(formattedTime)."
        identifier = "\(therapistId)_\(sessionId)_therapist_cancelled"
    case .cancelledByTherapist:
        return // therapist is the actor, no need to notify themselves
    case .rescheduled:
        title      = "Session Rescheduled"
        body       = "\(patientName) has rescheduled their session to \(formattedTime)."
        identifier = "\(therapistId)_\(sessionId)_therapist_rescheduled"
    case .reminder:
        return // reminders are scheduled on the therapist's device, not from patient side
    }

    NotificationService.shared.createNotification(
        forUser: therapistId, title: title, message: body,
        type: type.rawValue, identifier: identifier
    )
}

func scheduleLocalNotification(identifier: String, title: String, body: String, seconds: TimeInterval) {
    let content   = UNMutableNotificationContent()
    content.title = title
    content.body  = body
    content.sound = .default
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(seconds, 1), repeats: false)
    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    UNUserNotificationCenter.current().add(request) { error in
        if let error = error { print("Notification error:", error.localizedDescription) }
        else { print("Notification scheduled:", identifier) }
    }
}
