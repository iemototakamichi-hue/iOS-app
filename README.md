# BorrowBack

BorrowBack helps you remember which items and amounts of money you lent to friends. It is a Swift and UIKit app with Storyboard screens. Loans are stored on the device, and reminders use iOS local notifications.

## Run on a Mac

1. Copy this entire project folder to the Mac so `BorrowBack.xcodeproj` stays next to the `BorrowBack` source folder.
2. Open `BorrowBack.xcodeproj` in Xcode 16 or later.
3. Choose the **BorrowBack** scheme and an iPhone simulator running iOS 16 or later. Press **Run** or `Command-R`.
4. To run on a physical iPhone, select your team under **Signing & Capabilities**. If the project’s bundle identifier is unavailable for your team, change it to a unique one.

## Screens and navigation

| Screen | How it works |
| --- | --- |
| Launch | iOS shows the BorrowBack logo and name from `LaunchScreen.storyboard` while the app starts. |
| My Loan List | The navigation controller opens this screen from `Main.storyboard`. The table shows the loan, borrower, due or return date, and status. Use the search bar to match a borrower or loan name or amount. The **On Loan** and **Returned** tabs share the same table. |
| Create New Loan | Tap **+** to open the form. Choose **Item** or **Money**, enter the loan and borrower, and pick the dates. The form starts with today's date and a due date one week later. Notes and reminders are optional. **Save Loan** validates the fields, saves the record, and goes back to **On Loan**. |
| Loan Details | Tap a row to open the selected record. The screen shows the dates, notes, and status, plus the actual return date for a returned loan. |
| Edit Loan | Tap **Edit** to open the same form with the saved values filled in. Saving takes you back to the updated details. |
| Return confirmation | Tap **Mark as Returned** and then **Confirm Return**. BorrowBack records the return date and takes you to **Returned**. |
| Delete confirmation | Tap **Delete** and confirm to remove the loan and go back to the list. |

`Main.storyboard` sets up the navigation controller and the `AddLoan`, `ShowLoanDetails`, and `EditLoan` segues. A segue opens the next screen. `prepare(for:sender:)` gives the details or edit screen the UUID of the loan it should load. The navigation controller provides Back buttons, and `popViewController` goes back to the screen already on the navigation stack. The list and details reload when they reappear.

## Swift files

| File | What it does |
| --- | --- |
| `AppDelegate.swift` | Starts the app and lets iOS show a notification banner while BorrowBack is open. The `SceneDelegate` holds the window that loads `Main.storyboard`. |
| `Loan.swift` | Defines the `Loan` struct and its fields. It validates money input, formats ringgit amounts, and calculates the display status. A loan becomes overdue the day after its due date. |
| `LoanManager.swift` | Keeps the array of loans and loads and saves it with `UserDefaults`. Each loan has a UUID, so the app can find the right record even after a search changes the order of the visible rows. |
| `LoanListViewController.swift` | Filters the array by category and search text. `LoanCell` puts the display name, borrower, date, and status into the Storyboard table cell. |
| `LoanFormViewController.swift` | Shows the right field for each loan type, checks the inputs, and adds or updates the record. It keeps the same ID and return information when you edit a loan. |
| `LoanDetailsViewController.swift` | Displays a single loan and handles the return and delete confirmation alerts. |
| `NotificationManager.swift` | Requests permission and schedules a reminder for the selected date and time. It uses the loan UUID to replace an edited reminder and cancel it when the loan is returned or deleted. |

## Important functions

- `loadLoans()` reads the saved bytes from `UserDefaults`. `JSONDecoder` turns them back into an array of `Loan` values. The manager does this when it first starts.
- `saveLoans()` uses `JSONEncoder` to convert the array into bytes and writes them to `UserDefaults`. `addLoan()`, `updateLoan()`, and `deleteLoan()` make a changed copy of the array and call `saveLoans()`.
- `saveTapped()` checks that the borrower's name and loan value are present, that an amount is positive with up to two decimal places, and that the due date is on or after the date lent.
- `reloadLoans()` loops over the saved records. It uses `localizedCaseInsensitiveContains()` to check both the display name and the borrower against the search text.
- `markAsReturned()` sets `isReturned`, records the current date, and saves the edited loan. The details screen then cancels its reminder and opens the **Returned** category.
- `scheduleReminder()` asks iOS for permission and schedules a single alert. The loan is saved before scheduling. If permission is denied or scheduling fails, BorrowBack keeps the loan and shows a message. [Apple's guide to local notifications](https://developer.apple.com/documentation/usernotifications/scheduling-a-notification-locally-from-your-app)

## Mac testing checklist

Static checks on Windows confirmed the Xcode project references, storyboard navigation and control connections, Info.plist, shared scheme, and image assets. Xcode and the iOS Simulator were unavailable, so the app build and the checks below still need to be run on a Mac before the demonstration.

| Check | Expected result |
| --- | --- |
| Build and launch | The launch logo appears as the app starts, then **My Loan List** opens with working search, categories, and **+**. |
| Navigation and Back | Open the form, go back without saving, open a record, and open **Edit**. Each Back button returns to the screen you came from. |
| Create and view | Add an item named **Calculator** and a money loan for **20.50**, both for **Wen Xuan**. Both appear under **On Loan**. Tap each to verify the fields and notes. |
| Persistence | Stop or close the app and run it again. Confirm that the saved records and edits remain. |
| Edit | Change the borrower and due date. Saving returns to **Loan Details** and the list reflects both changes. |
| Search | Search for `calculator`, `wen`, and `20.50`. The relevant records appear, and clearing the search restores the selected category. |
| Overdue | Create a loan with a date lent and a due date in the past. It shows **Overdue**. A loan due today still shows **On Loan**. |
| Return | Try **Cancel** first, then **Confirm Return**. The record moves to **Returned**, shows the actual return date, and can no longer be marked returned. |
| Delete | Try **Cancel** first, then confirm. The record disappears and stays deleted after relaunch. |
| Invalid input | Try a blank borrower or item name, zero, a negative amount, an invalid amount, and a due date earlier than the date lent. The form shows an alert and stays open. |
| Local notifications | On an iPhone, grant permission and schedule a reminder a few minutes ahead. Verify delivery with the app in the background. Edit a future reminder and verify that only the new time fires. Return or delete a loan before its reminder and verify that no alert arrives. Disable permission and confirm that you can still save a loan. |
| Layout | Try a small iPhone, landscape, and a larger text size. Verify that the form scrolls with the keyboard open and that the list and detail text remain readable. |
