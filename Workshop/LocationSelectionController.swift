//
//  LocationSelectionController.swift
//  Workshop
//
//  Created by Ilijana Simonovska on 12/16/24.
//

import UIKit
import UIKit
import MapKit
import CoreLocation
import FirebaseAuth

class LocationSelectionController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UISearchBarDelegate, UITableViewDataSource,
                                   
    UITableViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var locationNameLabel: UILabel!
    @IBOutlet weak var confirmButton: UIBarButtonItem!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    var sellerId: String?
    var apartmentId: String?
    var imageUrl: String?
    var price: String?
    var phone: String?
    var squareMeters: String?
    var numberOfRooms: String?
    var apartmentDetails: [String: Any] = [:]
    var selectedLocationName: String?
    var latitude: String = ""
    var longitude: String = ""

    var locationManager = CLLocationManager()
    var searchResults: [MKMapItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupMap()
        setupSearchBar()
        setupTableView()
    }

    func setupMap() {
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        mapView.addGestureRecognizer(longPressRecognizer)
    }

    func setupSearchBar() {
        searchBar.delegate = self
    }

    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isHidden = true 
    }

    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let touchPoint = gestureRecognizer.location(in: mapView)
            let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            updateLocation(coordinate: coordinate)
        }
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.text, !searchText.isEmpty else { return }
        searchBar.resignFirstResponder()
        searchForLocation(named: searchText)
    }

    func searchForLocation(named name: String) {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = name

        let localSearch = MKLocalSearch(request: searchRequest)
        localSearch.start { [weak self] response, error in
            guard let self = self else { return }

            if let error = error {
                print("Search error: \(error.localizedDescription)")
                self.displayAlert(title: "Error", message: "Could not find location. Please try again.")
                return
            }

            guard let response = response else {
                self.displayAlert(title: "Error", message: "No results found for '\(name)'.")
                return
            }

            self.searchResults = response.mapItems.filter { $0.placemark.name != nil }
            self.tableView.reloadData()
            self.tableView.isHidden = self.searchResults.isEmpty
        }
    }

    func updateLocation(coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        CLGeocoder().reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }

            if let placemark = placemarks?.first {
                let locationName = placemark.name ?? "Unnamed Location"
                self.selectedLocationName = locationName
                self.locationNameLabel.text = "Selected Location: \(locationName)"
                self.latitude = "\(coordinate.latitude)"
                self.longitude = "\(coordinate.longitude)"

                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                annotation.title = locationName
                self.mapView.removeAnnotations(self.mapView.annotations)
                self.mapView.addAnnotation(annotation)
            }
            self.tableView.isHidden = true
        }
    }

    // MARK: - TableView DataSource and Delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultCell", for: indexPath)
        let item = searchResults[indexPath.row]
        cell.textLabel?.text = item.placemark.name
        cell.detailTextLabel?.text = item.placemark.title
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedMapItem = searchResults[indexPath.row]
        let coordinate = selectedMapItem.placemark.coordinate
        updateLocation(coordinate: coordinate)
        mapView.setRegion(MKCoordinateRegion(center: coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000), animated: true)
    }

    @IBAction func confirmLocationPressed(_ sender: UIBarButtonItem) {
            guard let locationName = selectedLocationName else {
                displayAlert(title: "Error", message: "Please select a valid location.")
                return
            }

            // Prepare for the next segue
            performSegue(withIdentifier: "toTimeSlots", sender: self)
        }

        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if segue.identifier == "toTimeSlots" {
                guard let destinationVC = segue.destination as? TimeSlotsController else { return }

                destinationVC.sellerId = sellerId
                destinationVC.apartmentId = apartmentId
                destinationVC.imageUrl = imageUrl
                destinationVC.price = price
                destinationVC.phone = phone
                destinationVC.squareMeters = squareMeters
                destinationVC.numberOfRooms = numberOfRooms
                destinationVC.locationName = selectedLocationName
                destinationVC.latitude = latitude
                destinationVC.longitude = longitude

                print("DEBUG: Passing fields to TimeSlots -> SellerID: \(sellerId ?? "nil")")
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

extension LocationSelectionController {
    func displayAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
}
