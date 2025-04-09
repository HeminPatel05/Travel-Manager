

import UIKit
import Network
import CoreData

class ViewTripTableViewController: UITableViewController, UISearchBarDelegate {

    @IBOutlet weak var tripSearchBar: UISearchBar!
    var trips: [Trip] = []
    var filteredTrips: [Trip] = []
    var destinations: [Destination] = []
    var isSearching = false
    let monitor = NWPathMonitor()
    let managedContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    private let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale.current
        return formatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupSearchBar()
        checkInternetConnection()
    }

    private func setupTableView() {
        tableView.backgroundColor = .systemBackground
        tableView.tableFooterView = UIView()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
    }

    private func setupSearchBar() {
        tripSearchBar.delegate = self
    }

    private func checkInternetConnection() {
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    print("Internet connection available. Fetching destinations...")
                    self.fetchDestinations()
                } else {
                    print("No internet connection. Loading data from Core Data.")
                    self.showErrorAlert(message: "No internet connection. Loading data from Core Data.")
                    self.loadTripsFromCoreData()
                }
            }
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }
    
    private func saveTripsToCoreData(_ apiTrips: [TripAPIModel], destinationId: String) {
        let fetchRequest: NSFetchRequest<Trip> = Trip.fetchRequest()
        do {
            let existingTrips = try managedContext.fetch(fetchRequest)
            // Convert destinationId (String) → Int32
            guard let destinationIDInt32 = Int32(destinationId) else {
                print("Invalid destination ID: \(destinationId)")
                return
            }
            
            for apiTrip in apiTrips {
                // Safely convert apiTrip.id (String) → Int32
                guard let tripID = Int32(apiTrip.id) else {
                    print("Invalid trip ID: \(apiTrip.id)")
                    continue
                }
                
                if !existingTrips.contains(where: { $0.id == tripID }) {
                    let newTrip = Trip(context: managedContext)
                    newTrip.id = tripID
                    newTrip.title = apiTrip.title
                    newTrip.startDate = Date(timeIntervalSince1970: TimeInterval(apiTrip.startDate))
                    newTrip.endDate = Date(timeIntervalSince1970: TimeInterval(apiTrip.endDate))
                    
                    // Find destination with matching Int32 ID
                    newTrip.destination = destinations.first { $0.id == destinationIDInt32 }
                }
            }
            try managedContext.save()
            loadTripsFromCoreData()
        } catch {
            print("Error saving trips to Core Data: \(error)")
        }
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LabelTrip", for: indexPath)
        let trip = isSearching ? filteredTrips[indexPath.row] : trips[indexPath.row]
        
        // Configure cell properties
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.numberOfLines = 0
        
        // Create date strings
        let startDate = trip.startDate?.formatted(date: .abbreviated, time: .omitted) ?? "Unknown Start"
        let endDate = trip.endDate?.formatted(date: .abbreviated, time: .omitted) ?? "Unknown End"
        
        // Create location string
        let city = trip.destination?.city ?? "Unknown City"
        let country = trip.destination?.country ?? "Unknown Country"
        
        // Configure text
        cell.textLabel?.text = """
        ID: \(trip.id)
        \(trip.title ?? "Untitled Trip")
        Dates: \(startDate) - \(endDate)
        Location: \(city), \(country)
        """
        
        return cell
    }

    private func fetchDestinations() {
        let destinationsURL = "https://67e3654e97fc65f535397b85.mockapi.io/api/travel/destination"
        guard let url = URL(string: destinationsURL) else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("Error fetching destinations: \(error)")
                DispatchQueue.main.async { self.loadTripsFromCoreData() }
                return
            }
            
            guard let data = data else { return }
            do {
                let decoder = JSONDecoder()
                let apiDestinations: [APIDestination] = try decoder.decode([APIDestination].self, from: data)
                print("Fetched destinations: \(apiDestinations.count)")
                DispatchQueue.main.async {
                    self.saveDestinationsToCoreData(apiDestinations)
                }
            } catch {
                print("Error decoding destinations JSON: \(error)")
            }
        }.resume()
    }

    private func saveDestinationsToCoreData(_ apiDestinations: [APIDestination]) {
        let fetchRequest: NSFetchRequest<Destination> = Destination.fetchRequest()
        
        do {
            let existingDestinations = try managedContext.fetch(fetchRequest)
            
            for apiDestination in apiDestinations {
                guard let idString = apiDestination.id, let id = Int32(idString) else {
                    print("Invalid ID format: \(apiDestination.id ?? "nil")")
                    continue
                }
                
                if !existingDestinations.contains(where: { $0.id == id }) {
                    let newDestination = Destination(context: managedContext)
                    newDestination.id = id
                    newDestination.city = apiDestination.city
                    newDestination.country = apiDestination.country
                    print("Saved new destination: \(newDestination.city ?? "Unknown")")
                }
            }
            try managedContext.save()
            self.fetchTripsFromAPI()
        } catch {
            print("Destination save error: \(error)")
        }
    }

    private func fetchTripsFromAPI() {
        let fetchRequest: NSFetchRequest<Destination> = Destination.fetchRequest()
        do {
            destinations = try managedContext.fetch(fetchRequest)
            for destination in destinations {
                let destinationIDString = String(destination.id)
                print("Fetching trips for destination ID: \(destinationIDString)")
                self.fetchTripsForDestination(destinationIDString)
            }
        } catch {
            print("Error loading destinations: \(error)")
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearching ? filteredTrips.count : trips.count
    }



    private func fetchTripsForDestination(_ destinationId: String) {
        let tripsURL = "https://67e3654e97fc65f535397b85.mockapi.io/api/travel/destination/\(destinationId)/trip"
        guard let url = URL(string: tripsURL) else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("Error fetching trips: \(error)")
                return
            }
            
            guard let data = data else { return }
            do {
                let decoder = JSONDecoder()
                let apiTrips = try decoder.decode([TripAPIModel].self, from: data)
                print("Fetched \(apiTrips.count) trips for destination ID: \(destinationId)")
                DispatchQueue.main.async {
                    self.saveTripsToCoreData(apiTrips, destinationId: destinationId)
                }
            } catch {
                print("Error decoding trips JSON: \(error)")
            }
        }.resume()
    }

    private func loadTripsFromCoreData() {
        let fetchRequest: NSFetchRequest<Trip> = Trip.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        do {
            trips = try managedContext.fetch(fetchRequest)
            filteredTrips = trips
            print("Loaded \(trips.count) trips from Core Data.")
            
            // Ensure UI updates on the main thread
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        } catch {
            showErrorAlert(message: "Failed to load trips: \(error.localizedDescription)")
        }
    }

}

// MARK: - UISearchBarDelegate
extension ViewTripTableViewController {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            isSearching = false
            filteredTrips = trips
        } else {
            isSearching = true
            if let searchID = Int32(searchText) { // Search by ID
                filteredTrips = trips.filter { $0.id == searchID }
            } else {
                filteredTrips = [] // If input isn't an ID, no results
            }
        }

        if filteredTrips.isEmpty {
            showNoResultsView()
        } else {
            tableView.backgroundView = nil
        }
        
        tableView.reloadData()
    }
    
    private func showNoResultsView() {
        let containerView = UIView(frame: tableView.bounds)
        
        let iconImage = UIImage(systemName: "magnifyingglass")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 44, weight: .regular))
        let iconView = UIImageView(image: iconImage)
        iconView.tintColor = .systemGray
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        let messageLabel = UILabel()
        messageLabel.text = "No Trips Found\nTry a new search"
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

    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isSearching = false
        searchBar.text = ""
        filteredTrips = trips
        tableView.reloadData()
    }
}
