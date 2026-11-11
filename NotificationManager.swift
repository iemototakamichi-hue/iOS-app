import Foundation
import UserNotifications

class NotificationManager {
    static func scheduleReminder(for loan: Loan, completion: @escaping (Bool) -> Void) {
        guard let reminderDate = loan.reminderDate, reminderDate > Date() else {
            completion(false)
            return
        }

        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                // The loan might have changed while the permission prompt was open.
                guard let currentLoan = LoanManager.shared.loan(withID: loan.id),
                      !currentLoan.isReturned, currentLoan.reminderDate == reminderDate else {
                    completion(false)
                    return
                }
                guard granted, reminderDate > Date() else {
                    completion(false)
                    return
                }

                let content = UNMutableNotificationContent()
                content.title = "Loan return reminder"
                content.body = "Follow up with \(currentLoan.borrowerName) about \(currentLoan.displayName)."
                content.sound = .default

                let dateParts = Calendar.current.dateComponents(
                    [.calendar, .timeZone, .year, .month, .day, .hour, .minute, .second],
                    from: reminderDate
                )
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateParts, repeats: false)
                if trigger.nextTriggerDate() == nil {
                    completion(false)
                    return
                }
                let request = UNNotificationRequest(
                    identifier: loan.id.uuidString, content: content, trigger: trigger
                )
                center.add(request) { error in
                    DispatchQueue.main.async {
                        completion(error == nil)
                    }
                }
            }
        }
    }

    static func cancelReminder(for id: UUID) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [id.uuidString])
        center.removeDeliveredNotifications(withIdentifiers: [id.uuidString])
    }
}
