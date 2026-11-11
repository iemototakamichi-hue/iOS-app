import UIKit

class LoanFormViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var scrollBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var typeControl: UISegmentedControl!
    @IBOutlet private weak var itemSection: UIStackView!
    @IBOutlet private weak var itemField: UITextField!
    @IBOutlet private weak var amountSection: UIStackView!
    @IBOutlet private weak var amountField: UITextField!
    @IBOutlet private weak var borrowerField: UITextField!
    @IBOutlet private weak var dateLentPicker: UIDatePicker!
    @IBOutlet private weak var dueDatePicker: UIDatePicker!
    @IBOutlet private weak var notesView: UITextView!
    @IBOutlet private weak var reminderSection: UIStackView!
    @IBOutlet private weak var reminderSwitch: UISwitch!
    @IBOutlet private weak var reminderPicker: UIDatePicker!
    @IBOutlet private weak var saveButton: UIButton!

    var loanID: UUID?
    private let manager = LoanManager.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        title = loanID == nil ? "Create New Loan" : "Edit Loan"
        notesView.layer.cornerRadius = 10
        dateLentPicker.preferredDatePickerStyle = .compact
        dueDatePicker.preferredDatePickerStyle = .compact
        reminderPicker.preferredDatePickerStyle = .compact
        dateLentPicker.setContentHuggingPriority(.required, for: .horizontal)
        dueDatePicker.setContentHuggingPriority(.required, for: .horizontal)

        // Keep the form scrollable above the keyboard on smaller screens.
        scrollBottomConstraint.isActive = false
        scrollView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor).isActive = true

        let today = Date()
        dateLentPicker.date = today
        dueDatePicker.date = Calendar.current.date(byAdding: .day, value: 7, to: today) ?? today
        reminderPicker.minimumDate = today
        reminderPicker.date = today.addingTimeInterval(3600)

        if let id = loanID, let loan = manager.loan(withID: id) {
            fillForm(with: loan)
        }
        updateTypeFields()
        reminderPicker.isHidden = !reminderSwitch.isOn
    }

    private func fillForm(with loan: Loan) {
        typeControl.selectedSegmentIndex = loan.loanType == "Money" ? 0 : 1
        itemField.text = loan.itemName
        if let amount = loan.amount {
            amountField.text = Loan.formatAmount(amount, locale: .current)
        }
        borrowerField.text = loan.borrowerName
        dateLentPicker.date = loan.dateLent
        dueDatePicker.date = loan.dueDate
        notesView.text = loan.notes
        reminderSection.isHidden = loan.isReturned
        if let reminderDate = loan.reminderDate, reminderDate > Date(), !loan.isReturned {
            reminderSwitch.isOn = true
            reminderPicker.date = reminderDate
        }
    }

    @IBAction private func typeChanged(_ sender: UISegmentedControl) {
        view.endEditing(true)
        updateTypeFields()
    }

    private func updateTypeFields() {
        let isMoney = typeControl.selectedSegmentIndex == 0
        itemSection.isHidden = isMoney
        amountSection.isHidden = !isMoney
    }

    @IBAction private func reminderChanged(_ sender: UISwitch) {
        view.endEditing(true)
        reminderPicker.isHidden = !sender.isOn
        if sender.isOn {
            reminderPicker.minimumDate = Date()
            if reminderPicker.date <= Date() {
                reminderPicker.date = Date().addingTimeInterval(3600)
            }
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == itemField {
            borrowerField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }

    @IBAction private func saveTapped(_ sender: UIButton) {
        view.endEditing(true)
        let borrower = (borrowerField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if borrower.isEmpty {
            showMessage("Enter the borrower's name.")
            return
        }

        let isMoney = typeControl.selectedSegmentIndex == 0
        var itemName = ""
        var amount: Double?
        if isMoney {
            let amountText = (amountField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            amount = Loan.moneyAmount(from: amountText)
            if amount == nil {
                showMessage("Enter an amount greater than zero with up to two decimal places.")
                return
            }
        } else {
            itemName = (itemField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if itemName.isEmpty {
                showMessage("Enter the name of the item you lent.")
                return
            }
        }

        let dateLent = dateLentPicker.date
        let dueDate = dueDatePicker.date
        if Calendar.current.compare(dueDate, to: dateLent, toGranularity: .day) == .orderedAscending {
            showMessage("Choose a due date on or after the date lent.")
            return
        }

        saveLoan(itemName: itemName, amount: amount, borrower: borrower, dateLent: dateLent, dueDate: dueDate)
    }

    private func saveLoan(itemName: String, amount: Double?, borrower: String, dateLent: Date, dueDate: Date) {
        let notes = (notesView.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        var previousLoan: Loan?
        if let id = loanID {
            guard let existing = manager.loan(withID: id) else {
                showMessage("This loan is no longer available.")
                return
            }
            previousLoan = existing
        }
        let isReturned = previousLoan?.isReturned ?? false
        let reminderDate = reminderSwitch.isOn && !isReturned ? reminderPicker.date : nil
        let loan = Loan(
            id: previousLoan?.id ?? UUID(), loanType: amount == nil ? "Item" : "Money",
            itemName: itemName, amount: amount, borrowerName: borrower,
            dateLent: dateLent, dueDate: dueDate, notes: notes, isReturned: isReturned,
            returnedDate: previousLoan?.returnedDate, reminderDate: reminderDate
        )

        let didSave = previousLoan == nil ? manager.addLoan(loan) : manager.updateLoan(loan)
        if !didSave {
            showMessage("The loan could not be saved. Please try again.")
            return
        }
        saveButton.isEnabled = false

        // Save first so a notification problem never prevents saving a loan.
        if reminderDate == nil {
            NotificationManager.cancelReminder(for: loan.id)
            finishSaving()
            return
        }

        navigationItem.hidesBackButton = true
        NotificationManager.scheduleReminder(for: loan) { [weak self] scheduled in
            guard let self = self else { return }
            if scheduled {
                self.finishSaving()
            } else {
                self.finishWithoutReminder(loan)
            }
        }
    }

    private func finishWithoutReminder(_ loan: Loan) {
        if var savedLoan = manager.loan(withID: loan.id), savedLoan.reminderDate == loan.reminderDate {
            savedLoan.reminderDate = nil
            if manager.updateLoan(savedLoan) {
                NotificationManager.cancelReminder(for: savedLoan.id)
            }
        }
        guard navigationController?.topViewController === self else { return }
        let alert = UIAlertController(
            title: "Loan Saved",
            message: "The reminder couldn't be scheduled. Check notification permissions and choose a future time if you edit the loan.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.finishSaving()
        })
        present(alert, animated: true)
    }

    private func finishSaving() {
        guard let navigation = navigationController, navigation.topViewController === self else { return }
        if loanID == nil, let list = navigation.viewControllers.first as? LoanListViewController {
            list.showLoans(returned: false)
        }
        navigation.popViewController(animated: true)
    }

    private func showMessage(_ message: String) {
        let alert = UIAlertController(title: "Check Loan", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
