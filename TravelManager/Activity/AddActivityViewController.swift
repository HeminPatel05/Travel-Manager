import UIKit
import CoreData
import Network

class NetworkMonitor {
    static let shared = NetworkMonitor()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue.global(qos: .background)
    
    var isConnected: Bool = false
    
    private init() {
        monitor.pathUpdateHandler = { path in
            self.isConnected = path.status == .satisfied
        }
        monitor.start(queue: queue)
    }
}

class AddActivityViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var tripTextField: UITextField!
    @IBOutlet weak var activityName: UITextField!
    @IBOutlet weak var activityDate: UIDatePicker!
    @IBOutlet weak var activityTime: UIDatePicker!
    @IBOutlet weak var activityLocation: UITextField!
    
    var trips: [Trip] = []
    var selectedTrip: Trip?
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTripPicker()
        loadTrips()
    }
    
    private func setupTripPicker() {
        let tripPickerView = UIPickerView()
        tripPickerView.delegate = self
        tripPickerView.dataSource = self
        tripTextField.inputView = tripPickerView
    }
    
    private func loadTrips() {
        let request: NSFetchRequest<Trip> = Trip.fetchRequest()
        
        do {
            trips = try context.fetch(request)
            if !trips.isEmpty {
                selectedTrip = trips.first
                tripTextField.text = selectedTrip?.title
            }
        } catch {
            print("Error loading trips: \(error)")
        }
    }

    // MARK: - Picker View Methods
    func numberOfComponents(in pickerView: UIPickerView) -> Int { return 1 }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return trips.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return trips[row].title
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedTrip = trips[row]
        tripTextField.text = trips[row].title
    }

    @IBAction func addActivityButton(_ sender: Any) {
        guard validateInputs() else { return }
        
        let newActivity = Activity(context: context)
        newActivity.id = generateActivityID()
        newActivity.name = activityName.text
        newActivity.location = activityLocation.text
        newActivity.date = activityDate.date
        newActivity.time = activityTime.date
        newActivity.trip = selectedTrip
        
        saveActivity()
        syncActivityToServer(newActivity)
    }
    
    private func generateActivityID() -> Int32 {
        let request: NSFetchRequest<Activity> = Activity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        request.fetchLimit = 1
        
        do {
            let lastActivity = try context.fetch(request).first
            return (lastActivity?.id ?? 0) + 1
        } catch {
            print("Error generating ID: \(error)")
            return 1
        }
    }
    
    private func validateInputs() -> Bool {
        guard selectedTrip != nil else {
            showAlert("Please select a trip")
            return false
        }
        
        guard let name = activityName.text, !name.isEmpty else {
            showAlert("Please enter activity name")
            return false
        }
        
        guard let location = activityLocation.text, !location.isEmpty else {
            showAlert("Please enter location")
            return false
        }
        
        return true
    }
    
    private func saveActivity() {
        do {
            try context.save()
            showAlert("Activity added successfully!", clearFields: true)
        } catch {
            showAlert("Failed to save activity: \(error.localizedDescription)")
        }
    }
    
    private func syncActivityToServer(_ activity: Activity) {
        guard NetworkMonitor.shared.isConnected else {
            showAlert("No internet connection. Activity will be saved locally.")
            return
        }
        
        let url = URL(string: "https://yourapi.com/activities")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let activityData: [String: Any] = [
            "id": activity.id,
            "name": activity.name ?? "",
            "location": activity.location ?? "",
            "date": formatDate(activity.date ?? Date()),
            "time": formatTime(activity.time ?? Date()),
            "trip_id": activity.trip?.id ?? 0
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: activityData, options: [])
        } catch {
            print("Error serializing JSON: \(error)")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error syncing activity: \(error)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 {
                print("Activity synced successfully!")
            } else {
                print("Failed to sync activity. Response: \(String(describing: response))")
            }
        }
        
        task.resume()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ time: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: time)
    }
    
    private func showAlert(_ message: String, clearFields: Bool = false) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                if clearFields { self.clearFields() }
            })
            self.present(alert, animated: true)
        }
    }
    
    private func clearFields() {
        activityName.text = ""
        activityLocation.text = ""
        activityDate.date = Date()
        activityTime.date = Date()
        tripTextField.text = ""
        selectedTrip = nil
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}
