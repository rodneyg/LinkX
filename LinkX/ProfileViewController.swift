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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        profileImage.layer.cornerRadius = 10.0
        profileImage.layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        profileImage.layer.borderWidth = 0.5
        
        fetchUserProfile(completion: { user in
            guard let user = user else {
                return
            }
            
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
    
    func fetchUserProfile(completion: @escaping (User?) -> (), withCancel cancel: ((Error) -> ())?) {
        let ref = Database.database().reference().child("users").child("")
        
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let data = snapshot.value as? [String : Any] else {
                completion(nil)
                return
            }
            
            completion(User(uid: "", dictionary: data))
        }) { (err) in
            print("Failed to fetch posts:", err)
            cancel?(err)
        }
    }
    
    @IBAction func editTouched(_ sender: Any) {
        performSegue(withIdentifier: "ShowEditProfile", sender: self)
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
