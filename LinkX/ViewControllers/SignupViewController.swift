//
//  SignupViewController.swift
//  LinkX
//
//  Created by Rodney Gainous Jr on 6/19/19.
//  Copyright © 2019 CodeSigned. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseAnalytics
import FirebaseDatabase
import PKHUD

class SignupViewController: UIViewController {

    @IBOutlet var firstNameField: UITextField!
    @IBOutlet var lastNameField: UITextField!
    @IBOutlet var emailField: UITextField!
    @IBOutlet var passwordField: UITextField!
    
    var signingIn = false
    
    public var onSigninTouched: ((UIViewController) -> ())?
    public var onCloseTouched: ((UIViewController) -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        firstNameField.delegate = self
        lastNameField.delegate = self
        emailField.delegate = self
        passwordField.delegate = self
    }
    
    @IBAction func joinTouched(_ sender: Any) {
        Analytics.logEvent("join_touched", parameters: ["reason" : "first name"])

        guard signingIn == false else {
            Analytics.logEvent("join_failed", parameters: ["reason" : "in progress"])
            return
        }
        
        signingIn = true
        
        guard let firstName = firstNameField.text, firstName.count > 1 else {
            Analytics.logEvent("join_failed", parameters: ["reason" : "first name"])
            return
        }
        
        guard let lastName = lastNameField.text, lastName.count > 1 else {
            Analytics.logEvent("join_failed", parameters: ["reason" : "last name"])
            return
        }
        
        guard let email = emailField.text, email.count > 1 else {
            Analytics.logEvent("join_failed", parameters: ["reason" : "email"])
            return
        }
        
        guard let password = passwordField.text, password.count > 4 else {
            Analytics.logEvent("join_failed", parameters: ["reason" : "password"])
            return //password must be at least 5 characters
        }
        
        Auth.auth().createUser(withEmail: email, firstName: firstName, lastName: lastName, password: password, image: nil) { err in
            if let error = err {
                //print error
                self.signingIn = false
                Analytics.logEvent("join_failed", parameters: ["description" : error.localizedDescription])
                HUD.flash(.labeledError(title: "Error", subtitle: error.localizedDescription), delay: 1.5)
                return
            }
            
            Analytics.logEvent("join_success", parameters: [:])
            HUD.flash(.success, delay: 1.5)
            self.signingIn = false
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func signInTouched(_ sender: Any) {
        onSigninTouched?(self)
    }
    
    @IBAction func closeTouched(_ sender: Any) {
        onCloseTouched?(self)
        dismiss(animated: true, completion: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension SignupViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == firstNameField {
            Analytics.logEvent("signup_return_key", parameters: ["text_field" : "first name"])
            textField.resignFirstResponder()
            lastNameField.becomeFirstResponder()
        } else if textField == lastNameField {
            Analytics.logEvent("signup_return_key", parameters: ["text_field" : "last name"])
            textField.resignFirstResponder()
            emailField.becomeFirstResponder()
        } else if textField == emailField {
            Analytics.logEvent("signup_return_key", parameters: ["text_field" : "email"])
            textField.resignFirstResponder()
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            Analytics.logEvent("signup_return_key", parameters: ["text_field" : "password"])
            signInTouched(textField)
        }
        return true
    }
}
