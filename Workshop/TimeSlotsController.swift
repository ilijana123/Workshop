import UIKit
import FirebaseDatabase
import FirebaseAuth

class TimeSlotsController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var slotsTableView: UITableView!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    var sellerId: String?
    var apartmentId: String?
    var imageUrl: String?
    var price: String?
    var phone: String?
    var squareMeters: String?
    var numberOfRooms: String?
    var locationName: String?
    var latitude: String?
    var longitude: String?
    var timeSlots: [String: [String: Bool]] = [:]
    var apartmentDetails: [String: Any] = [:]
    var selectedSlots: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        generateWorkingDays()
        setupTableView()
    }

    // MARK: - Generate Working Days (without slots)
        func generateWorkingDays() {
            let calendar = Calendar.current
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"

            var currentDate = Date()
            var workingDaysCount = 0

            while workingDaysCount < 5 {
                let weekday = calendar.component(.weekday, from: currentDate)
                if weekday != 1 && weekday != 7 {
                    let dateKey = formatter.string(from: currentDate)
                    timeSlots[dateKey] = [:]
                    workingDaysCount += 1
                }
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            }
        }
    // MARK: - Add Time Slots
    @IBAction func addTimeSlotTapped(_ sender: Any) {
        // Check if the total number of slots exceeds the limit
        if selectedSlots.count >= 8 {
            displayAlert(title: "Limit Reached", message: "You can only add up to 8 time slots.")
            return
        }
        
        let alert = UIAlertController(title: "Add Time Slot", message: nil, preferredStyle: .alert)
        let timePicker = UIDatePicker()
        timePicker.datePickerMode = .time
        timePicker.preferredDatePickerStyle = .wheels
        timePicker.translatesAutoresizingMaskIntoConstraints = false
        alert.view.addSubview(timePicker)
        
        NSLayoutConstraint.activate([
            timePicker.leadingAnchor.constraint(equalTo: alert.view.leadingAnchor, constant: 20),
            timePicker.trailingAnchor.constraint(equalTo: alert.view.trailingAnchor, constant: -20),
            timePicker.topAnchor.constraint(equalTo: alert.view.topAnchor, constant: 60),
            timePicker.bottomAnchor.constraint(equalTo: alert.view.bottomAnchor, constant: -100)
        ])
        
        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { [weak self] _ in
            guard let strongSelf = self else { return }
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            let selectedTime = formatter.string(from: timePicker.date)
            if strongSelf.selectedSlots.contains(selectedTime) {
                strongSelf.displayAlert(title: "Error", message: "Time slot already exists.")
                return
            }
            
            strongSelf.selectedSlots.append(selectedTime)
            strongSelf.applySlotsToAllDays()
            strongSelf.slotsTableView.reloadData()
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true)
    }



        func applySlotsToAllDays() {
            for dateKey in timeSlots.keys {
                timeSlots[dateKey] = [:]
                for slot in selectedSlots {
                    timeSlots[dateKey]?[slot] = true
                }
            }
        }

        func isValidTimeFormat(_ time: String) -> Bool {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            return timeFormatter.date(from: time) != nil
        }

    // MARK: - Update Slots for Today
    func updateSlots() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let calendar = Calendar.current
        let currentDate = Date()
        let todayDateString = formatter.string(from: currentDate)
        let startOfTomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: currentDate)!)
        if currentDate >= startOfTomorrow {
            updateSlotsForNextDay(todayDateString: todayDateString)
        } else {
            deactivatePastTimeSlots(todayDateString: todayDateString)
        }
    }

    func updateSlotsForNextDay(todayDateString: String) {
        guard let today = timeSlots.keys.sorted().first(where: { $0 == todayDateString }) else { return }
        let nextWorkingDay = getNextWorkingDay(from: today)

        if let todaySlots = timeSlots[today] {
            timeSlots.removeValue(forKey: today)
            timeSlots[nextWorkingDay] = todaySlots
        }
    }

    func deactivatePastTimeSlots(todayDateString: String) {
        guard var todaySlots = timeSlots[todayDateString] else { return }
        
        let currentTime = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        for (time, isActive) in todaySlots {
            if let slotTime = formatter.date(from: time), slotTime < currentTime {
                todaySlots[time] = false
            }
        }
        timeSlots[todayDateString] = todaySlots
    }

    func getNextWorkingDay(from date: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let currentDate = formatter.date(from: date) else { return date }
        let calendar = Calendar.current
        var nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!

        while calendar.component(.weekday, from: nextDate) == 1 || calendar.component(.weekday, from: nextDate) == 7 {
            nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate)!
        }

        return formatter.string(from: nextDate)
    }


    // MARK: - TableView Setup
    func setupTableView() {
        slotsTableView.dataSource = self
        slotsTableView.delegate = self
        slotsTableView.reloadData()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return timeSlots.keys.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Array(timeSlots.keys.sorted())[section]
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let dateKey = Array(timeSlots.keys.sorted())[section]
        return timeSlots[dateKey]?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SlotCell", for: indexPath)
        
        let dateKey = Array(timeSlots.keys.sorted())[indexPath.section]
        let timeKey = Array(timeSlots[dateKey]!.keys.sorted())[indexPath.row]
        let isActive = timeSlots[dateKey]?[timeKey] ?? false

        cell.textLabel?.text = timeKey

        let toggleSwitch = UISwitch()
        toggleSwitch.isOn = isActive
        toggleSwitch.tag = indexPath.row
        toggleSwitch.isEnabled = !(Calendar.current.isDateInToday(Date()) && !isActive)
        toggleSwitch.addTarget(self, action: #selector(toggleSlot(_:)), for: .valueChanged)
        cell.accessoryView = toggleSwitch

        return cell
    }

    @objc func toggleSlot(_ sender: UISwitch) {
        let point = sender.convert(CGPoint.zero, to: slotsTableView)
        guard let indexPath = slotsTableView.indexPathForRow(at: point) else { return }

        let dateKey = Array(timeSlots.keys.sorted())[indexPath.section]
        let timeKey = Array(timeSlots[dateKey]!.keys.sorted())[indexPath.row]

        if Calendar.current.isDateInToday(Date()) && !(timeSlots[dateKey]?[timeKey] ?? false) {
            displayAlert(title: "Error", message: "Cannot activate past slots for today.")
            sender.isOn = false
            return
        }

        timeSlots[dateKey]?[timeKey] = sender.isOn
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let dateKey = Array(timeSlots.keys.sorted())[indexPath.section]
            let timeKey = Array(timeSlots[dateKey]!.keys.sorted())[indexPath.row]
            timeSlots[dateKey]?.removeValue(forKey: timeKey)
            if timeSlots[dateKey]?.isEmpty == true {
                timeSlots.removeValue(forKey: dateKey)
            }
            tableView.reloadData()
        }
    }

    // MARK: - Save Data
    @IBAction func saveApartmentData(_ sender: UIBarButtonItem) {
        guard let sellerId = Auth.auth().currentUser?.uid else {
            displayAlert(title: "Error", message: "You must be logged in to save data.")
            return
        }

        guard let apartmentId = apartmentId else {
            displayAlert(title: "Error", message: "Invalid apartment ID.")
            return
        }

        let apartmentData: [String: Any] = [
            "apartmentId": apartmentId,
            "sellerId": sellerId,
            "price": price ?? "N/A",
            "numberOfRooms": numberOfRooms ?? "N/A",
            "phone": phone ?? "N/A",
            "squareMeters": squareMeters ?? "N/A",
            "locationName": locationName ?? "N/A",
            "latitude": latitude ?? "N/A",
            "longitude": longitude ?? "N/A",
            "timeSlots": timeSlots
        ]

        let dbRef = Database.database().reference().child("apartments").child(apartmentId)
        dbRef.setValue(apartmentData) { error, _ in
            if let error = error {
                self.displayAlert(title: "Error", message: "Failed to save apartment details.")
            } else {
                self.displayAlert(title: "Success", message: "Apartment data has been saved.")
            }
        }
    }

    func displayAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true)
    }
    @IBAction func logoutTapped(_ sender: Any) {
        do {
            try Auth.auth().signOut()
            
            if let sceneDelegate = UIApplication.shared.connectedScenes
                .first?.delegate as? SceneDelegate,
               let window = sceneDelegate.window {
                
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let loginVC = storyboard.instantiateViewController(withIdentifier: "ViewController")
                window.rootViewController = loginVC
                window.makeKeyAndVisible()
            }
            
        } catch let signOutError as NSError {
            print("Error signing out: \(signOutError.localizedDescription)")
        }
    }
}

