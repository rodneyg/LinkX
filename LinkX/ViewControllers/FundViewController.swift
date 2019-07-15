//
//  FundViewController.swift
//  LinkX
//
//  Created by Rodney Gainous Jr on 7/11/19.
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

class FundViewController: UIViewController, MFMailComposeViewControllerDelegate, FUIAuthDelegate {
    
    public var fund: Fund!
    public var loggedIn: Bool = false
    public var purchased: Bool = false
    public var canPurchase: Bool = false
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var sendLabel: UILabel!
    @IBOutlet var loginButton: UIButton!
    @IBOutlet var bookmarkButton: UIButton!
    
    @IBOutlet var contactView: UIStackView!
        
    public var onSigninTouched: ((UIViewController) -> ())?
    
    private var storedFund: LXFund?
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    let db = Firestore.firestore()
    let authUI = FUIAuth.defaultAuthUI()
    let providers: [FUIAuthProvider] = [
        FUIEmailAuth()
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()

//        if fund.publicUrl == nil && fund.id != nil {
//            Database.database().createInvestorLink(withInvestor: fund.id) { url in
//                self.fund.publicUrl = url
//            }
//        }
        
        checkUser()
        fetchFund()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        checkUser()
        
        nameLabel.text = fund.name
        titleLabel.text = "\(fund.stage)"
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
            
            let purchaseAlert = UIAlertController(title: "Confirm Purchase", message: "Access to this contact is 15 points. Are you sure you want to continue?", preferredStyle: .alert)
            
            purchaseAlert.addAction(UIAlertAction(title: "Yes, Purchase", style: .default, handler: { (action: UIAlertAction!) in
                HUD.flash(.progress, onView: self.view, delay: 60.0, completion: nil)
                
                Database.database().purchaseFundContact(uid: uid, fundId: self.fund.id, completion: { (transaction, error) in
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
                    self.sendLabel.text = self.fund.contact
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
            self.sendLabel.text = self.splitEmail(email: self.fund.contact)
            return // no user
        }
        
        Database.database().hasPurchasedFund(uid: user.uid, fundId: fund.id) { hasPurchasedFund in
            self.purchased = hasPurchasedFund
            
            if hasPurchasedFund {
                self.contactView.isHidden = false
                self.loginButton.isHidden = true
                self.sendLabel.text = self.fund.contact
            } else {
                Database.database().canPurchaseFund(uid: user.uid, completion: { canPurchase in
                    self.canPurchase = canPurchase
                    
                    if canPurchase {
                        self.loginButton.isHidden = false
                        self.contactView.isHidden = false
                        self.loginButton.setTitle("Access for 15 Points", for: .normal)
                        self.sendLabel.text = self.splitEmail(email: self.fund.contact)
                        return // no user
                    } else {
                        self.loginButton.isHidden = false
                        self.contactView.isHidden = true
                        self.loginButton.setTitle("Earn Points To Access", for: .normal)
                        self.sendLabel.text = self.splitEmail(email: self.fund.contact)
                        return // no user
                    }
                })
            }
        }
    }
    
    public func fetchFund() {
        let context = appDelegate.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "LXFund")
        request.predicate = NSPredicate(format: "id = %@", fund.id)
        request.returnsObjectsAsFaults = false
        
        do {
            let result = try context.fetch(request)
            guard let funds = result as? [LXFund], let fetchedFund = funds.first else {
                return //investor selected is not stored locally
            }
            
            self.storedFund = fetchedFund
            self.bookmarkButton.isSelected = true //stored investors are bookmarked
        } catch {
            print("Failed")
        }
    }
    
    @IBAction func shareTouched(_ sender: Any) {
        guard let uid = Auth.auth().currentUser?.uid, let publicUrl = fund.publicUrl else {
            return
        }
        
        Analytics.logEvent("share_touched", parameters: ["uid" : uid, "fund_id" : fund.id, "fund_name" : fund.name])
        
        // text to share
        let text = "Hey. Check out \(fund.name) on LinkX on iOS! \(publicUrl)"
        
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
        
        Analytics.logEvent("clipboard_touched", parameters: ["uid" : uid, "fund_id" : fund.id, "fund_name" : fund.name])
        UIPasteboard.general.string = self.fund.contact
        //TODO: add show alert
    }
    
    @IBAction func bookmarkTouched(_ sender: Any) {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        let context = appDelegate.persistentContainer.viewContext
        
        Analytics.logEvent("bookmark_touched", parameters: ["uid" : uid, "fund_id" : fund.id, "fund_name" : fund.name])
        
        guard storedFund == nil else { //investor already stored locally, delete bookmark
            Analytics.logEvent("delete_bookmark", parameters: ["uid" : uid, "fund_id" : fund.id, "fund_name" : fund.name])
            context.delete(storedFund!)
            bookmarkButton.isSelected = false
            storedFund = nil
            return
        }
        
        let entity = NSEntityDescription.entity(forEntityName: "LXFund", in: context)
        let newFund = NSManagedObject(entity: entity!, insertInto: context)
        
        newFund.setValue(fund.id, forKey: "id")
        newFund.setValue(fund.name, forKey: "name")
        newFund.setValue(fund.city, forKey: "city")
        newFund.setValue(fund.state, forKey: "state")
        newFund.setValue(fund.stage, forKey: "stage")
        
        do {
            Analytics.logEvent("bookmark_saved", parameters: ["uid" : uid, "fund_id" : fund.id, "fund_name" : fund.name])
            try context.save()
            storedFund = newFund as? LXFund
            bookmarkButton.isSelected = true
        } catch {
            Analytics.logEvent("bookmark_failed", parameters: ["uid" : uid, "fund_id" : fund.id, "fund_name" : fund.name])
            print("Failed saving") //TODO: add failed to bookmark
        }
    }
    
    @IBAction func emailTouched(_ sender: Any) {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        Analytics.logEvent("email_touched", parameters: ["uid" : uid, "fund_id" : fund.id, "fund_name" : fund.name])
        let composeVC = MFMailComposeViewController()
        
        composeVC.mailComposeDelegate = self
        composeVC.setToRecipients([fund.contact])
        composeVC.setSubject("Put Your Subject Here - \(fund.name)")
        
        guard MFMailComposeViewController.canSendMail() else { //TODO: show mail error alert
            Analytics.logEvent("email_failed", parameters: ["uid" : uid, "fund_id" : fund.id, "fund_name" : fund.name])
            return
        }
        
        composeVC.setMessageBody("Hey \(fund.name), \n How are you? I hope all is well! \n", isHTML: false)
        
        self.present(composeVC, animated: true, completion: nil)
    }
    
    @IBAction func closeTouched(_ sender: Any) {
        Analytics.logEvent("close_touched", parameters: [:])
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
