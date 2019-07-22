//
//  EmailViewController.swift
//  LinkX
//
//  Created by Rodney Gainous Jr on 3/23/19.
//  Copyright © 2019 CodeSigned. All rights reserved.
//

import UIKit
import MessageUI
import CoreData
import Cosmos
import FirebaseAuth
import FirebaseDatabase
import FirebaseFirestore
import FirebaseUI
import FirebaseAnalytics
import PKHUD

class EmailViewController: UIViewController, MFMailComposeViewControllerDelegate, FUIAuthDelegate {
    
    public var investor: Investor!
    public var fund: Fund?
    public var loggedIn: Bool = false
    public var purchased: Bool = false
    public var canPurchase: Bool = false
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var sendLabel: UILabel!
    @IBOutlet var loginButton: UIButton!
    @IBOutlet var bookmarkButton: UIButton!
    
    @IBOutlet var contactView: UIStackView!
        
    @IBOutlet var profileImage: CustomImageView!
    
    public var onSigninTouched: ((UIViewController) -> ())?
    
    private var storedInvestor: LXInvestor?
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    let db = Firestore.firestore()
    let authUI = FUIAuth.defaultAuthUI()
    let providers: [FUIAuthProvider] = [
        FUIEmailAuth()
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        profileImage.layer.cornerRadius = 10.0
        profileImage.layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        profileImage.layer.borderWidth = 0.5
        
        if investor.publicUrl == nil && investor.key != nil {
            Database.database().createInvestorLink(withInvestor: investor.key!) { url in
                self.investor.publicUrl = url
            }
        }
        
        checkUser()
        fetchInvestor()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        checkUser()
        
        nameLabel.text = investor.fullName()
        titleLabel.text = "\(investor.title) at \(investor.firm)"
    }
    
    @IBAction func loginTouched(_ sender: Any) {
        guard let uid = Auth.auth().currentUser?.uid else {
            if onSigninTouched == nil {
                self.tabBarController?.selectedIndex = 2
            } else {
                onSigninTouched?(self)
            }
            return // no user
        }
        
        //hasPurchased, canPurchased
        if canPurchase { //show prompt to accept purchase

            let purchaseAlert = UIAlertController(title: "Confirm Purchase", message: "Access to this contact is 25 points. Are you sure you want to continue?", preferredStyle: .alert)
            
            purchaseAlert.addAction(UIAlertAction(title: "Yes, Purchase", style: .default, handler: { (action: UIAlertAction!) in
                HUD.flash(.progress, onView: self.view, delay: 60.0, completion: nil)
                
                Database.database().purchaseInvestorContact(uid: uid, investorId: self.investor.id, completion: { (transaction, error) in
                    if let error = error {
                        print(error.localizedDescription)
                        HUD.flash(.labeledError(title: "Error", subtitle: error.localizedDescription), delay: 4.5)
                        return
                    }
                    
                    guard let _ = transaction else {
                        HUD.flash(.labeledError(title: "Error", subtitle: "Transaction could not be completed."), delay: 4.5)
                        return
                    }
                    
                    self.bookmarkTouched(self)
                    self.loginButton.isHidden = true
                    self.contactView.isHidden = false
                    self.sendLabel.text = self.investor.contactInfo.email
                    HUD.flash(.success, delay: 2.5)
                    HUD.flash(.success, onView: nil, delay: 2.5, completion: { success in
                        AppStore.shared.setAppRuns(5)
                        AppStore.shared.showReview()
                    })
                })
            }))
            
            purchaseAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            }))
            
            self.present(purchaseAlert, animated: true, completion: nil)
        } else { //logged in and can't purchase
            tabBarController?.selectedIndex = 4 // go to earn points
        }
    }
    
    func splitEmail(email: String) -> String {
        var splits = email.split(separator: "@")
        
        return splits.count > 1 ? "xxxx@\(splits[1])" : "xxxx@xxxx.com"
    }
    
    private func authUI(_ authUI: FUIAuth, didSignInWith user: User?, error: Error?) {
        checkUser()
    }
    
    func checkUser() {
        guard let user = Auth.auth().currentUser else {
            self.contactView.isHidden = true
            self.loginButton.isHidden = false
            self.loginButton.setTitle("Login To See Contact Details", for: .normal)
            self.sendLabel.text = self.splitEmail(email: self.investor.contactInfo.email)
            return // no user
        }
        
        Database.database().hasPurchasedInvestor(uid: user.uid, investorId: investor.id) { hasPurchasedInvestor in
            self.purchased = hasPurchasedInvestor
            
            if hasPurchasedInvestor {
                self.contactView.isHidden = false
                self.loginButton.isHidden = true
                self.sendLabel.text = self.investor.contactInfo.email
            } else {
                Database.database().canPurchaseInvestor(uid: user.uid, completion: { canPurchase in
                    self.canPurchase = canPurchase
                    
                    if canPurchase {
                        self.loginButton.isHidden = false
                        self.contactView.isHidden = false
                        self.loginButton.setTitle("Access for 25 Points", for: .normal)
                        self.sendLabel.text = self.splitEmail(email: self.investor.contactInfo.email)
                        return // no user
                    } else {
                        self.loginButton.isHidden = false
                        self.contactView.isHidden = true
                        self.loginButton.setTitle("Earn Points To Access", for: .normal)
                        self.sendLabel.text = self.splitEmail(email: self.investor.contactInfo.email)
                        return // no user
                    }
                })
            }
        }
    }
    
    public func fetchInvestor() {
        let context = appDelegate.persistentContainer.viewContext

        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "LXInvestor")
        request.predicate = NSPredicate(format: "id = %@", investor.id)
        request.returnsObjectsAsFaults = false
        
        do {
            let result = try context.fetch(request)
            guard let investors = result as? [LXInvestor], let fetchedInvestor = investors.first else {
                return //investor selected is not stored locally
            }
            
            self.storedInvestor = fetchedInvestor
            self.bookmarkButton.isSelected = true //stored investors are bookmarked
        } catch {
            print("Failed")
        }
    }

    @IBAction func shareTouched(_ sender: Any) {
        guard let uid = Auth.auth().currentUser?.uid, let publicUrl = investor.publicUrl else {
            return
        }
        
        Analytics.logEvent("share_touched", parameters: ["uid" : uid, "investor_id" : investor.id, "investor_name" : investor.fullName()])

        // text to share
        let text = "Hey. Check out \(investor.first) \(investor.last) on LinkX on iOS! \(publicUrl)"
        
        // set up activity view controller
        let textToShare = [ text ]
        let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
        
        // present the view controller
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    @IBAction func clipboardTouched(_ sender: Any) {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        Analytics.logEvent("clipboard_touched", parameters: ["uid" : uid, "investor_id" : investor.id, "investor_name" : investor.fullName()])
        UIPasteboard.general.string = investor.contactInfo.email
        //TODO: add show alert
    }
    
    @IBAction func bookmarkTouched(_ sender: Any) {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        let context = appDelegate.persistentContainer.viewContext
        
        Analytics.logEvent("bookmark_touched", parameters: ["uid" : uid, "investor_id" : investor.id, "investor_name" : investor.fullName()])

        guard storedInvestor == nil else { //investor already stored locally, delete bookmark
            Analytics.logEvent("delete_bookmark", parameters: ["uid" : uid, "investor_id" : investor.id, "investor_name" : investor.fullName()])
            context.delete(storedInvestor!)
            bookmarkButton.isSelected = false
            storedInvestor = nil
            return
        }
        
        let entity = NSEntityDescription.entity(forEntityName: "LXInvestor", in: context)
        let newInvestor = NSManagedObject(entity: entity!, insertInto: context)
        
        newInvestor.setValue(investor.id, forKey: "id")
        newInvestor.setValue(investor.first, forKey: "first")
        newInvestor.setValue(investor.last, forKey: "last")
        newInvestor.setValue(investor.firm, forKey: "firm")
        newInvestor.setValue(investor.title, forKey: "title")
        newInvestor.setValue(investor.metadata, forKey: "metadata")
        newInvestor.setValue(investor.contactInfo.city, forKey: "city")
        newInvestor.setValue(investor.contactInfo.email, forKey: "email")
        newInvestor.setValue(investor.contactInfo.state, forKey: "state")
        
        do {
            Analytics.logEvent("bookmark_saved", parameters: ["uid" : uid, "investor_id" : investor.id, "investor_name" : investor.fullName()])
            try context.save()
            storedInvestor = newInvestor as? LXInvestor
            bookmarkButton.isSelected = true
        } catch {
            Analytics.logEvent("bookmark_failed", parameters: ["uid" : uid, "investor_id" : investor.id, "investor_name" : investor.fullName()])
            print("Failed saving") //TODO: add failed to bookmark
        }
    }
    
    @IBAction func emailTouched(_ sender: Any) {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        Analytics.logEvent("email_touched", parameters: ["uid" : uid, "investor_id" : investor.id, "investor_name" : investor.fullName()])
        let composeVC = MFMailComposeViewController()

        composeVC.mailComposeDelegate = self
        composeVC.setToRecipients([investor.contactInfo.email])
        composeVC.setSubject("Put Your Subject Here - \(investor.first)")
        
        guard MFMailComposeViewController.canSendMail() else { //TODO: show mail error alert
            Analytics.logEvent("email_failed", parameters: ["uid" : uid, "investor_id" : investor.id, "investor_name" : investor.fullName()])
            return
        }
        
        composeVC.setMessageBody("Hey \(investor.first), \n How are you? I hope all is well! \n", isHTML: false)
        
        self.present(composeVC, animated: true, completion: nil)
    }
    
    @IBAction func closeTouched(_ sender: Any) {
        Analytics.logEvent("close_touched_investor", parameters: [:])
        dismiss()
    }
    
    public func dismiss() {
        view.endEditing(true)
        dismiss(animated: true, completion: nil)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}
