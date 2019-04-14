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

class EmailViewController: UIViewController, MFMailComposeViewControllerDelegate {
    
    public var investor: Investor!
    
    @IBOutlet var sendLabel: UILabel!
    @IBOutlet var bookmarkButton: UIButton!
    
    private var storedInvestor: LXInvestor?
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchInvestor()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        sendLabel.text = investor.contactInfo.email
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
            return
        }
        
        let entity = NSEntityDescription.entity(forEntityName: "LXInvestor", in: context)
        let newInvestor = NSManagedObject(entity: entity!, insertInto: context)
        
        newInvestor.setValue(investor.first, forKey: "first")
        newInvestor.setValue(investor.last, forKey: "last")
        newInvestor.setValue(investor.first, forKey: "firm")
        newInvestor.setValue(investor.title, forKey: "title")
        newInvestor.setValue(investor.metadata, forKey: "metadata")
        newInvestor.setValue(investor.contactInfo.city, forKey: "city")
        newInvestor.setValue(investor.contactInfo.email, forKey: "email")
        newInvestor.setValue(investor.contactInfo.state, forKey: "state")
        
        do {
            try context.save()
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
