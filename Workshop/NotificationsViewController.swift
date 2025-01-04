import UIKit
import FirebaseDatabase
import FirebaseAuth

class NotificationsTableViewController: UITableViewController {

    var notifications: [NotificationModel] = []
    let dbRef = Database.database().reference()
    var sellerId: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        if let currentUser = Auth.auth().currentUser {
            sellerId = currentUser.uid
            loadNotifications()
        } else {
            showAlert(title: "Error", message: "You must be logged in to view notifications.")
        }
    }

    func loadNotifications() {
        guard let sellerId = sellerId else {
            showAlert(title: "Error", message: "Failed to retrieve seller information.")
            return
        }

        dbRef.child("bookings").queryOrdered(byChild: "sellerId").queryEqual(toValue: sellerId).observe(.value) { snapshot in
            self.notifications.removeAll()
            guard let bookingData = snapshot.value as? [String: [String: Any]] else {
                DispatchQueue.main.async {
                    self.tableView.reloadData() 
                }
                return
            }

            let group = DispatchGroup()

            for (id, data) in bookingData {
                group.enter()
                let buyerId = data["buyerId"] as? String ?? ""
                self.dbRef.child("users").child(buyerId).observeSingleEvent(of: .value) { userSnapshot in
                    defer { group.leave() }
                    let buyerData = userSnapshot.value as? [String: Any] ?? [:]
                    let buyerName = buyerData["name"] as? String ?? "Unknown"
                    let buyerPhone = buyerData["phone"] as? String ?? "Unknown"

                    var bookingInfo = data
                    bookingInfo["buyerName"] = buyerName
                    bookingInfo["buyerPhone"] = buyerPhone

                    let notification = NotificationModel(id: id, data: bookingInfo)
                    self.notifications.append(notification)
                }
            }

            group.notify(queue: .main) {
                self.tableView.reloadData()
            }
        }

        dbRef.child("bookings").queryOrdered(byChild: "sellerId").queryEqual(toValue: sellerId).observe(.childChanged) { snapshot in
            if let data = snapshot.value as? [String: Any],
               let bookingId = snapshot.key as String? {
                self.updateNotification(bookingId: bookingId, data: data)
            }
        }
    }

    let notificationsQueue = DispatchQueue(label: "com.notifications.queue", attributes: .concurrent)

    func updateNotification(bookingId: String, data: [String: Any]) {
        notificationsQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }

            if let index = self.notifications.firstIndex(where: { $0.id == bookingId }) {
                var updatedData = data
                let buyerId = data["buyerId"] as? String ?? ""

                self.dbRef.child("users").child(buyerId).observeSingleEvent(of: .value) { userSnapshot in
                    let buyerData = userSnapshot.value as? [String: Any] ?? [:]
                    updatedData["buyerName"] = buyerData["name"] as? String ?? "Unknown"
                    updatedData["buyerPhone"] = buyerData["phone"] as? String ?? "Unknown"

                    DispatchQueue.main.async {
                        self.notificationsQueue.async(flags: .barrier) {
                            guard self.notifications.indices.contains(index) else {
                                print("Index out of range for notifications array")
                                return
                            }

                            self.notifications[index] = NotificationModel(id: bookingId, data: updatedData)
                        }
                        DispatchQueue.main.async {
                            self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                        }
                    }
                }
            } else {
                print("Notification with ID \(bookingId) not found.")
            }
        }
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationCell", for: indexPath) as? NotificationCell else {
            fatalError("Unable to dequeue NotificationCell")
        }
        let notification = notifications[indexPath.row]
        let timeSlot = notification.timeSlot

        cell.apartmentIdLabel.text = "Apartment ID: \(notification.apartmentId)"
        cell.buyerNameLabel.text = "Buyer: \(notification.buyerName)"
        cell.buyerPhoneLabel.text = "Phone: \(notification.buyerPhone)"
        cell.timeSlotLabel.text = "Time Slot: \(timeSlot)"

        if isTimeSlotExpired(timeSlot: timeSlot) {
            cell.statusLabel.text = "Status: Expired"
            cell.acceptButton.isHidden = true
            cell.rejectButton.isHidden = true
        } else {
            cell.statusLabel.text = "Status: \(notification.status.capitalized)"
            cell.acceptButton.isHidden = notification.status != "pending"
            cell.rejectButton.isHidden = notification.status != "pending"
        }

        cell.acceptAction = { [weak self] in
            self?.acceptBooking(at: indexPath.row)
        }
        cell.rejectAction = { [weak self] in
            self?.rejectBooking(at: indexPath.row)
        }

        return cell
    }

    func isTimeSlotExpired(timeSlot: String) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        if let slotDate = dateFormatter.date(from: timeSlot) {
            return slotDate < Date()
        }
        return false
    }

    func acceptBooking(at index: Int) {
        guard notifications.indices.contains(index) else { return }
        let notification = notifications[index]
        updateBookingStatus(notification: notification, status: "accepted")
    }

    func rejectBooking(at index: Int) {
        guard notifications.indices.contains(index) else { return }
        let notification = notifications[index]
        updateBookingStatus(notification: notification, status: "rejected")
    }

    func updateBookingStatus(notification: NotificationModel, status: String) {
        dbRef.child("bookings").child(notification.bookingId).updateChildValues(["sellerDecision": status]) { [weak self] error, _ in
            guard let self = self else { return }

            if let error = error {
                self.showAlert(title: "Error", message: "Failed to update booking: \(error.localizedDescription)")
                return
            }

            DispatchQueue.main.async {
                if let index = self.notifications.firstIndex(where: { $0.id == notification.bookingId }) {
                    self.notificationsQueue.async(flags: .barrier) {
                        self.notifications[index].status = status
                    }
                    DispatchQueue.main.async {
                        self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                    }
                } else {
                    self.tableView.reloadData() // Fallback to reload entire table if index not found
                }
            }

            self.notifyBuyer(notification: notification, status: status)
            self.showAlert(title: "Success", message: "Booking \(status.capitalized).")
        }
    }
    func notifyBuyer(notification: NotificationModel, status: String) {
        let buyerNotification = [
            "title": "Booking \(status.capitalized)",
            "message": "Your booking request for \(notification.apartmentId) was \(status).",
            "status": status
        ]
        dbRef.child("notifications").child(notification.buyerId).childByAutoId().setValue(buyerNotification)
    }

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
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
