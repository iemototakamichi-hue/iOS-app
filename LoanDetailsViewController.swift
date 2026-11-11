import UIKit

class LoanDetailsViewController: UIViewController {
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var statusLabel: UILabel!
    @IBOutlet private weak var borrowerLabel: UILabel!
    @IBOutlet private weak var dateLentLabel: UILabel!
    @IBOutlet private weak var dueDateLabel: UILabel!
    @IBOutlet private weak var notesLabel: UILabel!
    @IBOutlet private weak var returnedDateSection: UIStackView!
    @IBOutlet private weak var returnedDateLabel: UILabel!
    @IBOutlet private weak var reminderSection: UIStackView!
    @IBOutlet private weak var reminderLabel: UILabel!
    @IBOutlet private weak var returnButton: UIButton!

    var loanID: UUID?
    private let manager = LoanManager.shared
    private let dateFormatter = DateFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        dateFormatter.dateStyle = .medium
        returnButton.configuration?.image = UIImage(systemName: "arrow.uturn.backward")
        returnButton.configuration?.imagePadding = 8
        NotificationCenter.default.addObserver(
            self, selector: #selector(timeChanged(_:)), name: UIApplication.significantTimeChangeNotification, object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showLoan()
    }

    @objc private func timeChanged(_ notification: Notification) {
        showLoan()
    }

    private func showLoan() {
        guard let id = loanID, let loan = manager.loan(withID: id) else { return }
        let status = loan.status
        nameLabel.text = loan.displayName
        statusLabel.text = status
        if status == "Overdue" {
            statusLabel.textColor = .systemRed
        } else if loan.isReturned {
            statusLabel.textColor = .secondaryLabel
        } else {
            statusLabel.textColor = view.tintColor
        }

        borrowerLabel.text = loan.borrowerName
        dateLentLabel.text = dateFormatter.string(from: loan.dateLent)
        dueDateLabel.text = dateFormatter.string(from: loan.dueDate)
        notesLabel.text = loan.notes.isEmpty ? "No notes" : loan.notes

        returnedDateSection.isHidden = !loan.isReturned
        if let returnedDate = loan.returnedDate {
            returnedDateLabel.text = dateFormatter.string(from: returnedDate)
        } else {
            returnedDateLabel.text = "Unavailable"
        }

        reminderSection.isHidden = true
        if let reminderDate = loan.reminderDate, !loan.isReturned {
            dateFormatter.timeStyle = .short
            reminderLabel.text = dateFormatter.string(from: reminderDate)
            dateFormatter.timeStyle = .none
            reminderSection.isHidden = false
        }
        returnButton.isHidden = loan.isReturned
    }

    @IBAction private func returnTapped(_ sender: UIButton) {
        guard let id = loanID, let loan = manager.loan(withID: id), !loan.isReturned else { return }
        let alert = UIAlertController(
            title: "Mark as Returned",
            message: "Has \(loan.borrowerName) returned \(loan.displayName)?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Confirm Return", style: .default) { [weak self] _ in
            self?.confirmReturn(id: id)
        })
        present(alert, animated: true)
    }

    private func confirmReturn(id: UUID) {
        if !manager.markAsReturned(id: id) {
            showError("The return could not be saved.")
            return
        }
        NotificationManager.cancelReminder(for: id)
        if let list = navigationController?.viewControllers.first as? LoanListViewController {
            list.showLoans(returned: true)
        }
        navigationController?.popViewController(animated: true)
    }

    @IBAction private func deleteTapped(_ sender: UIButton) {
        guard let id = loanID, let loan = manager.loan(withID: id) else { return }
        let alert = UIAlertController(
            title: "Delete Loan?",
            message: "The record for \(loan.displayName) will be removed.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.confirmDelete(id: id)
        })
        present(alert, animated: true)
    }

    private func confirmDelete(id: UUID) {
        if !manager.deleteLoan(id: id) {
            showError("The loan could not be deleted.")
            return
        }
        NotificationManager.cancelReminder(for: id)
        navigationController?.popViewController(animated: true)
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Could Not Update Loan", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EditLoan", let form = segue.destination as? LoanFormViewController {
            form.loanID = loanID
        }
    }
}
