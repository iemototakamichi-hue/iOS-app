import Foundation

struct Loan: Codable {
    var id: UUID
    var loanType: String
    var itemName: String
    var amount: Double?
    var borrowerName: String
    var dateLent: Date
    var dueDate: Date
    var notes: String
    var isReturned: Bool
    var returnedDate: Date?
    var reminderDate: Date?

    var displayName: String {
        if loanType == "Money", let amount = amount {
            return "RM\(Loan.formatAmount(amount))"
        }
        return itemName
    }

    var status: String {
        if isReturned {
            return "Returned"
        }
        // The whole due day is available for returning the loan.
        if Calendar.current.compare(Date(), to: dueDate, toGranularity: .day) == .orderedDescending {
            return "Overdue"
        }
        return "On Loan"
    }

    static func formatAmount(_ amount: Double, locale: Locale = Locale(identifier: "en_MY")) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = amount.rounded(.towardZero) == amount ? 0 : 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? String(amount)
    }

    static func moneyAmount(from text: String, locale: Locale = .current) -> Double? {
        // Accept the decimal separator shown by the user's keyboard.
        let separator = locale.decimalSeparator ?? "."
        var normalized = ""
        for character in text.replacingOccurrences(of: separator, with: ".") {
            if character == "." {
                normalized.append(character)
            } else if let digit = character.wholeNumberValue, digit >= 0, digit <= 9 {
                normalized += String(digit)
            } else {
                return nil
            }
        }
        let parts = normalized.split(separator: ".", omittingEmptySubsequences: false)
        if parts.count > 2 || (parts.count == 2 && parts[1].count > 2) {
            return nil
        }
        if let amount = Double(normalized), amount.isFinite, amount > 0 {
            return amount
        }
        return nil
    }
}
