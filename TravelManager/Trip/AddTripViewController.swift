//import UIKit
//import CoreData
//
//class AddTripViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
//
//    @IBOutlet weak var tripTitle: UITextField!
//    @IBOutlet weak var destinationTrip: UITextField!
//    @IBOutlet weak var startDateTrip: UIDatePicker!
//    @IBOutlet weak var endDateTrip: UIDatePicker!
//    
//    private var pickerView = UIPickerView()
//    private var destinations: [Destination] = []
//    private var selectedDestination: Destination?
//
//    var managedContext: NSManagedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupPickerView()
//        loadDestinations()
//        setupDismissKeyboard()
//    }
//    
//    private func setupDismissKeyboard() {
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
//        view.addGestureRecognizer(tapGesture)
//    }
//    
//    @objc func dismissKeyboard() {
//        view.endEditing(true)
//    }
//
//    private func setupPickerView() {
//        pickerView.delegate = self
//        pickerView.dataSource = self
//        destinationTrip.inputView = pickerView
//        destinationTrip.delegate = self
//
//        let toolbar = UIToolbar()
//        toolbar.sizeToFit()
//        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(donePicker))
//        toolbar.setItems([doneButton], animated: false)
//        destinationTrip.inputAccessoryView = toolbar
//    }
//
//    private func loadDestinations() {
//        let fetchRequest: NSFetchRequest<Destination> = Destination.fetchRequest()
//        do {
//            destinations = try managedContext.fetch(fetchRequest)
//        } catch {
//            print("Failed to fetch destinations: \(error.localizedDescription)")
//        }
//    }
//
//    @objc private func donePicker() {
//        destinationTrip.resignFirstResponder()
//    }
//
////    @IBAction func addTripButtonTapped(_ sender: Any) {
////        guard validateInputs() else { return }
////        
////        let newTrip = Trip(context: managedContext)
////        
////        // Auto-increment ID
////        newTrip.id = getNextTripID()
////        newTrip.title = tripTitle.text!
////        
////        // Store Date objects directly
////        newTrip.startDate = startDateTrip.date
////        newTrip.endDate = endDateTrip.date
////        
////        newTrip.destination = selectedDestination
////
////        saveTrip(trip: newTrip)
////    }
//    
//    @IBAction func addTripButtonTapped(_ sender: Any) {
//        guard validateInputs() else { return }
//        
//        let newTrip = Trip(context: managedContext)
//        
//        // Auto-increment ID
//        newTrip.id = getNextTripID()
//        newTrip.title = tripTitle.text!
//        
//        // Store Date objects directly
//        newTrip.startDate = startDateTrip.date
//        newTrip.endDate = endDateTrip.date
//        
//        newTrip.destination = selectedDestination
//        
//        // Save the trip locally first
//        saveTrip(trip: newTrip)
//        
//        // Convert dates to timestamps
//        let startDateTimestamp = Int(startDateTrip.date.timeIntervalSince1970)
//        let endDateTimestamp = Int(endDateTrip.date.timeIntervalSince1970)
//        
//        // Prepare data for API request
//        let tripData: [String: Any] = [
//            "title": newTrip.title ?? "",
//            "startDate": startDateTimestamp,  // Using timestamp instead of formatted string
//            "endDate": endDateTimestamp,      // Using timestamp instead of formatted string
//            "id": "\(newTrip.id)",            // Ensure ID is a string as in your JSON
//            "destinationId": "\(selectedDestination?.id ?? 0)" // Ensure destination ID is a string
//        ]
//        
//        // Get the destination ID dynamically from selectedDestination
//        if let destinationId = selectedDestination?.id {
//            let apiUrl = "https://67e3654e97fc65f535397b85.mockapi.io/api/travel/destination/\(destinationId)/trip"
//            sendTripDataToAPI(tripData, apiUrl: apiUrl)
//        }
//    }
//
//    private func sendTripDataToAPI(_ tripData: [String: Any], apiUrl: String) {
//        guard let url = URL(string: apiUrl) else { return }
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        
//        // Convert the trip data to JSON
//        do {
//            request.httpBody = try JSONSerialization.data(withJSONObject: tripData, options: [])
//        } catch {
//            print("Failed to encode trip data: \(error)")
//            return
//        }
//        
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            if let error = error {
//                print("Error sending trip data to API: \(error)")
//                return
//            }
//            
//            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 {
//                // Successfully added the trip to the API
//                DispatchQueue.main.async {
//                    self.showAlert(message: "Trip added successfully to the API!")
//                }
//            } else {
//                DispatchQueue.main.async {
//                    self.showAlert(message: "Failed to add trip to the API.")
//                }
//            }
//        }.resume()
//    }
//
//
//
//    private let dateFormatter: DateFormatter = {
//            let formatter = DateFormatter()
//            formatter.dateFormat = "yyyy-MM-dd" // Match your desired format
//            return formatter
//        }()
//    
//    private func validateInputs() -> Bool {
//        guard let title = tripTitle.text, !title.isEmpty else {
//            showAlert(message: "Please enter a trip title.")
//            return false
//        }
//        
//        guard selectedDestination != nil else {
//            showAlert(message: "Please select a destination.")
//            return false
//        }
//        
//        guard startDateTrip.date <= endDateTrip.date else {
//            showAlert(message: "Start date must be before end date.")
//            return false
//        }
//        
//        return true
//    }
//
//    private func getNextTripID() -> Int32 {
//        let fetchRequest: NSFetchRequest<Trip> = Trip.fetchRequest()
//        do {
//            let trips = try managedContext.fetch(fetchRequest)
//            return (trips.map { $0.id }.max() ?? 0) + 1
//        } catch {
//            return 1
//        }
//    }
//
//    private func saveTrip(trip: Trip) {
//        do {
//            try managedContext.save()
//            showAlert(message: "Trip added successfully!") {
//                self.clearFields()
//            }
//        } catch {
//            showAlert(message: "Save failed: \(error.localizedDescription)")
//        }
//    }
//
//    private func clearFields() {
//        tripTitle.text = ""
//        destinationTrip.text = ""
//        selectedDestination = nil
//    }
//
//    private func showAlert(message: String, completion: (() -> Void)? = nil) {
//        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
//            completion?()
//        })
//        present(alert, animated: true)
//    }
//
//    // MARK: - PickerView Methods
//    func numberOfComponents(in pickerView: UIPickerView) -> Int {
//        return 1
//    }
//
//    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
//        return destinations.count
//    }
//
//    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
//        guard let city = destinations[row].city, let country = destinations[row].country else { return nil }
//        return "\(city), \(country)"
//    }
//
//    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
//        selectedDestination = destinations[row]
//        guard let city = destinations[row].city, let country = destinations[row].country else { return }
//        destinationTrip.text = "\(city), \(country)"
//    }
//}


import UIKit
import CoreData
import SystemConfiguration

class AddTripViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {

    @IBOutlet weak var tripTitle: UITextField!
    @IBOutlet weak var destinationTrip: UITextField!
    @IBOutlet weak var startDateTrip: UIDatePicker!
    @IBOutlet weak var endDateTrip: UIDatePicker!
    
    private var pickerView = UIPickerView()
    private var destinations: [Destination] = []
    private var selectedDestination: Destination?
    private var currentTripId: Int32 = 0
    private var currentTripData: [String: Any] = [:]
    private var currentApiUrl: String = ""

    var managedContext: NSManagedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPickerView()
        loadDestinations()
        setupDismissKeyboard()
    }
    
    // MARK: - Setup
    private func setupDismissKeyboard() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    private func setupPickerView() {
        pickerView.delegate = self
        pickerView.dataSource = self
        destinationTrip.inputView = pickerView
        destinationTrip.delegate = self

        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(donePicker))
        toolbar.setItems([doneButton], animated: false)
        destinationTrip.inputAccessoryView = toolbar
    }
    
    @objc private func donePicker() {
        destinationTrip.resignFirstResponder()  // Dismiss the picker view
    }

    // MARK: - Data Management
    private func loadDestinations() {
        let fetchRequest: NSFetchRequest<Destination> = Destination.fetchRequest()
        do {
            destinations = try managedContext.fetch(fetchRequest)
        } catch {
            showAlert(message: "Failed to load destinations")
        }
    }

    // MARK: - Main Action
    @IBAction func addTripButtonTapped(_ sender: Any) {
        guard validateInputs() else { return }
        guard isInternetAvailable() else {
            showAlert(message: "Internet connection required to add trips")
            return
        }
        
        prepareTripData()
        startSyncProcess(attempt: 1)
    }

    // MARK: - Sync Process
    private func prepareTripData() {
        currentTripId = getNextTripID()
        let startTimestamp = Int(startDateTrip.date.timeIntervalSince1970)
        let endTimestamp = Int(endDateTrip.date.timeIntervalSince1970)
        
        currentTripData = [
            "title": tripTitle.text!,
            "startDate": startTimestamp,
            "endDate": endTimestamp,
            "id": "\(currentTripId)",
            "destinationId": "\(selectedDestination?.id ?? 0)"
        ]
        
        currentApiUrl = "https://67e3654e97fc65f535397b85.mockapi.io/api/travel/destination/\(selectedDestination?.id ?? 0)/trip"
    }

    private func startSyncProcess(attempt: Int) {
        sendTripDataToAPI { [weak self] success in
            guard let self = self else { return }
            
            if success {
                self.saveTripToCoreData()
                DispatchQueue.main.async {
                    self.showAlert(message: "Trip added successfully!") {
                        self.clearFields()
                    }
                }
            } else if attempt < 3 {
                DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                    self.startSyncProcess(attempt: attempt + 1)
                }
            } else {
                DispatchQueue.main.async {
                    self.showAlert(message: "Failed after 3 attempts. Try again later.")
                }
            }
        }
    }

    // MARK: - API Communication
    private func sendTripDataToAPI(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: currentApiUrl) else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: currentTripData, options: [])
            URLSession.shared.dataTask(with: request) { _, response, _ in
                let success = (response as? HTTPURLResponse)?.statusCode == 201
                completion(success)
            }.resume()
        } catch {
            completion(false)
        }
    }

    // MARK: - Core Data
    private func saveTripToCoreData() {
        let newTrip = Trip(context: managedContext)
        newTrip.id = currentTripId
        newTrip.title = tripTitle.text
        newTrip.startDate = startDateTrip.date
        newTrip.endDate = endDateTrip.date
        newTrip.destination = selectedDestination
        
        do {
            try managedContext.save()
        } catch {
            showAlert(message: "Failed to save trip locally")
        }
    }

    // MARK: - Utilities
    private func getNextTripID() -> Int32 {
        let fetchRequest: NSFetchRequest<Trip> = Trip.fetchRequest()
        do {
            let trips = try managedContext.fetch(fetchRequest)
            return (trips.map { $0.id }.max() ?? 0) + 1
        } catch {
            return 1
        }
    }

    private func validateInputs() -> Bool {
        guard let title = tripTitle.text, !title.isEmpty else {
            showAlert(message: "Trip title required")
            return false
        }
        
        guard selectedDestination != nil else {
            showAlert(message: "Select a destination")
            return false
        }
        
        guard startDateTrip.date <= endDateTrip.date else {
            showAlert(message: "Invalid date range")
            return false
        }
        
        return true
    }

    private func clearFields() {
        tripTitle.text = ""
        destinationTrip.text = ""
        selectedDestination = nil
    }

    // MARK: - Network Check
    private func isInternetAvailable() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else { return false }
        
        var flags: SCNetworkReachabilityFlags = []
        return SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags)
            && flags.contains(.reachable)
            && !flags.contains(.connectionRequired)
    }

    // MARK: - PickerView Methods
    func numberOfComponents(in pickerView: UIPickerView) -> Int { return 1 }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return destinations.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        guard let city = destinations[row].city, let country = destinations[row].country else { return nil }
        return "\(city), \(country)"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedDestination = destinations[row]
        guard let city = destinations[row].city, let country = destinations[row].country else { return }
        destinationTrip.text = "\(city), \(country)"
    }

    // MARK: - Alert
    private func showAlert(message: String, completion: (() -> Void)? = nil) {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                completion?()
            })
            self?.present(alert, animated: true)
        }
    }
}
