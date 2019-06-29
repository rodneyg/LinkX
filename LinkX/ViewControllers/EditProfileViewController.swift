//
//  EditProfileViewController.swift
//  LinkX
//
//  Created by Rodney Gainous Jr on 5/26/19.
//  Copyright © 2019 CodeSigned. All rights reserved.
//

import UIKit
import FirebaseAuth
import PKHUD
import FirebaseStorage

class EditProfileViewController: UIViewController {

    @IBOutlet var profileImage: CustomImageView!
    @IBOutlet var firstField: UITextField!
    @IBOutlet var lastField: UITextField!
    @IBOutlet var headlineField: UITextField!
    @IBOutlet var titleField: UITextField!
    @IBOutlet var companyField: UITextField!
    @IBOutlet var emailField: UITextField!
    
    var imagePicker: ImagePicker!
    var user: User!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let user = user else {
            self.dismiss(animated: true, completion: nil)
            return
        }
        
        profileImage.layer.cornerRadius = 10.0
        profileImage.layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        profileImage.layer.borderWidth = 0.5
        
        if let imageUrl = user.profileImageUrl {
            profileImage.loadImage(urlString: imageUrl)
        }
        
        firstField.text = user.firstName
        lastField.text = user.lastName
        emailField.text = Auth.auth().currentUser?.email
        
        if user.headline?.count ?? 0 > 0 {
            headlineField.text = user.headline
        }

        if user.title?.count ?? 0 > 0 {
            titleField.text = user.title
        }
        
        if user.company?.count ?? 0 > 0 {
            companyField.text = user.company
        }
        
        self.imagePicker = ImagePicker(presentationController: self, delegate: self)
    }

    @IBAction func deleteTouched(_ sender: Any) {
        let deleteAlert = UIAlertController(title: "Delete", message: "Your account will permanently be deleted.", preferredStyle: .alert)
        
        deleteAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            self.deleteAccount()
        }))
        
        deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
        }))
        
        self.present(deleteAlert, animated: true, completion: nil)
    }
    
    func deleteAccount() {
        HUD.show(.progress)
        Auth.auth().currentUser?.delete { error in
            if let error = error {
                HUD.flash(.labeledError(title: "Deletion Error", subtitle: error.localizedDescription), delay: 1.5)
            } else {
                HUD.flash(.success, delay: 2.0)
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func changeTouched(_ sender: Any) {
        self.imagePicker.present(from: view)
    }
    
    @IBAction func saveTouched(_ sender: Any) {
        guard let firstName = firstField.text, firstName.count > 1 else {
            return
        }
        
        guard let lastName = lastField.text, lastName.count > 1 else {
            return
        }
        
        guard let email = emailField.text, email.count > 1 else {
            return //TODO: add confirmation check for e-mail change
        }
        
        HUD.flash(.progress, delay: 10.0)
        
        if let image = profileImage.image {
            Storage.storage().uploadUserProfileImage(image: image, completion: { (profileImageUrl) in
                Auth.auth().uploadUser(withUID: self.user.uid, firstName: firstName, lastName: lastName, headline: self.headlineField.text, title: self.titleField.text, company: self.companyField.text, profileImageUrl: profileImageUrl) {
                    HUD.flash(.success, delay: 2.0)
                    self.dismiss(animated: true, completion: nil)
                }
            })
        } else {
            Auth.auth().uploadUser(withUID: self.user.uid, firstName: firstName, lastName: lastName, headline: headlineField.text, title: titleField.text, company: companyField.text) {
                HUD.flash(.success, delay: 2.0)
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func closeTouched(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
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

extension EditProfileViewController: ImagePickerDelegate {
    func didSelect(image: UIImage?) {
        self.profileImage.image = image
    }
}
