import UIKit
import CoreData
import SystemConfiguration

class DeleteTripViewController: UIViewController {
    
    @IBOutlet weak var tripID: UITextField!
    private var currentTripID: Int32 = 0
    private var currentApiUrl: String = ""
    
    private let managedContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDismissKeyboard()
    }
    
    private func setupDismissKeyboard() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @IBAction func deleteTripButtonTapped(_ sender: Any) {
        guard isInternetAvailable() else {
            showAlert(message: "Internet connection required for deletion")
            return
        }
        
        guard validateInput(), let tripIDText = tripID.text, let tripID = Int32(tripIDText) else {
            showAlert(message: "Please enter a valid Trip ID")
            return
        }
        
        currentTripID = tripID
        startDeleteProcess(attempt: 1)
    }
    
    // MARK: - Delete Process
    private func startDeleteProcess(attempt: Int) {
        guard let trip = fetchLocalTrip() else {
            showAlert(message: "Trip not found locally")
            return
        }
        
        guard validateDeletionRules(trip: trip) else { return }
        
        guard let destinationID = trip.destination?.id else {
            showAlert(message: "Missing destination reference")
            return
        }
        
        currentApiUrl = "https://67e3654e97fc65f535397b85.mockapi.io/api/travel/destination/\(destinationID)/trip/\(currentTripID)"
        
        deleteFromAPI(attempt: attempt) { [weak self] apiSuccess in
            guard let self = self else { return }
            
            if apiSuccess {
                self.deleteFromCoreData(trip: trip)
                DispatchQueue.main.async {
                    self.showAlert(message: "Trip deleted successfully") {
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            } else if attempt < 3 {
                DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                    self.startDeleteProcess(attempt: attempt + 1)
                }
            } else {
                DispatchQueue.main.async {
                    self.showAlert(message: "Failed after 3 attempts")
                }
            }
        }
    }
    
    // MARK: - API Deletion
    private func deleteFromAPI(attempt: Int, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: currentApiUrl) else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            let success = error == nil && (response as? HTTPURLResponse)?.statusCode == 200
            completion(success)
        }.resume()
    }
    
    // MARK: - Core Data Operations
    private func fetchLocalTrip() -> Trip? {
        let fetchRequest: NSFetchRequest<Trip> = Trip.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %d", currentTripID)
        
        do {
            return try managedContext.fetch(fetchRequest).first
        } catch {
            showAlert(message: "Local fetch error: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func deleteFromCoreData(trip: Trip) {
        managedContext.delete(trip)
        do {
            try managedContext.save()
        } catch {
            showAlert(message: "Local delete error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Validation
    private func validateInput() -> Bool {
        return !(tripID.text?.isEmpty ?? true)
    }
    
    private func validateDeletionRules(trip: Trip) -> Bool {
        guard trip.activity?.count == 0 else {
            showAlert(message: "Cannot delete trip with activities")
            return false
        }
        
        guard trip.expense?.count == 0 else {
            showAlert(message: "Cannot delete trip with expenses")
            return false
        }
        
        guard let startDate = trip.startDate, startDate > Date() else {
            showAlert(message: "Cannot delete started trips")
            return false
        }
        
        return true
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
