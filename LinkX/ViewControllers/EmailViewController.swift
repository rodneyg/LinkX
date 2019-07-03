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
    public var loggedIn: Bool = false
    public var purchased: Bool = false
    public var canPurchase: Bool = false
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var firmLabel: UILabel!
    @IBOutlet var sendLabel: UILabel!
    @IBOutlet var loginButton: UIButton!
    @IBOutlet var bookmarkButton: UIButton!
    
    @IBOutlet var investorRating: CosmosView!
    @IBOutlet var ratingsLabel: UILabel!
    @IBOutlet var contactView: UIStackView!
    
    var lastRating: Double?
    
    @IBOutlet var userRating: CosmosView!
    @IBOutlet var commentsText: UITextView!
    @IBOutlet var commentsHeight: NSLayoutConstraint!
    @IBOutlet var submitButton: UIButton!
    
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
        
        commentsHeight.constant = 0
        
        checkUser()
        fetchInvestor()

        userRating.didTouchCosmos = { rating in
            Analytics.logEvent("touched_rating", parameters: ["rating" : rating])

            if rating == self.lastRating {
                Analytics.logEvent("touched_rating_double", parameters: [:])

                self.lastRating = 0
                self.userRating.rating = 0
            }
            
            self.onSigninTouched?(self)
            //self.submitButton.isHidden = false
        }
        
        userRating.didFinishTouchingCosmos = { rating in
            guard Auth.auth().currentUser != nil else {
                self.userRating.rating = 0.0
                return //user is nil
            }
            
            //self.submitButton.isEnabled = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        fetchUserRating(completion: { rating in
            self.userRating.isUserInteractionEnabled = false
            //self.userRating.isHidden = false
            //self.userRating.rating = rating
        }) { error in
            //self.userRating.isHidden = false
            //TODO: handle error
        }
        
        fetchRating()
        
        nameLabel.text = investor.fullName()
        titleLabel.text = investor.title
        firmLabel.text = investor.firm
        ratingsLabel.text = "\(investor.rating.numOfRatings) ratings"
        investorRating.rating = investor.rating.avgRating
    }
    
    @IBAction func loginTouched(_ sender: Any) {
        guard let uid = Auth.auth().currentUser?.uid else {
            onSigninTouched?(self)
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
                    
                    self.contactView.isUserInteractionEnabled = true
                    self.sendLabel.text = self.investor.contactInfo.email
                    HUD.flash(.success, delay: 2.5)
                })
            }))
            
            purchaseAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            }))
            
            self.present(purchaseAlert, animated: true, completion: nil)
        } else { //logged in and can't purchase
            tabBarController?.selectedIndex = 4 // go to earn points
        }
    }
    
    private func authUI(_ authUI: FUIAuth, didSignInWith user: User?, error: Error?) {
        checkUser()
    }
    
    func checkUser() {
        guard let user = Auth.auth().currentUser else {
            self.contactView.isUserInteractionEnabled = false
            self.sendLabel.text = "Login To See Contact Details"
            return // no user
        }
        
        Database.database().hasPurchasedInvestor(uid: user.uid, investorId: investor.id) { hasPurchasedInvestor in
            self.purchased = hasPurchasedInvestor
            
            if hasPurchasedInvestor {
                self.contactView.isUserInteractionEnabled = true
                self.sendLabel.text = self.investor.contactInfo.email
            } else {
                Database.database().canPurchaseInvestor(uid: user.uid, completion: { canPurchase in
                    self.canPurchase = canPurchase
                    
                    if canPurchase {
                        self.contactView.isUserInteractionEnabled = true
                        self.sendLabel.text = "Spend 25 Points To See Contact Details"
                        return // no user
                    } else {
                        self.contactView.isUserInteractionEnabled = false
                        self.sendLabel.text = "Earn Points To See Contact Details"
                        return // no user
                    }
                })
            }
        }
    }
    
    public func fetchRating() {
        let ref = Database.database().reference().child("ratings").child(investor.id)
        
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let ratings = snapshot.value as? [String : Any] else {
                return
            }
            
            let numOfRatings = ratings["num_of_ratings"] as? Int
            let avgRating = ratings["avg_rating"] as? Double
            
            self.ratingsLabel.text = "\(numOfRatings ?? 0) ratings"
            self.investorRating.rating = avgRating ?? 0.0
        }) { (err) in
            print("Failed to fetch ratings:", err)
        }
    }
    
    public func fetchUserRating(completion: @escaping (Double) -> (), withCancel cancel: ((Error?) -> ())?) {
        guard let user = Auth.auth().currentUser else {
            cancel?(nil)
            return
        }
        
        let userRating = db.collection("ratings").whereField("sender_id", isEqualTo: user.uid).whereField("user_id", isEqualTo: investor.id)
        userRating.getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                cancel?(err)
            } else {
                guard let document = querySnapshot!.documents.first else {
                    cancel?(err)
                    return // no rating found for user
                }
                
                var docData = document.data()
                let rating = (docData["value"] as? Double) ?? 0.0
                completion(rating)
            }
        }
    }
    
    public func updateAndIncrementUserRating() {
        let ref = Database.database().reference().child("ratings").child(investor.id)

        ref.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            if var rating = currentData.value as? [String : AnyObject] {
                var ratingCount = rating["num_of_ratings"] as? Int ?? 0
                
                ratingCount += 1
                
                rating["num_of_ratings"] = ratingCount as AnyObject?
                rating["avg_rating"] = 0 as AnyObject?
                
                // Set value and report transaction success
                currentData.value = rating
                
                return TransactionResult.success(withValue: currentData)
            }
            return TransactionResult.success(withValue: currentData)
        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
    public func addRating(rating: Double, completion: @escaping () -> (), withCancel cancel: ((Error) -> ())?) {
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        var ref: DocumentReference? = nil
        
        // Add a document with a generated ID.
        ref = db.collection("ratings").addDocument(data: [
            "comment": "",
            "user_id" : investor.id,
            "sender_id": user.uid,
            "timestamp": Date().timeIntervalSince1970,
            "value": rating
        ]) { err in
            if let err = err {
                cancel?(err)
                print("Error adding document: \(err)")
            } else {
                completion()
                print("Document added with ID: \(ref!.documentID)")
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
    
    @IBAction func submitTouched(_ sender: Any) {
        addRating(rating: userRating.rating, completion: {
            self.userRating.isUserInteractionEnabled = false
            
            self.updateAndIncrementUserRating()
        }) { error in
            //TODO: handle error
        }
    }
    
    @IBAction func shareTouched(_ sender: Any) {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        Analytics.logEvent("share_touched", parameters: ["uid" : uid, "investor_id" : investor.id, "investor_name" : investor.fullName()])

        // text to share
        let text = "Hey. Here is the e-mail for \(investor.first) \(investor.last): \(investor.contactInfo.email) \n I found it using LinkX on iOS!"
        
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
