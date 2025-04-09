import UIKit
import CoreData
import SystemConfiguration

class AddDestinationViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var cityName: UITextField!
    @IBOutlet weak var countryName: UITextField!
    @IBOutlet weak var destinationImage: UIImageView!
    
    var selectedImageData: Data?
    let apiUrl = "https://67e3654e97fc65f535397b85.mockapi.io/api/travel/destination"
    let imgbbApiKey = "884c686bc032e5eb43069a6882155e63"
    var managedContext: NSManagedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Add Destination"
        setupUI()
    }
    
    private func setupUI() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        destinationImage.isUserInteractionEnabled = true
        destinationImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selectImageClicked)))
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @IBAction func selectImageClicked(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true)
    }
    
    // MARK: - Image Picker Delegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            destinationImage.image = image
            selectedImageData = image.jpegData(compressionQuality: 0.8)
        }
        dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
    
    @IBAction func addDestinationClicked(_ sender: UIButton) {
        guard isInternetAvailable() else {
            showAlert(title: "Offline", message: "Please connect to the internet to add destinations")
            return
        }
        
        guard validateFields(),
              let city = cityName.text,
              let country = countryName.text,
              let imageData = selectedImageData else {
            return
        }
        
        startUploadProcess(city: city, country: country, imageData: imageData)
    }
    
    // MARK: - Upload Process
    private func startUploadProcess(city: String, country: String, imageData: Data, attempt: Int = 1) {
        uploadImageToImgBB(imageData: imageData) { [weak self] uploadedUrl in
            guard let self = self else { return }
            
            if let url = uploadedUrl {
                self.syncWithAPI(city: city, country: country, imageUrl: url) { apiId in
                    DispatchQueue.main.async {
                        if let id = apiId, self.saveToCoreData(id: id, city: city, country: country, imageData: imageData) {
                            self.clearForm()
                            self.showAlert(title: "Success", message: "Destination added successfully!")
                        }
                    }
                }
            } else if attempt < 3 {
                DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                    self.startUploadProcess(city: city, country: country, imageData: imageData, attempt: attempt + 1)
                }
            } else {
                DispatchQueue.main.async {
                    self.showAlert(title: "Error", message: "Could not add destination. Please try again later.")
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
        }) else { return false }
        
        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return false
        }
        
        return flags.contains(.reachable) && !flags.contains(.connectionRequired)
    }
    
    // MARK: - Validation
    private func validateFields() -> Bool {
        guard let city = cityName.text, !city.isEmpty else {
            showAlert(title: "Missing Info", message: "Please enter a city name")
            return false
        }
        
        guard let country = countryName.text, !country.isEmpty else {
            showAlert(title: "Missing Info", message: "Please enter a country name")
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
        let url = URL(string: "https://api.imgbb.com/1/upload?key=\(imgbbApiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
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
    private func syncWithAPI(city: String, country: String, imageUrl: String, completion: @escaping (Int32?) -> Void) {
        guard let url = URL(string: apiUrl) else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let newDestination = APIDestination(id: nil, city: city, country: country, destinationImageURL: imageUrl)
        
        do {
            request.httpBody = try JSONEncoder().encode(newDestination)
            
            URLSession.shared.dataTask(with: request) { data, _, _ in
                guard let data = data,
                      let response = try? JSONDecoder().decode(APIDestination.self, from: data),
                      let idString = response.id,
                      let apiId = Int32(idString) else {
                    completion(nil)
                    return
                }
                completion(apiId)
            }.resume()
        } catch {
            completion(nil)
        }
    }
    
    // MARK: - Core Data
    private func saveToCoreData(id: Int32, city: String, country: String, imageData: Data) -> Bool {
        let newDestination = Destination(context: managedContext)
        newDestination.id = id
        newDestination.city = city
        newDestination.country = country
        newDestination.destinationImage = imageData
        
        do {
            try managedContext.save()
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Helpers
    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    private func clearForm() {
        DispatchQueue.main.async { [weak self] in
            self?.cityName.text = ""
            self?.countryName.text = ""
            self?.destinationImage.image = nil
            self?.selectedImageData = nil
        }
    }
}

