import UIKit
import CoreData

class ViewExpensesTableViewController: UITableViewController {
    
    var trips = [Trip]()
    var expensesDict = [String: [Expense]]()
    var sectionTitles = [String]()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
    }
    
    private func setupTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "expenseCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
    }
    
    private func loadData() {
        let tripRequest: NSFetchRequest<Trip> = Trip.fetchRequest()
        tripRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        
        do {
            trips = try context.fetch(tripRequest)
            organizeExpenses()
            tableView.reloadData()
        } catch {
            print("Error fetching trips: \(error)")
        }
    }
    
    private func organizeExpenses() {
        expensesDict.removeAll()
        sectionTitles.removeAll()
        
        for trip in trips {
            if let title = trip.title,
               let expenses = trip.expense?.allObjects as? [Expense],
               !expenses.isEmpty {
                
                // Sort expenses safely using nil-coalescing operator with Date.distantPast
                expensesDict[title] = expenses.sorted { ($0.date ?? Date.distantPast) < ($1.date ?? Date.distantPast) }
                
                sectionTitles.append(title)
            }
        }
        sectionTitles.sort()
    }

    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sectionTitles.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let tripTitle = sectionTitles[section]
        return expensesDict[tripTitle]?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "expenseCell", for: indexPath)
        let tripTitle = sectionTitles[indexPath.section]
        
        if let expense = expensesDict[tripTitle]?[indexPath.row] {
            cell.textLabel?.numberOfLines = 0

            // Create a DateFormatter to format the Date into a String
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd" // Adjust format as needed
            
            // Convert expense.date (Date) to a formatted String
            let formattedDate = expense.date != nil ? dateFormatter.string(from: expense.date!) : "N/A"

            // Set cell text with formatted values
            cell.textLabel?.text = """
            ID: \(expense.id)
            Title: \(expense.title ?? "N/A")
            Amount: $\(String(format: "%.2f", expense.amount))
            Date: \(formattedDate)
            """
        }
        
        return cell
    }
}
