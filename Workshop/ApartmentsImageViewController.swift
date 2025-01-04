//
//  ApartmentsImageViewController.swift
//  Workshop
//
//  Created by Ilijana Simonovska on 12/21/24.
//

import UIKit
import FirebaseStorage
import FirebaseDatabase
import FirebaseAuth

class ApartmentsImageViewController: UICollectionViewController {
    var apartmentIds: [String] = []
    var images: [UIImage] = []
    var storageRef: StorageReference!
    var databaseRef: DatabaseReference!

    override func viewDidLoad() {
        super.viewDidLoad()

        storageRef = Storage.storage().reference()
        databaseRef = Database.database().reference()

        fetchApartmentIds()
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
    func fetchApartmentIds() {
        databaseRef.child("apartments").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value as? [String: Any] else {
                print("No apartments found.")
                return
            }

            self.apartmentIds = Array(value.keys)
            self.fetchImages()
        }
    }

    func fetchImages() {
        let group = DispatchGroup()
        images.removeAll()

        for id in apartmentIds {
            group.enter()
            let imagePath = "apartments/\(id).jpg"
            let imageRef = storageRef.child(imagePath)

            imageRef.getData(maxSize: 10 * 1024 * 1024) { data, error in // 10MB max size
                if let error = error {
                    print("Error downloading image for apartment \(id): \(error.localizedDescription)")
                    group.leave()
                    return
                }

                if let data = data, let image = UIImage(data: data) {
                    self.images.append(image)
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            self.collectionView.reloadData()
        }
    }

    func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    // MARK: - UICollectionView DataSource
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ApartmentImageCell", for: indexPath) as! ApartmentImageCell
        cell.imageView.image=images[indexPath.item]

        return cell
    }
}
