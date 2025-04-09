import UIKit
import CoreData

class ViewActivityTableViewController: UITableViewController, UISearchBarDelegate {

    var trips = [Trip]()
    @IBOutlet weak var activitySearchBar: UISearchBar!
    var activitiesDict = [String: [Activity]]()
    var sectionTitles = [String]()
    var filteredActivitiesDict = [String: [Activity]]()
    var isSearching = false
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupSearchBar()
        loadData()
    }

    private func setupTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "LabelActivity")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.backgroundColor = .systemBackground
        tableView.tableFooterView = UIView()
    }

    private func setupSearchBar() {
        activitySearchBar.delegate = self
    }

    private func loadData() {
        let request: NSFetchRequest<Trip> = Trip.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]

        do {
            trips = try context.fetch(request)
            organizeActivitiesByTrip()
            tableView.reloadData()
        } catch {
            showErrorAlert(message: "Error fetching trips: \(error.localizedDescription)")
        }
    }

    private func organizeActivitiesByTrip() {
        activitiesDict.removeAll()
        sectionTitles.removeAll()

        for trip in trips {
            if let title = trip.title,
               let activities = trip.activity?.allObjects as? [Activity],
               !activities.isEmpty {  // Only include trips with activities
                activitiesDict[title] = activities.sorted { $0.id < $1.id }
                sectionTitles.append(title)
            }
        }
        filteredActivitiesDict = activitiesDict
    }

    // MARK: - Table View Data Source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return isSearching ? filteredActivitiesDict.count : activitiesDict.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return isSearching ? Array(filteredActivitiesDict.keys)[section] : sectionTitles[section]
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let tripTitle = isSearching ? Array(filteredActivitiesDict.keys)[section] : sectionTitles[section]
        return (isSearching ? filteredActivitiesDict[tripTitle] : activitiesDict[tripTitle])?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LabelActivity", for: indexPath)
        let tripTitle = isSearching ? Array(filteredActivitiesDict.keys)[indexPath.section] : sectionTitles[indexPath.section]
        
        if let activity = (isSearching ? filteredActivitiesDict : activitiesDict)[tripTitle]?[indexPath.row] {
            cell.textLabel?.numberOfLines = 0
            
            // Create a DateFormatter to format the date into a String
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd" // Format for the date
            
            // Convert the Date to a String for activity.date
            let formattedDate = activity.date != nil ? dateFormatter.string(from: activity.date!) : "N/A"
            
            // Create a DateFormatter to format the time into a String
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm" // Format for time
            
            // Convert the Date to a String for activity.time
            let formattedTime = activity.time != nil ? timeFormatter.string(from: activity.time!) : "N/A"
            
            // Set the cell's text label with formatted data
            cell.textLabel?.text = """
            ID: \(activity.id)
            Name: \(activity.name ?? "N/A")
            Date: \(formattedDate)
            Time: \(formattedTime)
            Location: \(activity.location ?? "N/A")
            """
        }
        
        return cell
    }

    // MARK: - Search Handling
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            isSearching = false
            filteredActivitiesDict = activitiesDict
            tableView.backgroundView = nil
        } else {
            isSearching = true
            filteredActivitiesDict = activitiesDict.mapValues { activities in
                activities.filter {
                    $0.name?.range(of: searchText, options: .caseInsensitive) != nil
                }
            }.filter { !$0.value.isEmpty }  // Remove empty sections
            
            if filteredActivitiesDict.isEmpty {
                showNoResultsView()
            } else {
                tableView.backgroundView = nil
            }
        }
        tableView.reloadData()
    }
    
    // MARK: - No Results View
    private func showNoResultsView() {
        let containerView = UIView(frame: tableView.bounds)
        
        let iconImage = UIImage(systemName: "magnifyingglass")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 44, weight: .regular))
        let iconView = UIImageView(image: iconImage)
        iconView.tintColor = .systemGray
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        let messageLabel = UILabel()
        messageLabel.text = "No Activities Found\nTry a new search"
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
        searchBar.resignFirstResponder()
        filteredActivitiesDict = activitiesDict
        tableView.backgroundView = nil
        tableView.reloadData()
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
