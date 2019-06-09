//
//  EditProfileViewController.swift
//  LinkX
//
//  Created by Rodney Gainous Jr on 5/26/19.
//  Copyright © 2019 CodeSigned. All rights reserved.
//

import UIKit

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
        
        profileImage.layer.cornerRadius = 10.0
        profileImage.layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        profileImage.layer.borderWidth = 0.5
        
        if let imageUrl = user.profileImageUrl {
            profileImage.loadImage(urlString: imageUrl)
        }
        
        self.imagePicker = ImagePicker(presentationController: self, delegate: self)
    }

    @IBAction func changeTouched(_ sender: Any) {
        self.imagePicker.present(from: view)
    }
    
    @IBAction func saveTouched(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func closeTouched(_ sender: Any) {
        navigationController?.popViewController(animated: true)
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
