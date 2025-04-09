//import UIKit
//
//class UpdateExpenseViewController: UIViewController {
//    
//    @IBOutlet weak var expenseIDTextField: UITextField!
//    @IBOutlet weak var titleTextField: UITextField!
//    @IBOutlet weak var amountTextField: UITextField!
//    @IBOutlet weak var datePicker: UIDatePicker!
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
//        view.addGestureRecognizer(tapGesture)
//    }
//    
//    
//    @objc func dismissKeyboard() {
//        view.endEditing(true)
//    }
//    
//    @IBAction func updateExpenseButtonTapped(_ sender: UIButton) {
//        // Step 1: Ensure a valid expense ID is entered
//        guard let idText = expenseIDTextField.text, let expenseId = Int(idText) else {
//            showAlert(message: "Please enter a valid Expense ID.")
//            return
//        }
//        
//        // Step 2: Get the new values for title, amount, and date
//        guard let newTitle = titleTextField.text, !newTitle.isEmpty else {
//            showAlert(message: "Please enter a valid title.")
//            return
//        }
//        
//        guard let amountText = amountTextField.text, let newAmount = Double(amountText) else {
//            showAlert(message: "Please enter a valid amount.")
//            return
//        }
//        
//        let newDate = formatDate(datePicker.date)
//        
//        // Step 3: Update the expense
//        let success = DataManager.shared.updateExpense(id: expenseId, title: newTitle, amount: newAmount, date: newDate)
//        
//        // Step 4: Show the success or failure message
//        let message = success ? "Expense updated successfully!" : "Failed to update expense."
//        showAlert(message: message)
//    }
//    
//    private func formatDate(_ date: Date) -> String {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "yyyy-MM-dd"
//        return formatter.string(from: date)
//    }
//    
//    private func showAlert(message: String) {
//        // Step 5: Create and display the alert message
//        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "OK", style: .default))
//        present(alert, animated: true)
//    }
//}


import UIKit
import CoreData

class UpdateExpenseViewController: UIViewController {
    
    @IBOutlet weak var expenseIDTextField: UITextField!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTapGesture()
    }
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    @IBAction func updateExpenseButtonTapped(_ sender: UIButton) {
        guard validateInputs() else { return }
        
        let expenseId = Int32(expenseIDTextField.text!)!
        let newDateString = dateFormatter.string(from: datePicker.date)
        
        updateExpense(id: expenseId, newTitle: titleTextField.text!,
                     newAmount: Double(amountTextField.text!)!, newDate: newDateString)
    }
    
    private func validateInputs() -> Bool {
        // Validate ID
        guard let idText = expenseIDTextField.text, let _ = Int32(idText) else {
            showAlert("Please enter a valid numeric Expense ID")
            return false
        }
        
        // Validate title
        guard let title = titleTextField.text, !title.isEmpty else {
            showAlert("Title cannot be empty")
            return false
        }
        
        // Validate amount
        guard let amountText = amountTextField.text,
              let amount = Double(amountText), amount > 0 else {
            showAlert("Please enter a valid positive amount")
            return false
        }
        
        return true
    }
    
    private func updateExpense(id: Int32, newTitle: String, newAmount: Double, newDate: String) {
        let request: NSFetchRequest<Expense> = Expense.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", id)
        
        do {
            let results = try context.fetch(request)
            
            guard let expense = results.first else {
                showAlert("Expense not found")
                return
            }
            
            // Check if expense.date is not nil
            if let existingDate = expense.date { // `expense.date` is already a Date
                let calendar = Calendar.current
                // Calculate the difference in days between `existingDate` and the current date
                if let days = calendar.dateComponents([.day], from: existingDate, to: Date()).day,
                   days > 30 {
                    showAlert("Cannot update expenses older than 30 days")
                    return
                }
            } else {
                // Handle the case where `expense.date` is nil (if necessary)
                showAlert("Expense date is missing")
            }
            
            // Convert `newDate` (String) to `Date`
            if let newDateObject = dateFormatter.date(from: newDate) {
                // Update properties
                expense.title = newTitle
                expense.amount = newAmount
                expense.date = newDateObject
                
                try context.save()
                
                showAlert("Expense updated successfully!") {
                    self.navigationController?.popViewController(animated: true)
                }
            } else {
                showAlert("Invalid date format")
            }
            
        } catch {
            showAlert("Update failed: \(error.localizedDescription)")
        }
    }

    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func showAlert(_ message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
}
