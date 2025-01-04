//
//  ViewController.swift
//  Workshop
//
//  Created by Ilijana Simonovska on 12/15/24.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class ViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var buyerSellerSwitch: UISwitch!
    @IBOutlet weak var buyerLabel: UILabel!
    @IBOutlet weak var sellerLabel: UILabel!
    @IBOutlet weak var topButton: UIButton!
    @IBOutlet weak var bottomButton: UIButton!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    
    var signUpMode = false
    private let db = Database.database().reference()

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        if let user = Auth.auth().currentUser {
            db.child("users").child(user.uid).observeSingleEvent(of: .value) { snapshot in
                if let value = snapshot.value as? [String: Any],
                   let userType = value["type"] as? String {
                    if userType == "Seller" {
                        self.performSegue(withIdentifier: "sellerSegue", sender: nil)
                    } else if userType == "Buyer" {
                        self.performSegue(withIdentifier: "buyerSegue", sender: nil)
                    }
                }
            }
        }
        setVisibleElements(signup: signUpMode)
    }
       
    func setVisibleElements(signup: Bool) {
        nameTextField.isHidden = !signup
        phoneTextField.isHidden = !signup
        buyerLabel.isHidden = !signup
        sellerLabel.isHidden = !signup
        buyerSellerSwitch.isHidden = !signup

        if signup {
            topButton.setTitle("Sign up", for: .normal)
            bottomButton.setTitle("Switch to log in", for: .normal)
        } else {
            topButton.setTitle("Log in", for: .normal)
            bottomButton.setTitle("Switch to sign up", for: .normal)
        }
    }

    @IBAction func topTapped(_ sender: Any) {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            displayAlert(title: "Missing Information", message: "Please enter email and password!")
            return
        }

        if signUpMode {
            guard let name = nameTextField.text, !name.isEmpty,
                  let phone = phoneTextField.text, !phone.isEmpty else {
                displayAlert(title: "Missing Information", message: "Please enter your name and phone number for sign-up!")
                return
            }

            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                if let error = error {
                    self.displayAlert(title: "Error", message: error.localizedDescription)
                    return
                }
                guard let user = result?.user else {
                    self.displayAlert(title: "Error", message: "Failed to create user.")
                    return
                }

                let userType = self.buyerSellerSwitch.isOn ? "Seller" : "Buyer"
                let req = user.createProfileChangeRequest()
                req.displayName = name

                req.commitChanges { error in
                    if let error = error {
                        self.displayAlert(title: "Error", message: "Profile update failed: \(error.localizedDescription)")
                    }
                }

                self.db.child("users").child(user.uid).setValue([
                    "id": user.uid,
                    "name": name,
                    "email": email,
                    "type": userType,
                    "phone": phone,
                    "createdAt": ServerValue.timestamp()
                ]) { error, _ in
                    if let error = error {
                        self.displayAlert(title: "Error", message: error.localizedDescription)
                    } else {
                        if userType == "Seller" {
                            self.performSegue(withIdentifier: "sellerSegue", sender: nil)
                        } else if userType == "Buyer" {
                            self.performSegue(withIdentifier: "buyerSegue", sender: nil)
                        }
                    }
                }
            }
        } else {
            Auth.auth().signIn(withEmail: email, password: password) { result, error in
                if let error = error {
                    self.displayAlert(title: "Error", message: error.localizedDescription)
                    return
                }
                guard let user = result?.user else {
                    self.displayAlert(title: "Error", message: "Failed to log in.")
                    return
                }

                self.db.child("users").child(user.uid).observeSingleEvent(of: .value) { snapshot in
                    if snapshot.exists(), let value = snapshot.value as? [String: Any],
                       let userType = value["type"] as? String {
                        if userType == "Seller" {
                            self.performSegue(withIdentifier: "sellerSegue", sender: nil)
                        } else if userType == "Buyer" {
                            self.performSegue(withIdentifier: "buyerSegue", sender: nil)
                        }
                    } else {
                        self.displayAlert(title: "Error", message: "User data not found. Please sign up first.")
                        try? Auth.auth().signOut()
                    }
                }
            }
        }
    }


    @IBAction func bottomTapped(_ sender: Any) {
        signUpMode.toggle()
        setVisibleElements(signup: signUpMode)
    }
       
    func displayAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
}
