//
//  ApartmentsViewController
//  Workshop
//
//  Created by Ilijana Simonovska on 12/17/24.
//

import UIKit
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth

class ApartmentsViewController: UITableViewController, UISearchBarDelegate {
    
    var apartments: [Apartment] = []
    var filteredApartments: [Apartment] = []
    var databaseRef: DatabaseReference!
    var storageRef: StorageReference!
    var searchBar: UISearchBar!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        databaseRef = Database.database().reference()
        storageRef = Storage.storage().reference()
        
        setupSearchBar()
        fetchApartments()
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
    func setupSearchBar() {
        searchBar = UISearchBar()
        searchBar.delegate = self
        searchBar.placeholder = "Search by location"
        searchBar.sizeToFit()
        tableView.tableHeaderView = searchBar
    }
    
    func fetchApartments() {
        databaseRef.child("apartments").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value as? [String: [String: Any]] else {
                print("No apartments found in the database.")
                return
            }

            var apartmentsWithRatings: [Apartment] = []
            let group = DispatchGroup()
            
            for (apartmentId, apartmentData) in value {
                guard let locationName = apartmentData["locationName"] as? String,
                      let price = apartmentData["price"] as? String,
                      let squareMeters = apartmentData["squareMeters"] as? String,
                      let numberOfRooms = apartmentData["numberOfRooms"] as? String,
                      let sellerId = apartmentData["sellerId"] as? String,
                      let timeSlotsDict = apartmentData["timeSlots"] as? [String: [String: Bool]] else {
                    continue
                }
                
                var timeSlots: [String] = []
                for (date, slots) in timeSlotsDict {
                    let dailySlots = slots.keys.map { "\(date) \($0)" }
                    timeSlots.append(contentsOf: dailySlots)
                }
                
                let apartment = Apartment(
                    apartmentId: apartmentId,
                    sellerId: sellerId,
                    locationName: locationName,
                    price: price,
                    squareMeters: squareMeters,
                    numberOfRooms: numberOfRooms,
                    timeSlots: timeSlotsDict
                )
                
                group.enter()
                self.databaseRef.child("bookings").queryOrdered(byChild: "apartmentId").queryEqual(toValue: apartmentId).observeSingleEvent(of: .value) { bookingSnapshot in
                    if let bookings = bookingSnapshot.value as? [String: [String: Any]] {
                        let ratings = bookings.compactMap { $0.value["ratingApartment"] as? Double }
                        if !ratings.isEmpty {
                            let averageRating = ratings.reduce(0, +) / Double(ratings.count)
                            apartment.averageRating = averageRating
                        }
                    }
                    apartmentsWithRatings.append(apartment)
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                self.apartments = apartmentsWithRatings
                self.filteredApartments = self.apartments
                self.tableView.reloadData()
            }
        }
    }

    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredApartments.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ApartmentTableViewCell", for: indexPath) as? ApartmentTableViewCell else {
            return UITableViewCell()
        }
        let apartment = filteredApartments[indexPath.row]
        
        cell.locationLabel.text = "Location: \(apartment.locationName)"
        cell.priceLabel.text = "Price: \(apartment.price)$"
        cell.sizeLabel.text = "\(apartment.squareMeters) square meters"
        if let averageRating = apartment.averageRating {
            cell.ratingLabel.text = "Rating: \(String(format: "%.1f", averageRating))"
        } else {
            cell.ratingLabel.text = "Rating: N/A"
        }
        cell.apartmentImageView.image = UIImage(named: "placeholder")

        let imagePath = "apartments/\(apartment.apartmentId).jpg"
        let imageRef = storageRef.child(imagePath)
        
        imageRef.downloadURL { url, error in
            if let error = error {
                print("Error fetching image URL: \(error.localizedDescription)")
                return
            }
            guard let url = url else { return }
            self.loadImage(from: url) { image in
                DispatchQueue.main.async {
                    if let visibleCell = tableView.cellForRow(at: indexPath) as? ApartmentTableViewCell {
                        visibleCell.apartmentImageView.image = image
                    }
                }
            }
        }
        return cell
    }
    
    func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data {
                completion(UIImage(data: data))
            } else {
                completion(nil)
            }
        }.resume()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "ShowApartmentDetail", sender: indexPath.row)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowApartmentDetail",
           let destinationVC = segue.destination as? ApartmentDetailViewController,
           let selectedIndex = sender as? Int {
            print("Passing Apartments: \(filteredApartments)")
            print("Selected Index: \(selectedIndex)")
            destinationVC.apartments = filteredApartments
            destinationVC.currentIndex = selectedIndex
        }
    }
    
    // MARK: - UISearchBarDelegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredApartments = apartments
        } else {
            filteredApartments = apartments.filter { $0.locationName.lowercased().contains(searchText.lowercased()) }
        }
        tableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        filteredApartments = apartments
        tableView.reloadData()
        searchBar.resignFirstResponder()
    }
}
