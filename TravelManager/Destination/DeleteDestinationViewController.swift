import UIKit
import CoreData
import SystemConfiguration

class DeleteDestinationViewController: UIViewController {
    
    @IBOutlet weak var idTextField: UITextField!
    let apiURL = "https://67e3654e97fc65f535397b85.mockapi.io/api/travel/destination"
    var managedContext: NSManagedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDismissKeyboard()
    }
    
    @IBAction func deleteDestinationClicked(_ sender: UIButton) {
        guard isInternetAvailable() else {
            showAlert(title: "Error", message: "Internet connection required for deletion.")
            return
        }
        
        guard let idText = idTextField.text, !idText.isEmpty,
              let destinationId = Int32(idText) else {
            showAlert(title: "Error", message: "Please enter a valid destination ID.")
            return
        }
        
        if deleteFromCoreData(id: destinationId) {
            deleteFromAPI(id: idText) { [weak self] success in
                DispatchQueue.main.async {
                    if success {
                        self?.showAlert(title: "Success", message: "Deleted from both local and remote") {
                            self?.navigationController?.popViewController(animated: true)
                        }
                    } else {
                        self?.showAlert(title: "Warning", message: "Deleted locally but failed to delete from server.")
                    }
                }
            }
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
        }) else {
            return false
        }
        
        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return false
        }
        
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        return (isReachable && !needsConnection)
    }
    
    // MARK: - Core Data Operations
    private func deleteFromCoreData(id: Int32) -> Bool {
        let fetchRequest: NSFetchRequest<Destination> = Destination.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %d", id)
        
        do {
            let results = try managedContext.fetch(fetchRequest)
            guard let destination = results.first else {
                showAlert(title: "Error", message: "Destination not found.")
                return false
            }
            
            if let trips = destination.trip, trips.count > 0 {
                showAlert(title: "Error", message: "Cannot delete - \(trips.count) associated trips exist.")
                return false
            }
            
            managedContext.delete(destination)
            try managedContext.save()
            return true
            
        } catch {
            showAlert(title: "Error", message: "Core Data delete failed: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - API Communication
    private func deleteFromAPI(id: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(apiURL)/\(id)") else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            let success: Bool
            if let httpResponse = response as? HTTPURLResponse {
                success = (200...299).contains(httpResponse.statusCode)
            } else {
                success = false
            }
            completion(success)
        }.resume()
    }
    
    // MARK: - UI Helpers
    private func setupDismissKeyboard() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
}
