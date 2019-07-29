//
//  ProfileViewController.swift
//  LinkX
//
//  Created by Rodney Gainous Jr on 5/26/19.
//  Copyright © 2019 CodeSigned. All rights reserved.
//

import UIKit
import Firebase
import PKHUD

class ProfileViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var profileView: UIView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var headlineLabel: UILabel!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var profileImage: CustomImageView!
    @IBOutlet var pointsLabel: UILabel!
    @IBOutlet var titleHeight: NSLayoutConstraint!
    @IBOutlet var stackView: UIStackView!
    @IBOutlet var postsButton: UIButton!
    @IBOutlet var bookmarksButton: UIButton!
    @IBOutlet var pointsButton: UIButton!
    @IBOutlet var logoutButton: UIButton!
    @IBOutlet var earnButton: UIButton!
    
    var fetchedUser: User?
    var isModal = false
    
    public var contributions = [Contribution]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        profileImage.layer.cornerRadius = 10.0
        profileImage.layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        profileImage.layer.borderWidth = 0.5
        
        pointsLabel.layer.cornerRadius = 5.0
        pointsLabel.layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        pointsLabel.layer.borderWidth = 0.5
        
        profileView.isHidden = true
        
        tableView.register(UINib(nibName: "ContributionTableViewCell", bundle: nil), forCellReuseIdentifier: "ContributionTableViewCell")
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        earnButton.isHidden = isModal
        
        if isModal {
            logoutButton.setTitle("Close", for: .normal)
        }
        
        guard let uid = Auth.auth().currentUser?.uid else {
            self.performSegue(withIdentifier: "ShowSignupFromProfile", sender: self)
            return // no signed in user re-direct to login page
        }
        
        profileView.isHidden = false
        
        guard fetchedUser == nil else {
            DispatchQueue.main.async {
                self.loadUser(user: self.fetchedUser!)
            }
            return
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
        
//        Database.database().fetchUserPoints(withUID: uid) { points in
//            let allPoints = points.map { return $0.value }
//            var total = 0.0
//            allPoints.forEach { total += $0 }
//            self.pointsLabel.text = "\(Int(total)) points"
//        }
    }
    
    func loadUser(user: User) {
        Database.database().fetchContributions(withUID: user.uid) { (contributions, error) in
            if let _ = error {
                return
            }
            
            guard let contributions = contributions else {
                return
            }
            
            DispatchQueue.main.async {
                self.contributions = contributions
                self.tableView.reloadData()
            }
        }
        
        if let points = user.points {
            self.pointsLabel.text = "\(Int(points)) points"
        }
        
        let titleAndCompany = user.title
        if user.title == nil && user.company == nil {
            //titleHeight.constant = 0
        } else {
            if titleAndCompany == nil {
                titleLabel.text = user.company
            } else if user.company != nil {
                titleLabel.text = "\(user.title!) at \(user.company!)"
            } else {
                titleLabel.text = titleAndCompany
            }
        }
        
        self.nameLabel.text = "\(user.firstName) \(user.lastName)"
        self.headlineLabel.text = user.headline ?? "No Headline"
        
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
            print("Failed to fetch user:", err)
            cancel?(err)
        }
    }
    
    @IBAction func postsTouched(_ sender: Any) {
    }
    
    @IBAction func bookmarksTouched(_ sender: Any) {
    }
    
    @IBAction func pointsTouched(_ sender: Any) {
    }
    
    @IBAction func earnTouched(_ sender: Any) {
        performSegue(withIdentifier: "ShowEarnPointsFromProfile", sender: self)
    }
    
    @IBAction func logoutTouched(_ sender: Any) {
        guard !isModal else {
            dismiss(animated: true, completion: nil)
            return
        }
        
        Analytics.logEvent("logout_touched", parameters: [:])

        let logoutAlert = UIAlertController(title: "Logout", message: "Are you sure you want to logout?", preferredStyle: .alert)
        
        logoutAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
            Analytics.logEvent("logoout_confirmed", parameters: [:])
            self.logout()
        }))
        
        logoutAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            Analytics.logEvent("logoout_cancelled", parameters: [:])
        }))
        
        self.present(logoutAlert, animated: true, completion: nil)
    }
    
    func logout() {
        HUD.show(.progress)
        try? Auth.auth().signOut()
        HUD.flash(.success)
        tabBarController?.selectedIndex = 0
    }
    
    @IBAction func editTouched(_ sender: Any) {
        Analytics.logEvent("edit_profile_touched", parameters: [:])
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
            
            spvc.onCloseTouched = { vc in
                self.tabBarController?.selectedIndex = 0
            }
        } else if segue.identifier == "ShowSigninFromProfile" {
            let spvc = segue.destination as! SigninViewController
            spvc.onSignin = { vc in
                vc.dismiss(animated: true, completion: nil)
            }
        }
    }

}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 78.0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contributions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell =
            tableView.dequeueReusableCell(withIdentifier: "ContributionTableViewCell", for: indexPath) as? ContributionTableViewCell else {
                return UITableViewCell()
        }
        
        cell.configure(contribution: contributions[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        Analytics.logEvent("contribution_cell_touched", parameters: [:])

        tableView.deselectRow(at: indexPath, animated: false)
    }
}
