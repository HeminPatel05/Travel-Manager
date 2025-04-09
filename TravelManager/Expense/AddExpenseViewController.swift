//import UIKit
//
//class AddExpenseViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
//    
//    @IBOutlet weak var tripField: UITextField!
//    @IBOutlet weak var titleField: UITextField!
//    @IBOutlet weak var amountField: UITextField!
//    @IBOutlet weak var dateField: UIDatePicker!
//    
//    private var pickerView = UIPickerView()
//    private var trips: [Trip] = []
//    private var selectedTripId: Int?
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        setupPickerView()
//        loadTrips()
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
//        view.addGestureRecognizer(tapGesture)
//    }
//    
//    
//    @objc func dismissKeyboard() {
//        view.endEditing(true)
//    }
//    
//    // MARK: - Setup PickerView for Trip Selection
//    private func setupPickerView() {
//        pickerView.delegate = self
//        pickerView.dataSource = self
//        tripField.inputView = pickerView
//        tripField.delegate = self
//        
//        // Add toolbar with a Done button
//        let toolbar = UIToolbar()
//        toolbar.sizeToFit()
//        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(donePicker))
//        toolbar.setItems([doneButton], animated: false)
//        tripField.inputAccessoryView = toolbar
//    }
//    
//    // MARK: - Load Trips from DataManager
//    private func loadTrips() {
//        trips = DataManager.shared.getAllTrips()
//    }
//    
//    @objc private func donePicker() {
//        tripField.resignFirstResponder()
//    }
//    
//    // MARK: - Add Expense Function
//    @IBAction func addExpenseButton(_ sender: Any) {
//        guard let tripId = selectedTripId else {
//            showAlert(message: "Please select a trip.")
//            return
//        }
//        guard let title = titleField.text, !title.isEmpty else {
//            showAlert(message: "Please enter an expense title.")
//            return
//        }
//        guard let amountText = amountField.text, let amount = Double(amountText), amount > 0 else {
//            showAlert(message: "Please enter a valid amount.")
//            return
//        }
//        
//        let date = formatDate(dateField.date)
//        
//        if (DataManager.shared.addExpense(tripId: tripId, title: title, amount: amount, date: date) != nil) {
//            showAlert(message: "Expense added successfully!")
//        } else {
//            showAlert(message: "Failed to add expense.")
//        }
//    }
//    
//    // MARK: - Format Date Function
//    private func formatDate(_ date: Date) -> String {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "yyyy-MM-dd"
//        return formatter.string(from: date)
//    }
//    
//    // MARK: - Show Alert Function
//    private func showAlert(message: String) {
//        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "OK", style: .default))
//        present(alert, animated: true)
//    }
//    
//    // MARK: - UIPickerView DataSource & Delegate
//    func numberOfComponents(in pickerView: UIPickerView) -> Int {
//        return 1
//    }
//    
//    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
//        return trips.count
//    }
//    
//    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
//        return trips[row].title
//    }
//    
//    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
//        let selectedTrip = trips[row]
//        tripField.text = selectedTrip.title
//        selectedTripId = Int(selectedTrip.id)
//    }
//}

import UIKit
import CoreData

class AddExpenseViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    
    @IBOutlet weak var tripField: UITextField!
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var amountField: UITextField!
    @IBOutlet weak var dateField: UIDatePicker!
    
    private var pickerView = UIPickerView()
    private var trips: [Trip] = []
    private var selectedTrip: Trip?
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPickerView()
        loadTrips()
        setupTapGesture()
    }
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Picker View Setup
    private func setupPickerView() {
        pickerView.delegate = self
        pickerView.dataSource = self
        tripField.inputView = pickerView
        tripField.delegate = self
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(donePicker))
        toolbar.setItems([doneButton], animated: false)
        tripField.inputAccessoryView = toolbar
    }
    
    // MARK: - Core Data Operations
    private func loadTrips() {
        let request: NSFetchRequest<Trip> = Trip.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        
        do {
            trips = try context.fetch(request)
        } catch {
            print("Error fetching trips: \(error)")
        }
    }
    
    private func generateExpenseID() -> Int32 {
        let request: NSFetchRequest<Expense> = Expense.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        request.fetchLimit = 1
        
        do {
            let lastExpense = try context.fetch(request).first
            return (lastExpense?.id ?? 0) + 1
        } catch {
            print("Error generating ID: \(error)")
            return 1
        }
    }
    
    // MARK: - Button Action
    @IBAction func addExpenseButton(_ sender: Any) {
        guard validateInputs() else { return }
        
        let newExpense = Expense(context: context)
        newExpense.id = generateExpenseID()
        newExpense.title = titleField.text
        newExpense.amount = Double(amountField.text!) ?? 0.0
        newExpense.date = dateField.date
        newExpense.trip = selectedTrip
        
        saveExpense()
    }
    
    private func validateInputs() -> Bool {
        guard selectedTrip != nil else {
            showAlert("Please select a trip")
            return false
        }
        
        guard let title = titleField.text, !title.isEmpty else {
            showAlert("Please enter expense title")
            return false
        }
        
        guard let amountText = amountField.text,
              let amount = Double(amountText), amount > 0 else {
            showAlert("Please enter valid amount")
            return false
        }
        
        return true
    }
    
    private func saveExpense() {
        do {
            try context.save()
            showAlert("Expense added successfully!") {
                self.clearFields()
            }
        } catch {
            showAlert("Failed to save expense: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Helper Methods
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func showAlert(_ message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
    
    private func clearFields() {
        tripField.text = ""
        titleField.text = ""
        amountField.text = ""
        dateField.date = Date()
        selectedTrip = nil
    }
    
    // MARK: - Picker View Methods
    func numberOfComponents(in pickerView: UIPickerView) -> Int { return 1 }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return trips.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return trips[row].title
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedTrip = trips[row]
        tripField.text = trips[row].title
    }
    
    @objc private func donePicker() {
        tripField.resignFirstResponder()
    }
}
