//
//  UploadViewController.swift
//  LinkX
//
//  Created by Rodney Gainous Jr on 6/21/19.
//  Copyright © 2019 CodeSigned. All rights reserved.
//

import UIKit
import PKHUD
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage
import FirebaseAnalytics

class UploadViewController: UIViewController {

    @IBOutlet var profileImage: CustomImageView!
    @IBOutlet var uploadButton: UIButton!
    @IBOutlet var removePhoto: UIButton!
    @IBOutlet var nextButton: UIButton!
    
    var imagePicker: ImagePicker!
    var selectedImage: UIImage?
    
    var contribution: Contribution!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        profileImage.layer.cornerRadius = 10.0
        profileImage.layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        profileImage.layer.borderWidth = 0.5
        
        self.imagePicker = ImagePicker(presentationController: self, delegate: self)
    }
    
    @IBAction func removeTouched(_ sender: Any) {
        removePhoto.isHidden = true
        selectedImage = nil
        profileImage.image = nil
    }
    
    @IBAction func backTouched(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func nextTouched(_ sender: Any) {
        guard let uid = Auth.auth().currentUser?.uid else {
            return // no current user
        }
        
        HUD.flash(.progress, delay: 10.0)

        if let image = selectedImage { //if we have an image upload it first
            Storage.storage().uploadInvestorProfileImage(image: image) { profileImageUrl in
                self.contribution.profileImageUrl = profileImageUrl
                self.addContribution(withUID: uid, contribution: self.contribution)
            }
            
            return
        }
        
        self.addContribution(withUID: uid, contribution: contribution)
    }
    
    func addContribution(withUID uid: String, contribution: Contribution) {
        Database.database().addContribution(withUID: uid, contribution: contribution) { error in
            if self.handleError(error: error) {
                Analytics.logEvent("add_contribution_error", parameters: ["description" : error?.localizedDescription ?? ""])
                return
            }
            
            Analytics.logEvent("added_contribution", parameters: ["uid" : uid])
            let activity = Activity(data: ["id" : "add_investor", "name" : "Add Investor"])
            var pointData : [String : Any] =  ["value" : 15.0, "activity" : activity, "created_at" : Date().timeIntervalSinceNow]
            if self.contribution.profileImageUrl != nil {
                pointData["notes"] = "additional 5 points for uploading image"
                pointData["value"] = 20.0
            }
            let point = Point(data: pointData)
            Database.database().addPoint(withUID: uid, point: point, completion: { error in
                if self.handleError(error: error) {
                    Analytics.logEvent("add_points_error", parameters: ["description" : error?.localizedDescription ?? ""])

                    return
                }
                
                Analytics.logEvent("added_points", parameters: ["uid" : uid, "points" : point.value])

                HUD.flash(.success, delay: 2.5)
                self.navigationController?.popToRootViewController(animated: true)
            })
        }
    }
    
    func handleError(error: Error?) -> Bool {
        if let error = error {
            HUD.flash(.labeledError(title: "Error", subtitle: error.localizedDescription), delay: 2.0)
            return true
        }
        
        return false
    }
    
    @IBAction func uploadTouched(_ sender: Any) {
        self.imagePicker.present(from: view)
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "" {
            
        }
    }
}

extension UploadViewController: ImagePickerDelegate {
    func didSelect(image: UIImage?) {
        self.removePhoto.isHidden = false
        self.profileImage.image = image
        self.selectedImage = image
    }
}
