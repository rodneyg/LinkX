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
import FirebaseAnalytics
import PKHUD

class SigninViewController: UIViewController {

    @IBOutlet var emailField: UITextField!
    @IBOutlet var passwordField: UITextField!
    
    var onSignin: ((UIViewController) -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func forgotTouched(_ sender: Any) {
        Analytics.logEvent("forgot_touched", parameters: [:])

        guard let email = emailField.text, email.count > 2 else {
            HUD.flash(.labeledError(title: "Error", subtitle: "Enter Valid E-mail"), delay: 2.0)
            Analytics.logEvent("forgot_failed", parameters: ["reason" : "email"])
            return //enter valid e-mail
        }
        
        Auth.auth().sendPasswordReset(withEmail: email) { err in
            if let error = err {
                //print error
                HUD.flash(.labeledError(title: "Error", subtitle: error.localizedDescription), delay: 2.0)

                Analytics.logEvent("forgot_password_failed", parameters: ["description" : error.localizedDescription])
                print("error forgot password in: \(error.localizedDescription)")
                return
            }
            
            HUD.show(.labeledSuccess(title: "Email", subtitle: "Check your email for your forgot password link."))
        }
    }
    
    @IBAction func signinTouched(_ sender: Any) {
        Analytics.logEvent("signin_touched", parameters: [:])

        guard let email = emailField.text, email.count > 2 else {
            Analytics.logEvent("signin_failed", parameters: ["reason" : "email"])
            return //enter valid e-mail
        }
        
        guard let password = passwordField.text, password.count > 2 else {
            Analytics.logEvent("signin_failed", parameters: ["reason" : "password"])
            return //enter valid password
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { (authData, err) in
            if let error = err {
                //print error
                //if account doesn't exist suggest the user sign up by sending them to the signup page pre-filled
                print("error signing in: \(error.localizedDescription)")
                Analytics.logEvent("signin_failed", parameters: ["description" : error.localizedDescription])
                HUD.flash(.labeledError(title: "Error", subtitle: error.localizedDescription), delay: 2.0)
                return
            }
            
            Analytics.logEvent("success_signin", parameters: [:])
            HUD.flash(.success, delay: 2.0)
            self.onSignin?(self)
        }
    }
    
    @IBAction func dismissTouched(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
