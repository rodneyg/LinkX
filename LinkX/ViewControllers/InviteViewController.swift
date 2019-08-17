//
//  InviteViewController.swift
//  LinkX
//
//  Created by Rodney Gainous Jr on 6/28/19.
//  Copyright © 2019 CodeSigned. All rights reserved.
//

import UIKit
import ContactsUI
import Contacts
import FirebaseDynamicLinks
import FirebaseDatabase
import Firebase

class InviteViewController: UIViewController {
    
    @IBOutlet var codeButton: UIButton!
    
    var user: User! //user must be set
    var inviteCode: String? {
        didSet {
            guard let code = inviteCode else {
                return //create invite code
            }

            inviteTextButton.setTitle(code, for: .normal)
        }
    }
    
    @IBOutlet var inviteTextButton: UIButton!
    @IBOutlet var inviteButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        inviteCode = user.inviteCode
        
        if inviteCode == nil { //try to create invite code if it does not exist
            Database.database().createInviteCode(withUser: user.uid, firstName: user.firstName, lastName: user.lastName) { code in
                self.inviteCode = code
            }
        }
        // Do any additional setup after loading the view.
    }
    
    @IBAction func closeTouched(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func inviteTouched(_ sender: Any) {
        showContactPicker()
    }
    
    @IBAction func codeTouched(_ sender: Any) {
        //if user does not have a code create one

    }
    
    @IBAction func shareTouched(_ sender: Any) {
        guard let link = user.inviteCodeUrl else {
            return
        }
        
        Analytics.logEvent("share_invite", parameters: ["uid" : user.uid])
        
        // text to share

        // set up activity view controller
        let textToShare = [ link ]
        let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
        
        // present the view controller
        self.present(activityViewController, animated: true, completion: nil)
    }
}

extension InviteViewController: CNContactPickerDelegate {
    
    //MARK:- contact picker
    func showContactPicker(){
    let contactPicker = CNContactPickerViewController()
    contactPicker.delegate = self
    contactPicker.displayedPropertyKeys =
    [CNContactGivenNameKey
    , CNContactPhoneNumbersKey]
    self.present(contactPicker, animated: true, completion: nil)
    
    }
    
    func contactPicker(_ picker: CNContactPickerViewController,
    didSelect contactProperty: CNContactProperty) {
    
    }
    
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
    // You can fetch selected name and number in the following way
    
    // user name
    let userName:String = contact.givenName
    
    // user phone number
    let userPhoneNumbers:[CNLabeledValue<CNPhoneNumber>] = contact.phoneNumbers
    let firstPhoneNumber:CNPhoneNumber = userPhoneNumbers[0].value
    
    
    // user phone number string
    let primaryPhoneNumberStr:String = firstPhoneNumber.stringValue
    
    print(primaryPhoneNumberStr)
    
    }
    
    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
    
    }
}
