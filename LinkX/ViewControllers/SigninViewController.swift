//
//  SigninViewController.swift
//  LinkX
//
//  Created by Rodney Gainous Jr on 6/19/19.
//  Copyright © 2019 CodeSigned. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class SigninViewController: UIViewController {

    @IBOutlet var emailField: UITextField!
    @IBOutlet var passwordField: UITextField!
    
    var onSignin: ((UIViewController) -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func forgotTouched(_ sender: Any) {
        guard let email = emailField.text, email.count > 2 else {
            return //enter valid e-mail
        }
        
        Auth.auth().sendPasswordReset(withEmail: email) { err in
            if let error = err {
                //print error
                print("error forgot password in: \(error.localizedDescription)")
                return
            }
            
            //TODO: let the user know to check their email
        }
    }
    
    @IBAction func signinTouched(_ sender: Any) {
        guard let email = emailField.text, email.count > 2 else {
            return //enter valid e-mail
        }
        
        guard let password = passwordField.text, password.count > 2 else {
            return //enter valid password
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { (authData, err) in
            if let error = err {
                //print error
                //if account doesn't exist suggest the user sign up by sending them to the signup page pre-filled
                print("error signing in: \(error.localizedDescription)")
                return
            }
            
            self.onSignin?(self)
        }
    }
    
    @IBAction func dismissTouched(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
