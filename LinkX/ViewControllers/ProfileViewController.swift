//
//  ProfileViewController.swift
//  LinkX
//
//  Created by Rodney Gainous Jr on 5/26/19.
//  Copyright © 2019 CodeSigned. All rights reserved.
//

import UIKit
import Firebase

class ProfileViewController: UIViewController {

    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var headlineLabel: UILabel!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var companyLabel: UILabel!
    @IBOutlet var profileImage: CustomImageView!
    
    var fetchedUser: User?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        profileImage.layer.cornerRadius = 10.0
        profileImage.layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        profileImage.layer.borderWidth = 0.5
        
        guard let uid = Auth.auth().currentUser?.uid else {
            self.performSegue(withIdentifier: "ShowSignupFromProfile", sender: self)
            return // no signed in user re-direct to login page
        }
        
        fetchUserProfile(uid: uid, completion: { user in
            guard let user = user else {
                return //user profile could not be fetched
            }
            
            self.fetchedUser = user
            
            DispatchQueue.main.async {
                self.loadUser(user: user)
            }
        }) { error in
            print(error.localizedDescription)
        }
    }
    
    func loadUser(user: User) {
        nameLabel.text = "\(user.firstName) \(user.lastName)"
        headlineLabel.text = user.headline
        titleLabel.text = user.title
        companyLabel.text = user.company
        
        if let imageUrl = user.profileImageUrl {
            profileImage.loadImage(urlString: imageUrl)
        }
    }
    
    func fetchUserProfile(uid: String, completion: @escaping (User?) -> (), withCancel cancel: ((Error) -> ())?) {
        let ref = Database.database().reference().child("users").child(uid)
        
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let data = snapshot.value as? [String : Any] else {
                completion(nil)
                return
            }
            
            completion(User(uid: uid, dictionary: data))
        }) { (err) in
            print("Failed to fetch posts:", err)
            cancel?(err)
        }
    }
    
    @IBAction func editTouched(_ sender: Any) {
        performSegue(withIdentifier: "ShowEditProfile", sender: self)
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowEditProfile" {
            let epvc = segue.destination as! EditProfileViewController
            
            if let user = self.fetchedUser {
                epvc.user = user
            }
        } else if segue.identifier == "ShowSignupFromProfile" {
            let spvc = segue.destination as! SignupViewController
            spvc.onSigninTouched = { vc in
                vc.dismiss(animated: true, completion: {
                    self.performSegue(withIdentifier: "ShowSigninFromProfile", sender: self)
                })
            }
        }
    }

}
