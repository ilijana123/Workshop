import UIKit
import FirebaseDatabase
import FirebaseAuth
import UserNotifications
import FirebaseStorage

class ApartmentDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UNUserNotificationCenterDelegate {
    
    var apartments: [Apartment] = []
    var currentIndex: Int = 0
    var dbRef: DatabaseReference!
    var selectedTimeSlot: (String, String)?
    
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var squareMetersLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var phoneNumberLabel: UILabel!
    @IBOutlet weak var advertiserNameLabel: UILabel!
    @IBOutlet weak var numberOfRoomsLabel: UILabel!
    @IBOutlet weak var timeSlotsTableView: UITableView!
    @IBOutlet weak var bookButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Received Apartments: \(apartments)")
        print("Current Index: \(currentIndex)")
        setupSwipeGestures()
        dbRef = Database.database().reference()
        imageView.isUserInteractionEnabled = true
        
        guard !apartments.isEmpty else {
            showAlert(title: "No Apartments Available", message: "There are no apartments to display. Please try again later.")
            return
        }

        timeSlotsTableView.dataSource = self
        timeSlotsTableView.delegate = self
        setupUI(for: currentIndex)

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted.")
            } else if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
        }

        UNUserNotificationCenter.current().delegate = self
    }

    @IBAction func bookButtonTapped(_ sender: UIButton) {
        guard let (date, time) = selectedTimeSlot else {
            showAlert(title: "Error", message: "Please select an active time slot.")
            return
        }

        guard let buyerId = getCurrentUserId() else {
            showAlert(title: "Error", message: "You must be logged in to book a time slot.")
            return
        }
        
        let bookingId = UUID().uuidString

        let bookingData: [String: Any] = [
            "bookingId": bookingId,
            "apartmentId": apartments[currentIndex].apartmentId,
            "sellerId": apartments[currentIndex].sellerId,
            "buyerId": buyerId,
            "timeSlot": "\(date) \(time)",
            "visited": false,
            "ratingSeller": 0,
            "ratingApartment": 0,
            "sellerDecision": "pending"
        ]

        dbRef.child("bookings").child(bookingId).setValue(bookingData) { error, _ in
            if let error = error {
                self.showAlert(title: "Error", message: "Failed to book the time slot: \(error.localizedDescription)")
            } else {
                self.notifySeller(sellerId: self.apartments[self.currentIndex].sellerId, bookingId: bookingId)
                self.showAlert(title: "Success", message: "Booking request sent. Waiting for seller confirmation.")
            }
        }
    }

    func notifySeller(sellerId: String, bookingId: String) {
        dbRef.child("notifications").child(sellerId).childByAutoId().setValue([
            "title": "New Booking Request",
            "message": "You have a new booking request. ID: \(bookingId)",
            "bookingId": bookingId
        ])

        let content = UNMutableNotificationContent()
        content.title = "New Booking Request"
        content.body = "A new booking request has been made for your apartment."
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule local notification: \(error.localizedDescription)")
            } else {
                print("Local notification scheduled successfully.")
            }
        }
    }

    func updateBookingStatus(bookingId: String, status: String) {
        dbRef.child("bookings").child(bookingId).child("sellerDecision").setValue(status) { error, _ in
            if let error = error {
                self.showAlert(title: "Error", message: "Failed to update booking: \(error.localizedDescription)")
            } else {
                self.showAlert(title: "Success", message: "Booking status updated to \(status).")
            }
        }
    }

    func getCurrentUserId() -> String? {
        return Auth.auth().currentUser?.uid
    }

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    func setupUI(for index: Int) {
        guard apartments.indices.contains(index) else {
            print("Index out of bounds.")
            return
        }

        let apartment = apartments[index]
        locationLabel.text = "Location: \(apartment.locationName)"
        priceLabel.text = "Price: \(apartment.price)"
        squareMetersLabel.text = "\(apartment.squareMeters) m²"
        numberOfRoomsLabel.text = "\(apartment.numberOfRooms) Rooms"

        fetchSellerName(sellerId: apartment.sellerId) { [weak self] name in
            DispatchQueue.main.async {
                self?.advertiserNameLabel.text = name ?? "Unknown Seller"
            }
        }
        fetchPhoneNumber(sellerId: apartment.sellerId) { [weak self] phone in
            DispatchQueue.main.async {
                self?.phoneNumberLabel.text = phone ?? "Unknown Phone"
            }
        }
        let storageRef = Storage.storage().reference().child("apartments/\(apartment.apartmentId).jpg")
          storageRef.downloadURL { [weak self] url, error in
              if let error = error {
                  print("Error fetching image URL: \(error.localizedDescription)")
                  return
              }
              guard let imageURL = url else { return }
              DispatchQueue.main.async {
                  self?.imageView.loadImage(from: imageURL)
              }
          }

          timeSlotsTableView.reloadData()
      }

    func setupSwipeGestures() {
        imageView.gestureRecognizers?.forEach { imageView.removeGestureRecognizer($0) }

        let swipeLeftGesture = UISwipeGestureRecognizer(target: self, action: #selector(swipeLeft))
        swipeLeftGesture.direction = .left
        imageView.addGestureRecognizer(swipeLeftGesture)

        let swipeRightGesture = UISwipeGestureRecognizer(target: self, action: #selector(swipeRight))
        swipeRightGesture.direction = .right
        imageView.addGestureRecognizer(swipeRightGesture)
    }

    @objc func swipeLeft() {
        if currentIndex < apartments.count - 1 {
            currentIndex += 1
            setupUI(for: currentIndex)
        } else {
            showAlert(title: "End of List", message: "No more apartments available.")
        }
    }

    @objc func swipeRight() {
        if currentIndex > 0 {
            currentIndex -= 1
            setupUI(for: currentIndex)
        } else {
            showAlert(title: "Start of List", message: "You are at the first apartment.")
        }
    }

    func fetchSellerName(sellerId: String, completion: @escaping (String?) -> Void) {
        dbRef.child("users").child(sellerId).observeSingleEvent(of: .value) { snapshot in
            guard let data = snapshot.value as? [String: Any],
                  let sellerName = data["name"] as? String else {
                completion(nil)
                return
            }
            completion(sellerName)
        }
    }

    func fetchPhoneNumber(sellerId: String, completion: @escaping (String?) -> Void) {
        dbRef.child("users").child(sellerId).observeSingleEvent(of: .value) { snapshot in
            guard let data = snapshot.value as? [String: Any],
                  let phone = data["phone"] as? String else {
                completion(nil)
                return
            }
            completion(phone)
        }
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return apartments[currentIndex].timeSlots.keys.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Array(apartments[currentIndex].timeSlots.keys.sorted())[section]
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let dateKeys = Array(apartments[currentIndex].timeSlots.keys) as [String]
        let sortedDateKeys = dateKeys.sorted()
        let dateKey = sortedDateKeys[section]

        guard let timeSlotsForDate = apartments[currentIndex].timeSlots[dateKey] else { return 0 }

        let validTimeSlots = timeSlotsForDate.filter { timeString, isActive in
            guard isActive else { return false }
            let fullDateTimeString = "\(dateKey) \(timeString)"
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
            if let date = dateFormatter.date(from: fullDateTimeString) {
                return date >= Date()
            }
            return false
        }
        return validTimeSlots.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TimeSlotCell", for: indexPath)

        let dateKeys = Array(apartments[currentIndex].timeSlots.keys) as [String]
        let sortedDateKeys = dateKeys.sorted()
        let dateKey = sortedDateKeys[indexPath.section]

        let timeSlotsForDate = apartments[currentIndex].timeSlots[dateKey]!.filter { timeString, isActive in
            guard isActive else { return false }
            let fullDateTimeString = "\(dateKey) \(timeString)"
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
            if let date = dateFormatter.date(from: fullDateTimeString) {
                return date >= Date()
            }
            return false
        }
        let validTimeSlotKeys = Array(timeSlotsForDate.keys).sorted()
        let timeKey = validTimeSlotKeys[indexPath.row]

        cell.textLabel?.text = timeKey
        cell.textLabel?.textColor = .green

        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let dateKeys = Array(apartments[currentIndex].timeSlots.keys) as [String]
        let sortedDateKeys = dateKeys.sorted()
        let dateKey = sortedDateKeys[indexPath.section]

        let timeSlotsForDate = apartments[currentIndex].timeSlots[dateKey]!.filter { timeString, isActive in
            guard isActive else { return false }
            let fullDateTimeString = "\(dateKey) \(timeString)"
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
            if let date = dateFormatter.date(from: fullDateTimeString) {
                return date >= Date()
            }
            return false
        }
        let validTimeSlotKeys = Array(timeSlotsForDate.keys).sorted()
        let timeKey = validTimeSlotKeys[indexPath.row]

        selectedTimeSlot = (dateKey, timeKey)
    }
}
extension UIImageView {
    func loadImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Error loading image: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            DispatchQueue.main.async {
                self.image = UIImage(data: data)
            }
        }.resume()
    }
}
