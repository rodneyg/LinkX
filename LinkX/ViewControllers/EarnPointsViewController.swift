//
//  EarnPointsViewController.swift
//  LinkX
//
//  Created by Rodney Gainous Jr on 7/1/19.
//  Copyright © 2019 CodeSigned. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class EarnPointsViewController: UIViewController {
    
    var user: User?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let uid = Auth.auth().currentUser?.uid else {
            self.performSegue(withIdentifier: "ShowSignupFromEarnPoints", sender: self)
            return // no signed in user re-direct to login page
        }

        fetchUserProfile(uid: uid, completion: { user in
            guard let user = user else {
                return //user profile could not be fetched
            }
            
            self.user = user
        }) { error in
            print(error.localizedDescription)
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
            print("Failed to fetch user:", err)
            cancel?(err)
        }
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EmbedActivityTable" {
            let avc = segue.destination as! ActivityTableViewController
            avc.activitySelected = { activity in
                if LXConstants.CONTRIBUTE_INVESTOR.id == activity.id {
                    self.performSegue(withIdentifier: "ShowContributeFromEarnPoints", sender: self)
                } else if LXConstants.REFERRAL.id == activity.id {
                    guard self.user != nil else {
                        return //user does not exist
                    }
                    
                    self.performSegue(withIdentifier: "ShowInviteFromEarnPoints", sender: self)
                }
            }
        } else if segue.identifier == "ShowInviteFromEarnPoints" {
            let ivc = segue.destination as! InviteViewController
            ivc.user = self.user!
        }
    }
}
