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

class InviteViewController: UIViewController {
    
    @IBOutlet var codeButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func inviteTouched(_ sender: Any) {
        showContactPicker()
    }
    
    @IBAction func codeTouched(_ sender: Any) {
        //if user does not have a code create one
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
