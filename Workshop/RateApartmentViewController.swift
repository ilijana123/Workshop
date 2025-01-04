import UIKit
import FirebaseDatabase
import FirebaseAuth

class RateApartmentViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    var eligibleBookings: [Booking] = []
    var dbRef: DatabaseReference!

    override func viewDidLoad() {
        super.viewDidLoad()
        dbRef = Database.database().reference()
        tableView.dataSource = self
        tableView.delegate = self
        fetchEligibleBookings()
    }

    func fetchEligibleBookings() {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("User not logged in")
            return
        }
        
        let currentTime = Date()
        dbRef.child("bookings").observe(.value) { snapshot in
            var fetchedBookings: [Booking] = []
            
            for child in snapshot.children {
                guard let childSnapshot = child as? DataSnapshot,
                      let value = childSnapshot.value as? [String: Any] else { continue }
                
                print("Booking Data: \(value)") // Debug log

                guard let bookingId = value["bookingId"] as? String,
                      let apartmentId = value["apartmentId"] as? String,
                      let sellerId = value["sellerId"] as? String,
                      let buyerId = value["buyerId"] as? String,
                      let visited = value["visited"] as? Bool,
                      let ratingSeller = value["ratingSeller"] as? Float,
                      let ratingApartment = value["ratingApartment"] as? Float,
                      let sellerDecision = value["sellerDecision"] as? String,
                      let timeSlot = value["timeSlot"] as? String else {
                    print("Missing keys in booking data")
                    continue
                }

                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm"
                
                if buyerId == currentUserId,
                   let timeSlotDate = formatter.date(from: timeSlot),
                   sellerDecision == "accepted",
                   timeSlotDate < currentTime,
                   timeSlotDate > currentTime.addingTimeInterval(-24 * 60 * 60) {
                    
                    let booking = Booking(
                        bookingId: bookingId,
                        apartmentId: apartmentId,
                        sellerId: sellerId,
                        buyerId: buyerId,
                        timeSlot: timeSlot,
                        visited: visited,
                        ratingSeller: ratingSeller,
                        ratingApartment: ratingApartment,
                        sellerDecision: sellerDecision
                    )
                    fetchedBookings.append(booking)
                }
            }
            
            print("Fetched eligible bookings: \(fetchedBookings)")
            
            DispatchQueue.main.async {
                self.eligibleBookings = fetchedBookings
                self.tableView.reloadData()
            }
        }
    }



    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return eligibleBookings.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "RatingCell", for: indexPath) as? RatingCell else {
            return UITableViewCell()
        }

        let booking = eligibleBookings[indexPath.row]
        cell.apartmentLabel.text = "Apartment: \(booking.apartmentId)"
        cell.timeLabel.text = "Time: \(booking.timeSlot ?? "N/A")"
        cell.configureStars(for: Int(booking.ratingApartment)) // Update stars based on rating
        
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let booking = eligibleBookings[indexPath.row]
        showRatingUI(for: booking)
    }

    func showRatingUI(for booking: Booking) {
        let alert = UIAlertController(title: "Rate Apartment", message: "Please rate this apartment.", preferredStyle: .alert)
        for i in 1...5 {
            alert.addAction(UIAlertAction(title: "\(i) Stars", style: .default) { _ in
                self.submitRating(for: booking, rating: i)
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    func submitRating(for booking: Booking, rating: Int) {
        dbRef.child("bookings").child(booking.bookingId).child("ratingApartment").setValue(rating) { error, _ in
            if let error = error {
                print("Error submitting rating: \(error.localizedDescription)")
            } else {
                print("Rating submitted successfully.")
                self.fetchEligibleBookings()
            }
        }
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

