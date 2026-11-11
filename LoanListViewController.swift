import UIKit

class LoanListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var searchBar: UISearchBar!
    @IBOutlet private weak var categoryControl: UISegmentedControl!

    private var visibleLoans: [Loan] = []
    private let dateFormatter = DateFormatter()
    private let emptyLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.rightBarButtonItem?.accessibilityLabel = "Add loan"
        dateFormatter.dateStyle = .medium
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 96

        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.font = .preferredFont(forTextStyle: .body)
        emptyLabel.adjustsFontForContentSizeCategory = true
        emptyLabel.textColor = .secondaryLabel

        // Update overdue labels when the date changes while the app is open.
        NotificationCenter.default.addObserver(
            self, selector: #selector(timeChanged(_:)), name: UIApplication.significantTimeChangeNotification, object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadLoans()
    }

    // Called after adding or returning a loan so the saved record is visible.
    func showLoans(returned: Bool) {
        categoryControl.selectedSegmentIndex = returned ? 1 : 0
        searchBar.text = ""
        reloadLoans()
        if !visibleLoans.isEmpty {
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        }
    }

    @IBAction private func categoryChanged(_ sender: UISegmentedControl) {
        reloadLoans()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        reloadLoans()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    @objc private func timeChanged(_ notification: Notification) {
        reloadLoans()
    }

    private func reloadLoans() {
        let showingReturned = categoryControl.selectedSegmentIndex == 1
        let searchText = (searchBar.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        visibleLoans = []

        for loan in LoanManager.shared.loans {
            if loan.isReturned == showingReturned {
                if searchText.isEmpty || loan.displayName.localizedCaseInsensitiveContains(searchText)
                    || loan.borrowerName.localizedCaseInsensitiveContains(searchText) {
                    visibleLoans.append(loan)
                }
            }
        }

        if showingReturned {
            visibleLoans.sort { first, second in
                (first.returnedDate ?? .distantPast) > (second.returnedDate ?? .distantPast)
            }
        }

        tableView.backgroundView = nil
        if visibleLoans.isEmpty {
            if !searchText.isEmpty {
                emptyLabel.text = "No matching loans."
            } else if showingReturned {
                emptyLabel.text = "No returned loans yet."
            } else {
                emptyLabel.text = "No loans yet. Tap + to add one."
            }
            tableView.backgroundView = emptyLabel
        }
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return visibleLoans.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LoanCell", for: indexPath) as! LoanCell
        let loan = visibleLoans[indexPath.row]
        let dateText: String
        if loan.isReturned {
            if let returnedDate = loan.returnedDate {
                dateText = "Returned \(dateFormatter.string(from: returnedDate))"
            } else {
                dateText = "Return date unavailable"
            }
        } else {
            dateText = "Due \(dateFormatter.string(from: loan.dueDate))"
        }
        cell.show(loan, dateText: dateText)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let loan = visibleLoans[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "ShowLoanDetails", sender: loan.id)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        searchBar.resignFirstResponder()
        if segue.identifier == "ShowLoanDetails",
           let details = segue.destination as? LoanDetailsViewController {
            details.loanID = sender as? UUID
        }
    }
}

class LoanCell: UITableViewCell {
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var borrowerLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var statusLabel: UILabel!

    func show(_ loan: Loan, dateText: String) {
        let status = loan.status
        nameLabel.text = loan.displayName
        borrowerLabel.text = loan.borrowerName
        dateLabel.text = dateText
        statusLabel.text = status
        if status == "Overdue" {
            statusLabel.textColor = .systemRed
        } else if loan.isReturned {
            statusLabel.textColor = .secondaryLabel
        } else {
            statusLabel.textColor = tintColor
        }

        isAccessibilityElement = true
        accessibilityLabel = "\(loan.displayName), \(loan.borrowerName), \(dateText), \(status)"
        accessibilityTraits = .button
    }
}
