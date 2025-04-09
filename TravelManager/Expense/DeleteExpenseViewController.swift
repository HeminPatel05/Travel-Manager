//import UIKit
//
//class DeleteExpenseViewController: UIViewController {
//    
//    @IBOutlet weak var expenseIDTextField: UITextField!
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//    }
//
//    @IBAction func deleteExpenseButtonTapped(_ sender: UIButton) {
//        // Step 1: Ensure a valid expense ID is entered
//        guard let idText = expenseIDTextField.text, let expenseId = Int(idText) else {
//            showAlert(message: "Please enter a valid Expense ID.")
//            return
//        }
//
//        // Step 2: Attempt to delete the expense
//        let result = DataManager.shared.deleteExpense(id: expenseId)
//
//        // Step 3: Show a success or failure alert
//        showAlert(message: result.message)
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
//        view.addGestureRecognizer(tapGesture)
//    }
//    
//    
//    @objc func dismissKeyboard() {
//        view.endEditing(true)
//    }
//
//    private func showAlert(message: String) {
//        // Step 4: Create an alert to show the success or failure message
//        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "OK", style: .default))
//        present(alert, animated: true)
//    }
//}

import UIKit
import CoreData

class DeleteExpenseViewController: UIViewController {
    
    @IBOutlet weak var expenseIDTextField: UITextField!
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    @IBAction func deleteExpenseButtonTapped(_ sender: UIButton) {
        guard let idText = expenseIDTextField.text,
              let expenseId = Int32(idText) else {
            showAlert(message: "Please enter a valid numeric Expense ID")
            return
        }
        
        deleteExpense(id: expenseId)
    }
    
    private func deleteExpense(id: Int32) {
        let request: NSFetchRequest<Expense> = Expense.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", id)
        
        do {
            let expenses = try context.fetch(request)
            
            guard let expense = expenses.first else {
                showAlert(message: "Expense not found")
                return
            }
            
            // Date validation check
            guard let expenseDate = expense.date else {
                showAlert(message: "Invalid expense date")
                return
            }
            
            if isOlderThan30Days(expenseDate) {
                showAlert(message: "Cannot delete expenses older than 30 days")
                return
            }
            
            context.delete(expense)
            try context.save()
            
            showAlert(message: "Expense deleted successfully") {
                self.navigationController?.popViewController(animated: true)
            }
            
        } catch {
            showAlert(message: "Deletion failed: \(error.localizedDescription)")
        }
    }
    
    private func isOlderThan30Days(_ date: Date) -> Bool {
        let calendar = Calendar.current
        guard let daysDifference = calendar.dateComponents([.day],
            from: date,
            to: Date()).day else { return false }
        
        return daysDifference > 30
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func showAlert(message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
}
