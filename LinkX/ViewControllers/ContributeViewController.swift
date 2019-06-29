//
//  AddInvestorViewController.swift
//  LinkX
//
//  Created by Rodney Gainous Jr on 6/21/19.
//  Copyright © 2019 CodeSigned. All rights reserved.
//

import UIKit
import PKHUD
import FirebaseAuth

class ContributeViewController: UIViewController {

    @IBOutlet var firstField: UITextField!
    @IBOutlet var lastField: UITextField!
    @IBOutlet var titleField: UITextField!
    @IBOutlet var fundField: UITextField!
    @IBOutlet var emailField: UITextField!
    
    var contribution: Contribution?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        firstField.delegate = self
        lastField.delegate = self
        titleField.delegate = self
        fundField.delegate = self
        emailField.delegate = self
    }

    @IBAction func nextTouched(_ sender: Any) {
        guard let firstName = firstField.text, firstName.count > 1 else {
            HUD.flash(.labeledError(title: "Invalid", subtitle: "Please enter a valid first name"), delay: 2.0)
            return
        }
        
        guard let lastName = lastField.text, lastName.count > 1 else {
            HUD.flash(.labeledError(title: "Invalid", subtitle: "Please enter a valid last name"), delay: 2.0)
            return
        }
        
        guard let title = titleField.text, title.count > 1 else {
            HUD.flash(.labeledError(title: "Invalid", subtitle: "Please enter a valid title"), delay: 2.0)
            return
        }
        
        guard let company = fundField.text, company.count > 1 else {
            HUD.flash(.labeledError(title: "Invalid", subtitle: "Please enter a company"), delay: 2.0)
            return
        }
        
        guard let uid = Auth.auth().currentUser?.uid else {
            return  // no user loaded
        }
        
        view.endEditing(true)
        
        let date = Date()
        let cDict: [String : Any] = ["first_name" : firstName, "last_name" : lastName, "title" : title, "firm" : company, "status" : "Pending", "reviewer_id" : uid, "type" : "Investor", "email" : emailField.text ?? "", "created_at" : date.timeIntervalSince1970, "updated_at" : date.timeIntervalSince1970]
        contribution = Contribution(dictionary: cDict)
        
        performSegue(withIdentifier: "ShowUploadPhotoFromContribute", sender: self)
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowUploadPhotoFromContribute" {
            let uvc = segue.destination as! UploadViewController
            uvc.contribution = contribution
        }
    }

}

extension ContributeViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == firstField {
            textField.resignFirstResponder()
            lastField.becomeFirstResponder()
        } else if textField == lastField {
            textField.resignFirstResponder()
            titleField.becomeFirstResponder()
        } else if textField == titleField {
            textField.resignFirstResponder()
            fundField.becomeFirstResponder()
        } else if textField == fundField {
            textField.resignFirstResponder()
            emailField.becomeFirstResponder()
        } else if textField == emailField {
            nextTouched(textField)
        }
        return true
    }
}
