import UIKit
import CoreData
import Network

class ViewController: UIViewController, UISearchBarDelegate {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var filteredDestinations: [Destination] = []
    var filteredTrips: [Trip] = []
    var filteredActivities: [Activity] = []
    var isEmptySearchResults: Bool = false
    
    private let monitor = NWPathMonitor()
    private let apiURL = "https://67e3654e97fc65f535397b85.mockapi.io/api/travel/destination"
    private var destinationsToProcess = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTapGesture()
        checkNetworkConnection()
    }

    // MARK: - Network Handling
    private func checkNetworkConnection() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    self?.fetchDestinationsFromAPI()
                } else {
                    self?.loadExistingDataAndGenerateDummies()
                }
            }
        }
        monitor.start(queue: DispatchQueue.global(qos: .background))
    }

    // MARK: - API Operations
    private func fetchDestinationsFromAPI() {
        guard let url = URL(string: apiURL) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("API Error: \(error.localizedDescription)")
                self.loadExistingDataAndGenerateDummies()
                return
            }
            
            guard let data = data else {
                self.loadExistingDataAndGenerateDummies()
                return
            }
            
            do {
                let apiDestinations = try JSONDecoder().decode([APIDestination].self, from: data)
                self.processAPIDestinations(apiDestinations)
            } catch {
                print("Decoding Error: \(error)")
                self.loadExistingDataAndGenerateDummies()
            }
        }.resume()
    }

    private func processAPIDestinations(_ apiDestinations: [APIDestination]) {
        context.perform { [weak self] in
            guard let self = self else { return }
            
            let existingDestinations = try? self.context.fetch(Destination.fetchRequest())
            
            for apiDest in apiDestinations {
                guard let id = Int32(apiDest.id ?? "") else { continue }
                
                let destination = existingDestinations?.first { $0.id == id } ?? Destination(context: self.context)
                destination.id = id
                destination.city = apiDest.city
                destination.country = apiDest.country
                
                if destination.destinationImage == nil,
                   let imageUrl = URL(string: apiDest.destinationImageURL) {
                    self.downloadImage(url: imageUrl) { imageData in
                        destination.destinationImage = imageData
                    }
                }
                
                // Fetch trips for this destination
                self.fetchTripsForDestination(destinationID: String(id))
            }
            
            try? self.context.save()
        }
    }

    private func fetchTripsForDestination(destinationID: String) {
        let tripsURL = "\(apiURL)/\(destinationID)/trip"
        guard let url = URL(string: tripsURL) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Trip Fetch Error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else { return }
            
            do {
                let apiTrips = try JSONDecoder().decode([TripAPIModel].self, from: data)
                self.processAPITrips(apiTrips, destinationID: destinationID)
            } catch {
                print("Trip Decoding Error: \(error)")
            }
        }.resume()
    }

    private func processAPITrips(_ apiTrips: [TripAPIModel], destinationID: String) {
        context.perform { [weak self] in
            guard let self = self,
                  let destinationID = Int32(destinationID),
                  let destination = try? self.context.fetch(Destination.fetchRequest())
                    .first(where: { $0.id == destinationID }) else { return }
            
            let existingTrips = try? self.context.fetch(Trip.fetchRequest())
            
            for apiTrip in apiTrips {
                guard let tripID = Int32(apiTrip.id) else { continue }
                
                let trip = existingTrips?.first { $0.id == tripID } ?? Trip(context: self.context)
                trip.id = tripID
                trip.title = apiTrip.title
                trip.startDate = Date(timeIntervalSince1970: TimeInterval(apiTrip.startDate))
                trip.endDate = Date(timeIntervalSince1970: TimeInterval(apiTrip.endDate))
                trip.destination = destination
            }
            
            try? self.context.save()
            self.generateDummyActivitiesAndExpenses()
        }
    }

    // MARK: - Core Data Operations
    private func loadExistingDataAndGenerateDummies() {
        let tripRequest: NSFetchRequest<Trip> = Trip.fetchRequest()
        
        do {
            let trips = try context.fetch(tripRequest)
            if !trips.isEmpty {
                generateDummyActivitiesAndExpenses()
            }
        } catch {
            print("Core Data Fetch Error: \(error)")
        }
    }

    // MARK: - Dummy Data Generation
    private func generateDummyActivitiesAndExpenses() {
        context.perform { [weak self] in
            guard let self = self else { return }
            
            guard let trips = try? self.context.fetch(Trip.fetchRequest()),
                  !trips.isEmpty else {
                print("No trips available for dummy data")
                return
            }
            
            // Generate 5 Activities
            for i in 1...5 {
                let activity = Activity(context: self.context)
                activity.id = self.getNextActivityID()
                activity.name = "Team Meeting \(i)"
                activity.location = ["Conference Room", "Client Office", "Workshop", "Field Visit", "Training Center"][i % 5]
                activity.date = Calendar.current.date(byAdding: .day, value: -i, to: Date())
                activity.time = Calendar.current.date(byAdding: .hour, value: 9 + i, to: Date())
                
                if let trip = trips[safe: i % trips.count] {
                    activity.trip = trip
                }
            }
            
            // Generate 5 Expenses
            for i in 1...5 {
                let expense = Expense(context: self.context)
                expense.id = self.getNextExpenseID()
                expense.title = ["Transport", "Lunch", "Materials", "Accommodation", "Parking"][i % 5]
                expense.amount = Double(i) * 50.0 + Double(i % 3) * 15.0
                expense.date = Calendar.current.date(byAdding: .day, value: -i, to: Date())
                
                if let trip = trips[safe: i % trips.count] {
                    expense.trip = trip
                }
            }
            
            self.saveContext(self.context)
        }
    }

    private func getNextActivityID() -> Int32 {
        let request: NSFetchRequest<Activity> = Activity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        return (try! context.fetch(request).first?.id ?? 0) + 1
    }

    private func getNextExpenseID() -> Int32 {
        let request: NSFetchRequest<Expense> = Expense.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        return (try! context.fetch(request).first?.id ?? 0) + 1
    }

    // MARK: - Helper Methods
    private func downloadImage(url: URL, completion: @escaping (Data?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, _, _ in
            completion(data)
        }.resume()
    }

    private func saveContext(_ context: NSManagedObjectContext) {
        do {
            try context.save()
            print("Successfully saved context")
        } catch {
            print("Error saving context: \(error)")
            context.rollback()
        }
    }

    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}


// MARK: - Array Extension
extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
