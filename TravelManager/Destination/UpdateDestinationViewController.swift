import UIKit
import CoreData
import SystemConfiguration

class UpdateDestinationViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var cityName: UITextField!
    @IBOutlet weak var idTextField: UITextField!
    @IBOutlet weak var destinationImageView: UIImageView!
    
    var selectedImageData: Data?
    let apiURL = "https://67e3654e97fc65f535397b85.mockapi.io/api/travel/destination"
    let imgbbApiKey = "884c686bc032e5eb43069a6882155e63"
    var managedContext: NSManagedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        destinationImageView.isUserInteractionEnabled = true
        destinationImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selectImage)))
    }
    
    @IBAction private func selectImage() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true)
    }
    
    // MARK: - Image Picker Delegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            destinationImageView.image = image
            selectedImageData = image.jpegData(compressionQuality: 0.8)
        }
        dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
    
    @IBAction func updateDestinationClicked(_ sender: UIButton) {
        guard validateFields(),
              let idText = idTextField.text,
              let destinationId = Int32(idText),
              let newCity = cityName.text,
              let imageData = selectedImageData else {
            return
        }
        
        startUpdateProcess(id: destinationId, newCity: newCity, imageData: imageData)
    }
    
    // MARK: - Update Process
    private func startUpdateProcess(id: Int32, newCity: String, imageData: Data, attempt: Int = 1) {
        guard isInternetAvailable() else {
            handleOfflineCase(attempt: attempt, id: id, newCity: newCity, imageData: imageData)
            return
        }
        
        uploadImageToImgBB(imageData: imageData) { [weak self] imageUrl in
            guard let self = self else { return }
            
            if let imageUrl = imageUrl {
                self.syncWithAPI(id: id, newCity: newCity, imageUrl: imageUrl) { apiSuccess in
                    if apiSuccess {
                        self.updateLocalDestination(id: id, newCity: newCity, imageData: imageData)
                        DispatchQueue.main.async {
                            self.clearForm()
                            self.showAlert(title: "Success", message: "Updated both local and remote data")
                        }
                    } else {
                        self.handleRetry(attempt: attempt, id: id, newCity: newCity, imageData: imageData)
                    }
                }
            } else {
                self.handleRetry(attempt: attempt, id: id, newCity: newCity, imageData: imageData)
            }
        }
    }
    
    // MARK: - Network Handling
    private func handleOfflineCase(attempt: Int, id: Int32, newCity: String, imageData: Data) {
        if attempt == 1 { // Only show alert on first attempt
            showAlert(title: "Offline", message: "Internet required for updates. Connect and try again.")
        }
    }
    
    private func handleRetry(attempt: Int, id: Int32, newCity: String, imageData: Data) {
        if attempt < 3 {
            DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                self.startUpdateProcess(id: id, newCity: newCity, imageData: imageData, attempt: attempt + 1)
            }
        } else {
            DispatchQueue.main.async {
                self.showAlert(title: "Error", message: "Update failed after 3 attempts")
            }
        }
    }
    
    // MARK: - Internet Check
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
    
    // MARK: - Validation
    private func validateFields() -> Bool {
        guard let idText = idTextField.text, !idText.isEmpty,
              Int32(idText) != nil else {
            showAlert(title: "Invalid ID", message: "Please enter a valid numeric ID")
            return false
        }
        
        guard let city = cityName.text, !city.isEmpty else {
            showAlert(title: "Missing City", message: "Please enter a city name")
            return false
        }
        
        guard selectedImageData != nil else {
            showAlert(title: "Missing Image", message: "Please select a destination image")
            return false
        }
        
        return true
    }
    
    // MARK: - Image Upload
    private func uploadImageToImgBB(imageData: Data, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "https://api.imgbb.com/1/upload?key=\(imgbbApiKey)") else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let dataDict = json["data"] as? [String: Any],
                  let urlString = dataDict["url"] as? String else {
                completion(nil)
                return
            }
            completion(urlString)
        }.resume()
    }
    
    // MARK: - API Sync
    private func syncWithAPI(id: Int32, newCity: String, imageUrl: String, completion: @escaping (Bool) -> Void) {
        guard let destination = fetchLocalDestination(id: id) else {
            DispatchQueue.main.async {
                self.showAlert(title: "Error", message: "Destination not found in local database")
            }
            completion(false)
            return
        }
        
        let apiDestination = APIDestination(
            id: String(id),
            city: newCity,
            country: destination.country ?? "",
            destinationImageURL: imageUrl
        )
        
        guard let url = URL(string: "\(apiURL)/\(id)") else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(apiDestination)
            
            URLSession.shared.dataTask(with: request) { _, response, error in
                let success = error == nil && (response as? HTTPURLResponse)?.statusCode == 200
                completion(success)
            }.resume()
        } catch {
            completion(false)
        }
    }
    
    // MARK: - Core Data Operations
    private func fetchLocalDestination(id: Int32) -> Destination? {
        let fetchRequest: NSFetchRequest<Destination> = Destination.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %d", id)
        
        do {
            return try managedContext.fetch(fetchRequest).first
        } catch {
            return nil
        }
    }
    
    private func updateLocalDestination(id: Int32, newCity: String, imageData: Data) {
        guard let destination = fetchLocalDestination(id: id) else { return }
        
        do {
            destination.city = newCity
            destination.destinationImage = imageData
            try managedContext.save()
        } catch {
            print("Core Data update failed: \(error)")
        }
    }
    
    // MARK: - Helpers
    private func clearForm() {
        DispatchQueue.main.async { [weak self] in
            self?.idTextField.text = ""
            self?.cityName.text = ""
            self?.destinationImageView.image = nil
            self?.selectedImageData = nil
        }
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self?.present(alert, animated: true)
        }
    }
}

