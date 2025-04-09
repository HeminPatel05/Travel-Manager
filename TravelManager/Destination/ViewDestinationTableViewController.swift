import UIKit
import CoreData
import Network

// MARK: - Custom Table View Cell
class DestinationCell: UITableViewCell {
    static let reuseIdentifier = "DestinationCell"
    
    private let idLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = .systemGray
        return label
    }()
    
    private let cityLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        return label
    }()
    
    private let countryLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let destinationImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 8
        iv.backgroundColor = .systemGray5
        return iv
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLayout() {
        let textStack = UIStackView(arrangedSubviews: [idLabel, cityLabel, countryLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        
        let mainStack = UIStackView(arrangedSubviews: [destinationImageView, textStack])
        mainStack.axis = .horizontal
        mainStack.spacing = 16
        mainStack.alignment = .center
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            destinationImageView.widthAnchor.constraint(equalToConstant: 60),
            destinationImageView.heightAnchor.constraint(equalToConstant: 60),
            
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    func configure(with destination: Destination) {
        idLabel.text = "ID: \(destination.id)"
        cityLabel.text = destination.city ?? "Unknown City"
        countryLabel.text = destination.country ?? "Unknown Country"
        
        if let imageData = destination.destinationImage {
            destinationImageView.image = UIImage(data: imageData)
        } else {
            destinationImageView.image = UIImage(systemName: "photo")
            destinationImageView.tintColor = .systemGray3
        }
    }
}

// MARK: - Main View Controller
class ViewDestinationTableViewController: UITableViewController, UISearchBarDelegate {
    
    var destinations = [Destination]()
    var filteredDestinations = [Destination]()
    var isSearching = false
    
    private let apiURL = "https://67e3654e97fc65f535397b85.mockapi.io/api/travel/destination"
    private let managedContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    private let imageCache = NSCache<NSString, UIImage>()
    
    @IBOutlet weak var destinationSearchBar: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupSearchBar()
        checkNetworkAndLoadData()
    }
    
    private func setupTableView() {
        tableView.register(DestinationCell.self, forCellReuseIdentifier: DestinationCell.reuseIdentifier)
        tableView.rowHeight = 80
        tableView.keyboardDismissMode = .onDrag
    }
    
    private func setupSearchBar() {
        destinationSearchBar.delegate = self
        destinationSearchBar.placeholder = "Search destinations..."
    }
    
    // MARK: - Network Handling
    private func checkNetworkAndLoadData() {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue.global(qos: .utility)
        
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    self?.fetchFromAPIAndSync()
                } else {
                    self?.showNetworkAlert()
                    self?.loadFromCoreData()
                }
                monitor.cancel()
            }
        }
        monitor.start(queue: queue)
    }
    
    private func fetchFromAPIAndSync() {
        guard let url = URL(string: apiURL) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("API Error: \(error)")
                self.loadFromCoreData()
                return
            }
            
            guard let data = data else {
                self.loadFromCoreData()
                return
            }
            
            do {
                let apiDestinations = try JSONDecoder().decode([APIDestination].self, from: data)
                self.processAPIResponse(apiDestinations)
            } catch {
                print("Decoding Error: \(error)")
                self.loadFromCoreData()
            }
        }.resume()
    }
    
    // MARK: - Core Data Operations
    private func processAPIResponse(_ apiDestinations: [APIDestination]) {
        managedContext.perform { [weak self] in
            guard let self = self else { return }
            
            let fetchRequest: NSFetchRequest<Destination> = Destination.fetchRequest()
            do {
                let existingDestinations = try self.managedContext.fetch(fetchRequest)
                let dispatchGroup = DispatchGroup()
                
                for apiDest in apiDestinations {
                    guard let idString = apiDest.id,
                          let id = Int32(idString) else {
                        continue
                    }
                    
                    let destination = existingDestinations.first { $0.id == id } ?? Destination(context: self.managedContext)
                    destination.id = id
                    destination.city = apiDest.city
                    destination.country = apiDest.country
                    
                    if destination.destinationImage == nil,
                       let imageUrl = URL(string: apiDest.destinationImageURL) {
                        dispatchGroup.enter()
                        self.downloadImage(url: imageUrl) { imageData in
                            destination.destinationImage = imageData
                            dispatchGroup.leave()
                        }
                    }
                }
                
                dispatchGroup.notify(queue: .main) {
                    self.saveContextAndReload()
                }
                
            } catch {
                print("Core Data Fetch Error: \(error)")
                self.loadFromCoreData()
            }
        }
    }
    
    private func downloadImage(url: URL, completion: @escaping (Data?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            
            if let image = UIImage(data: data) {
                completion(image.jpegData(compressionQuality: 0.7))
            } else {
                completion(nil)
            }
        }.resume()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if filteredDestinations.isEmpty {
            showNoResultsView()
        } else {
            tableView.backgroundView = nil
        }
        return filteredDestinations.count
    }
    
    private func saveContextAndReload() {
        do {
            try managedContext.save()
            loadFromCoreData()
        } catch {
            print("Core Data Save Error: \(error)")
            loadFromCoreData()
        }
    }
    
    private func loadFromCoreData() {
        let fetchRequest: NSFetchRequest<Destination> = Destination.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        
        do {
            destinations = try managedContext.fetch(fetchRequest)
            filteredDestinations = destinations
            
            // Update UI on main thread
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.tableView.backgroundView = nil
            }
        } catch {
            print("Core Data Load Error: \(error)")
        }
    }
    
    // MARK: - UI Helpers
    private func showNetworkAlert() {
        let alert = UIAlertController(
            title: "Offline Mode",
            message: "Showing locally saved destinations",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Search Bar Delegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            isSearching = false
            filteredDestinations = destinations
        } else {
            isSearching = true
            filteredDestinations = destinations.filter {
                $0.city?.localizedCaseInsensitiveContains(searchText) == true ||
                $0.country?.localizedCaseInsensitiveContains(searchText) == true
            }
        }

        if filteredDestinations.isEmpty {
            showNoResultsView()
        } else {
            tableView.backgroundView = nil
        }

        tableView.reloadData()
    }

    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.text = ""
        isSearching = false
        filteredDestinations = destinations
        tableView.reloadData()
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: DestinationCell.reuseIdentifier,
            for: indexPath
        ) as? DestinationCell else {
            return UITableViewCell()
        }
        
        let destination = filteredDestinations[indexPath.row]
        cell.configure(with: destination)
        return cell
    }
    
    private func showNoResultsView() {
        let containerView = UIView(frame: tableView.bounds)
        
        let iconImage = UIImage(systemName: "magnifyingglass")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 44, weight: .regular))
        let iconView = UIImageView(image: iconImage)
        iconView.tintColor = .systemGray
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        let messageLabel = UILabel()
        messageLabel.text = "No Destination Found\nTry a new search"
        messageLabel.textColor = .systemGray
        messageLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 2
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = UIStackView(arrangedSubviews: [iconView, messageLabel])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 44),
            iconView.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        tableView.backgroundView = containerView
    }
    
    

}

// MARK: - API Data Model

