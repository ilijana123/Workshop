//
//  ApartmentDetailsController.swift
//  Workshop
//
//  Created by Ilijana Simonovska on 12/16/24.
//

import UIKit
import FirebaseStorage
import FirebaseAuth

class ApartmentDetailsController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var apartmentPictureContainer: UIImageView!
    @IBOutlet weak var priceTextField: UITextField!
    @IBOutlet weak var squareMetersTextField: UITextField!
    @IBOutlet weak var numberOfRoomsTextField: UITextField!
    @IBOutlet weak var nextButton: UIBarButtonItem!
    @IBOutlet weak var uploadImageButton: UIButton!
    
    var selectedApartmentPicture: UIImage?
    var apartmentId = UUID().uuidString
    var apartmentDetails: [String: Any] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupImageTapGesture()
        nextButton.isEnabled = false
        handleTextFields()
    }

    // MARK: - Gesture for Image Selection
    func setupImageTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleImageChosen))
        apartmentPictureContainer.addGestureRecognizer(tap)
        apartmentPictureContainer.isUserInteractionEnabled = true
    }

    @objc func handleImageChosen() {
        presentImagePicker()
    }

    // MARK: - Image Picker
    func presentImagePicker() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true, completion: nil)
    }

    // MARK: - Field Validation
    func handleTextFields() {
        priceTextField.addTarget(self, action: #selector(validateFields), for: .editingChanged)
        squareMetersTextField.addTarget(self, action: #selector(validateFields), for: .editingChanged)
        numberOfRoomsTextField.addTarget(self, action: #selector(validateFields), for: .editingChanged)
    }

    @objc func validateFields() {
        guard let price = priceTextField.text, !price.isEmpty,
              let squareMeters = squareMetersTextField.text, !squareMeters.isEmpty,
              let numberOfRooms = numberOfRoomsTextField.text, !numberOfRooms.isEmpty,
              selectedApartmentPicture != nil else {
            nextButton.isEnabled = false
            return
        }
        nextButton.isEnabled = true
    }

    // MARK: - Alert Display
    func displayAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }

    // MARK: - Next Button
    @IBAction func nextButtonPressed(_ sender: UIBarButtonItem) {
        guard selectedApartmentPicture != nil else {
            displayAlert(title: "Error", message: "Please upload an apartment picture.")
            return
        }

        guard Auth.auth().currentUser?.uid != nil else {
            displayAlert(title: "Error", message: "You must be logged in to create an apartment.")
            return
        }
        performSegue(withIdentifier: "toLocationSelection", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toLocationSelection" {
            guard let destinationVC = segue.destination as? LocationSelectionController else { return }

            destinationVC.sellerId = Auth.auth().currentUser?.uid
            destinationVC.apartmentId = apartmentId
            destinationVC.price = priceTextField.text
            destinationVC.squareMeters = squareMetersTextField.text
            destinationVC.numberOfRooms = numberOfRoomsTextField.text

            print("DEBUG: Passing apartment details -> ApartmentID: \(apartmentId)")
        }
    }

    // MARK: - Image Picker Delegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let image = info[.originalImage] as? UIImage {
            apartmentPictureContainer.image = image
            selectedApartmentPicture = image
            uploadImageToStorage(image)
        } else {
            print("Error: Unable to select image.")
        }
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Upload Image to Firebase Storage
    func uploadImageToStorage(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            displayAlert(title: "Error", message: "Unable to process image.")
            return
        }

        let storageRef = Storage.storage().reference()
        let imagePath = "apartments/\(apartmentId).jpg"
        let fileRef = storageRef.child(imagePath)

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        fileRef.putData(imageData, metadata: metadata) { [weak self] (metadata, error) in
            guard let self = self else { return }

            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                self.displayAlert(title: "Error", message: "Failed to upload image. Try again.")
                return
            }

            self.apartmentDetails["imagePath"] = imagePath
            print("Image uploaded successfully!")
            self.validateFields() // Re-validate fields
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    @IBAction func uploadImageButtonTapped(_ sender: UIButton) {
        presentImagePicker()
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
