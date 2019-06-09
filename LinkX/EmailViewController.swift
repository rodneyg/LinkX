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

class EmailViewController: UIViewController, MFMailComposeViewControllerDelegate, FUIAuthDelegate {
    
    public var investor: Investor!
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var firmLabel: UILabel!
    @IBOutlet var sendLabel: UILabel!
    @IBOutlet var loginButton: UIButton!
    @IBOutlet var bookmarkButton: UIButton!
    
    @IBOutlet var investorRating: CosmosView!
    @IBOutlet var ratingsLabel: UILabel!
    
    @IBOutlet var userRating: CosmosView!
    @IBOutlet var commentsText: UITextView!
    @IBOutlet var commentsHeight: NSLayoutConstraint!
    @IBOutlet var submitButton: UIButton!
    
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
            self.presentAuthentication()
            self.submitButton.isHidden = false
        }
        
        userRating.didFinishTouchingCosmos = { rating in
            guard Auth.auth().currentUser != nil else {
                self.userRating.rating = 0.0
                return //user is nil
            }
            
            self.submitButton.isEnabled = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        fetchUserRating(completion: { rating in
            self.userRating.isUserInteractionEnabled = false
            self.userRating.isHidden = false
            self.userRating.rating = rating
        }) { error in
            self.userRating.isHidden = false
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
        presentAuthentication()
    }
    
    func presentAuthentication() {
        guard let auth = authUI, Auth.auth().currentUser == nil else {
            return //auth ui is nil or user is already logged in
        }
        
        auth.delegate = self
        auth.providers = providers
        
        let authViewController = auth.authViewController()
        present(authViewController, animated: true, completion: nil)
    }
    
    private func authUI(_ authUI: FUIAuth, didSignInWith user: User?, error: Error?) {
        checkUser()
    }
    
    func checkUser() {
        guard let _ = Auth.auth().currentUser else {
            self.sendLabel.text = "Login To See Email"
            return // no user
        }
        
        sendLabel.text = investor.contactInfo.email
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
        UIPasteboard.general.string = investor.contactInfo.email
        //TODO: add show alert
    }
    
    @IBAction func bookmarkTouched(_ sender: Any) {
        let context = appDelegate.persistentContainer.viewContext

        guard storedInvestor == nil else { //investor already stored locally, delete bookmark
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
            try context.save()
            storedInvestor = newInvestor as? LXInvestor
            bookmarkButton.isSelected = true
        } catch {
            print("Failed saving") //TODO: add failed to bookmark
        }
    }
    
    @IBAction func emailTouched(_ sender: Any) {
        let composeVC = MFMailComposeViewController()

        composeVC.mailComposeDelegate = self
        composeVC.setToRecipients([investor.contactInfo.email])
        composeVC.setSubject("AirWave Mini - \(investor.first)")
        
        guard MFMailComposeViewController.canSendMail() else { //TODO: show mail error alert
            return
        }
        
        composeVC.setMessageBody("Hey \(investor.first), \n How are you? I hope all is well! \n", isHTML: false)
        
        self.present(composeVC, animated: true, completion: nil)
    }
    
    @IBAction func closeTouched(_ sender: Any) {
        dismiss()
    }
    
    public func dismiss() {
        view.endEditing(true)
        navigationController?.popViewController(animated: true)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}
