import UIKit
import CoreData
import SystemConfiguration

class UpdateTripViewController: UIViewController {
    
    @IBOutlet weak var tripIDTextField: UITextField!
    @IBOutlet weak var tripTitleTextField: UITextField!
    @IBOutlet weak var endDatePicker: UIDatePicker!
    
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    private var currentTrip: Trip?
    private var currentApiUrl = ""
    private var currentRequestBody: [String: Any] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        tripIDTextField.keyboardType = .numberPad
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @IBAction func updateTripButtonTapped(_ sender: Any) {
        guard isInternetAvailable() else {
            showAlert(message: "Internet connection required for updates")
            return
        }
        
        guard validateInputs(),
              let tripID = Int32(tripIDTextField.text!),
              let trip = fetchTrip(id: tripID) else {
            return
        }
        
        currentTrip = trip
        prepareUpdateData()
        startUpdateProcess(attempt: 1)
    }
    
    // MARK: - Update Process
    private func prepareUpdateData() {
        guard let trip = currentTrip else { return }
        
        currentRequestBody = [
            "title": tripTitleTextField.text!,
            "endDate": Int(endDatePicker.date.timeIntervalSince1970)
        ]
        
        if let destinationID = trip.destination?.id {
            currentApiUrl = "https://67e3654e97fc65f535397b85.mockapi.io/api/travel/destination/\(destinationID)/trip/\(trip.id)"
        }
    }
    
    private func startUpdateProcess(attempt: Int) {
        guard let trip = currentTrip, validateDates(for: trip) else { return }
        
        updateTripOnAPI(attempt: attempt) { [weak self] apiSuccess in
            guard let self = self else { return }
            
            if apiSuccess {
                self.updateLocalTrip()
                DispatchQueue.main.async {
                    self.showAlert(message: "Trip updated successfully!") {
                        self.clearFields()
                    }
                }
            } else if attempt < 3 {
                DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                    self.startUpdateProcess(attempt: attempt + 1)
                }
            } else {
                DispatchQueue.main.async {
                    self.showAlert(message: "Update failed after 3 attempts")
                }
            }
        }
    }
    
    // MARK: - API Operations
    private func updateTripOnAPI(attempt: Int, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: currentApiUrl) else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: currentRequestBody, options: [])
            
            URLSession.shared.dataTask(with: request) { _, response, error in
                let success = error == nil && (response as? HTTPURLResponse)?.statusCode == 200
                completion(success)
            }.resume()
        } catch {
            completion(false)
        }
    }
    
    // MARK: - Core Data Operations
    private func updateLocalTrip() {
        guard let trip = currentTrip else { return }
        
        DispatchQueue.main.async {
            trip.title = self.tripTitleTextField.text!
            trip.endDate = self.endDatePicker.date
            
            do {
                try self.context.save()
            } catch {
                self.showAlert(message: "Local update failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Validation
    private func validateInputs() -> Bool {
        guard let idText = tripIDTextField.text, !idText.isEmpty else {
            showAlert(message: "Please enter Trip ID")
            return false
        }
        
        guard Int32(idText) != nil else {
            showAlert(message: "Invalid Trip ID format")
            return false
        }
        
        guard let title = tripTitleTextField.text, !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            showAlert(message: "Please enter trip title")
            return false
        }
        
        return true
    }
    
    private func validateDates(for trip: Trip) -> Bool {
        guard let startDate = trip.startDate else {
            showAlert(message: "Invalid start date")
            return false
        }
        
        let endDate = endDatePicker.date
        guard endDate >= startDate else {
            showAlert(message: "End date cannot be before \(formatDate(startDate))")
            return false
        }
        
        return true
    }
    
    private func fetchTrip(id: Int32) -> Trip? {
        let request: NSFetchRequest<Trip> = Trip.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", id)
        
        do {
            return try context.fetch(request).first
        } catch {
            showAlert(message: "Fetch error: \(error.localizedDescription)")
            return nil
        }
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
    
    // MARK: - Helpers
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func showAlert(message: String, completion: (() -> Void)? = nil) {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                completion?()
            })
            self?.present(alert, animated: true)
        }
    }
    
    private func clearFields() {
        tripIDTextField.text = ""
        tripTitleTextField.text = ""
        endDatePicker.date = Date()
    }
}
