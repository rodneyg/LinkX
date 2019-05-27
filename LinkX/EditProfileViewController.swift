//
//  EditProfileViewController.swift
//  LinkX
//
//  Created by Rodney Gainous Jr on 5/26/19.
//  Copyright © 2019 CodeSigned. All rights reserved.
//

import UIKit

class EditProfileViewController: UIViewController {

    @IBOutlet var profileImage: UIImageView!
    @IBOutlet var firstField: UITextField!
    @IBOutlet var lastField: UITextField!
    @IBOutlet var headlineField: UITextField!
    @IBOutlet var titleField: UITextField!
    @IBOutlet var companyField: UITextField!
    @IBOutlet var emailField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func changeTouched(_ sender: Any) {
    }
    
    @IBAction func saveTouched(_ sender: Any) {
    }
    
    @IBAction func closeTouched(_ sender: Any) {
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
