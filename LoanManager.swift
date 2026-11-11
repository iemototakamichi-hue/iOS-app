import Foundation

class LoanManager {
    static let shared = LoanManager()

    private let defaults = UserDefaults.standard
    private let loansKey = "borrowBackLoans"
    private(set) var loans: [Loan] = []

    private init() {
        loadLoans()
    }

    private func loadLoans() {
        guard let data = defaults.data(forKey: loansKey) else { return }
        do {
            loans = try JSONDecoder().decode([Loan].self, from: data)
        } catch {
            print("Could not load loans: \(error)")
        }
    }

    // Encode the new array before replacing the saved and in-memory copies.
    private func saveLoans(_ updatedLoans: [Loan]) -> Bool {
        do {
            let data = try JSONEncoder().encode(updatedLoans)
            defaults.set(data, forKey: loansKey)
            loans = updatedLoans
            return true
        } catch {
            print("Could not save loans: \(error)")
            return false
        }
    }

    func loan(withID id: UUID) -> Loan? {
        for loan in loans {
            if loan.id == id {
                return loan
            }
        }
        return nil
    }

    func addLoan(_ loan: Loan) -> Bool {
        var updatedLoans = loans
        updatedLoans.insert(loan, at: 0)
        return saveLoans(updatedLoans)
    }

    func updateLoan(_ loan: Loan) -> Bool {
        var updatedLoans = loans
        for index in updatedLoans.indices {
            if updatedLoans[index].id == loan.id {
                updatedLoans[index] = loan
                return saveLoans(updatedLoans)
            }
        }
        return false
    }

    func deleteLoan(id: UUID) -> Bool {
        var updatedLoans = loans
        for index in updatedLoans.indices {
            if updatedLoans[index].id == id {
                updatedLoans.remove(at: index)
                return saveLoans(updatedLoans)
            }
        }
        return false
    }

    func markAsReturned(id: UUID) -> Bool {
        guard var loan = loan(withID: id), !loan.isReturned else { return false }
        loan.isReturned = true
        loan.returnedDate = Date()
        loan.reminderDate = nil
        return updateLoan(loan)
    }
}
