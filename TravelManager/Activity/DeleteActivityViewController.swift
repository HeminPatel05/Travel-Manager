import UIKit
import CoreData

class DeleteActivityViewController: UIViewController {

    @IBOutlet weak var activityID: UITextField!
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        
        // Set numeric keyboard for ID field
        activityID.keyboardType = .numberPad
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    @IBAction func deleteActivityButton(_ sender: Any) {
        guard validateInput() else { return }
        deleteActivity(id: Int32(activityID.text!)!)
    }

    private func validateInput() -> Bool {
        guard let idText = activityID.text, !idText.isEmpty else {
            showAlert(title: "Error", message: "Please enter activity ID")
            return false
        }
        
        guard Int32(idText) != nil else {
            showAlert(title: "Invalid ID", message: "Please enter a numeric activity ID")
            return false
        }
        
        return true
    }

    private func deleteActivity(id: Int32) {
        let request: NSFetchRequest<Activity> = Activity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", id)

        do {
            let results = try context.fetch(request)
            
            guard let activity = results.first else {
                showAlert(title: "Error", message: "Activity not found")
                return
            }
            
            // Ensure the activity has valid date and time values
            guard let activityDate = activity.date,
                  let activityTime = activity.time else {
                showAlert(title: "Error", message: "Invalid activity date/time")
                return
            }
            
            // Combine date and time properly
            let calendar = Calendar.current
            let activityDateTime = calendar.date(bySettingHour: calendar.component(.hour, from: activityTime),
                                                 minute: calendar.component(.minute, from: activityTime),
                                                 second: 0,
                                                 of: activityDate)
            
            guard let validActivityDateTime = activityDateTime else {
                showAlert(title: "Error", message: "Failed to combine date/time")
                return
            }
            
            // Compare with current date/time
            if validActivityDateTime < Date() {
                showAlert(title: "Error", message: "Cannot delete past activities")
                return
            }
            
            // Proceed with deletion
            context.delete(activity)
            try context.save()
            
            showAlert(title: "Success", message: "Activity deleted successfully") {
                self.navigationController?.popViewController(animated: true)
            }
            
        } catch {
            showAlert(title: "Error", message: "Deletion failed: \(error.localizedDescription)")
        }
    }


    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
}
