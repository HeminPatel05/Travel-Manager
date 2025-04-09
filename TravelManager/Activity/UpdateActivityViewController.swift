import UIKit
import CoreData

class UpdateActivityViewController: UIViewController {

    @IBOutlet weak var activityID: UITextField!
    @IBOutlet weak var activityName: UITextField!
    @IBOutlet weak var activityDate: UIDatePicker!
    @IBOutlet weak var activityTime: UIDatePicker!
    @IBOutlet weak var activityLocation: UITextField!
    
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
        
        // Set numeric keyboard for ID field
        activityID.keyboardType = .numberPad
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @IBAction func updateActivityButton(_ sender: Any) {
        guard validateInputs() else { return }
        
        guard let activity = fetchActivity() else {
            showAlert(title: "Error", message: "Activity not found")
            return
        }
        
        if isPastActivity(activityDate.date) {
            showAlert(title: "Error", message: "Cannot update past activities")
            return
        }
        
        updateActivity(activity: activity)
    }

    private func validateInputs() -> Bool {
        // Validate Activity ID
        guard let activityId = activityID.text, !activityId.isEmpty else {
            showAlert(title: "Error", message: "Please enter activity ID")
            return false
        }
        
        // Check if ID is numeric
        guard let _ = Int32(activityId) else {
            showAlert(title: "Invalid ID", message: "Please enter a numeric activity ID")
            return false
        }
        
        // Validate other fields
        guard let name = activityName.text, !name.isEmpty else {
            showAlert(title: "Error", message: "Please enter activity name")
            return false
        }
        
        guard let location = activityLocation.text, !location.isEmpty else {
            showAlert(title: "Error", message: "Please enter location")
            return false
        }
        
        return true
    }

    // Rest of the code remains the same...
    private func fetchActivity() -> Activity? {
        guard let activityId = Int32(activityID.text!) else { return nil }
        
        let request: NSFetchRequest<Activity> = Activity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", activityId)
        
        do {
            return try context.fetch(request).first
        } catch {
            showAlert(title: "Error", message: "Fetch error: \(error.localizedDescription)")
            return nil
        }
    }

    private func isPastActivity(_ selectedDate: Date) -> Bool {
        let calendar = Calendar.current
        return selectedDate < calendar.startOfDay(for: Date())
    }

    private func updateActivity(activity: Activity) {
        activity.name = activityName.text
        activity.location = activityLocation.text
        activity.date = activityDate.date
        activity.time = activityTime.date
        
        do {
            try context.save()
            showAlert(title: "Success", message: "Activity updated") {
                self.clearFields()
                self.navigationController?.popViewController(animated: true)
            }
        } catch {
            showAlert(title: "Error", message: "Update failed: \(error.localizedDescription)")
        }
    }

    private func formatDate(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }

    private func formatTime(_ time: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: time)
    }

    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }

    private func clearFields() {
        activityID.text = ""
        activityName.text = ""
        activityLocation.text = ""
        activityDate.date = Date()
        activityTime.date = Date()
    }
}
