//
//  CSFirebaseUtils.swift
//  CodeSigned
//
//  Created by Rodney Gainous Jr on 6/9/19.
//  Copyright © 2019 CodeSigned. All rights reserved.
//

import Foundation
import Firebase

extension Auth {
    func createUser(withEmail email: String, firstName: String, lastName: String, password: String, image: UIImage?, completion: @escaping (Error?) -> ()) {
        if let user = Auth.auth().currentUser, user.isAnonymous {
            let credential = EmailAuthProvider.credential(withEmail: email, password: password)
            user.linkAndRetrieveData(with: credential) { (data, error) in
                guard let user = data?.user else { return }
                
                let userRecord = Database.database().reference().child("users").child(user.uid)
                userRecord.child("last_signin_at").setValue(ServerValue.timestamp())
                
                self.setupUser(uid: user.uid, firstName: firstName, lastName: lastName, image: image, completion: completion)
            }
        } else {
            Auth.auth().createUser(withEmail: email, password: password, completion: { (user, err) in
                if let err = err {
                    print("Failed to create user:", err)
                    completion(err)
                    return
                }
                guard let uid = user?.user.uid else { return }

                self.setupUser(uid: uid, firstName: firstName, lastName: lastName, image: image, completion: completion)
            })
        }
    }
    
    private func setupUser(uid: String, firstName: String, lastName: String, image: UIImage?, completion: @escaping (Error?) -> ()) {
        let point = Point(data: ["value" : 50.0, "notes" : "Starter Points", "created_at" : Date().timeIntervalSinceNow])
        Database.database().addPoint(withUID: uid, point: point) { (error) in
        }
        
        Database.database().createInviteCode(withUser: uid, firstName: firstName, lastName: lastName, completion: nil)
        
        if let image = image {
            Storage.storage().uploadUserProfileImage(image: image, completion: { (profileImageUrl) in
                self.uploadUser(withUID: uid, firstName: firstName, lastName: lastName, points: 0.0, profileImageUrl: profileImageUrl) {
                    completion(nil)
                }
            })
        } else {
            self.uploadUser(withUID: uid, firstName: firstName, lastName: lastName, points: 0.0) {
                completion(nil)
            }
        }
    }
    
    public func uploadUser(withUID uid: String, firstName: String, lastName: String, headline: String? = nil, title: String? = nil, company: String? = nil, points: Double? = nil, profileImageUrl: String? = nil, completion: @escaping (() -> ())) {
        var dictionaryValues: [String : Any] = ["first_name" : firstName, "last_name" : lastName]
        if profileImageUrl != nil {
            dictionaryValues["profile_image_url"] = profileImageUrl
        }
        
        if headline != nil {
            dictionaryValues["headline"] = headline
        }
        
        if title != nil {
            dictionaryValues["title"] = title
        }
        
        if company != nil {
            dictionaryValues["company"] = company
        }
        
        if points != nil {
            dictionaryValues["points"] = points
        }
        
        Database.database().reference().child("users").child(uid).updateChildValues(dictionaryValues, withCompletionBlock: { (err, ref) in
            if let err = err {
                print("Failed to upload user to database:", err)
                return
            }
            completion()
        })
    }
    
    private func addFund(withUID uid: String, contactMethod: String, city: String, state: String, stage: String, sectors: [String], email: String? = nil, completion: @escaping (() -> ())) {
        var dictionaryValues: [String : Any] = ["contact_method" : contactMethod, "city" : city, "state" : state, "stage" : stage]
        
        var sectorDict = [String : String]()
        sectors.forEach {
            sectorDict[$0] = $0
        }
        
        dictionaryValues["sectors"] = sectorDict
        
        if let email = email {
            dictionaryValues["email"] = email
        }
        
        let values = [uid: dictionaryValues]
        Database.database().reference().child("investors").updateChildValues(values, withCompletionBlock: { (err, ref) in
            if let err = err {
                print("Failed to upload user to database:", err)
                return
            }
            completion()
        })
    }
    
    
    private func addInvestor(withUID uid: String, firstName: String, lastName: String, title: String, fundName: String, email: String? = nil, completion: @escaping (() -> ())) {
        var dictionaryValues = ["firm" : fundName, "first" : firstName, "last" : lastName, title : "title"]
        if let email = email {
            dictionaryValues["email"] = email
        }
        
        let values = [uid: dictionaryValues]
        Database.database().reference().child("investors").updateChildValues(values, withCompletionBlock: { (err, ref) in
            if let err = err {
                print("Failed to upload user to database:", err)
                return
            }
            completion()
        })
    }
}

extension Storage {
    
    public func uploadUserProfileImage(image: UIImage, completion: @escaping (String) -> ()) {
        self.uploadProfileImage(directory: "profile_images", image: image, completion: completion)
    }
    
    public func uploadInvestorProfileImage(image: UIImage, completion: @escaping (String) -> ()) {
        self.uploadProfileImage(directory: "investor_profile_images", image: image, completion: completion)
    }
    
    private func uploadProfileImage(directory: String, image: UIImage, completion: @escaping (String) -> ()) {
        guard let uploadData = image.jpegData(compressionQuality: 1) else { return } //changed from 0.3
        
        let storageRef = Storage.storage().reference().child(directory).child(NSUUID().uuidString)
        
        storageRef.putData(uploadData, metadata: nil, completion: { (_, err) in
            if let err = err {
                print("Failed to upload profile image:", err)
                return
            }
            
            storageRef.downloadURL(completion: { (downloadURL, err) in
                if let err = err {
                    print("Failed to obtain download url for profile image:", err)
                    return
                }
                guard let profileImageUrl = downloadURL?.absoluteString else { return }
                completion(profileImageUrl)
            })
        })
    }
}

extension Database {
    
    //Contributions
    
    func fetchContributions(withUID uid: String, completion: @escaping ([Contribution]?, Error?) -> ()) {
        Database.database().reference().child("contributions").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            guard let children = snapshot.children.allObjects as? [DataSnapshot] else {
                completion([], nil)
                return
            }
            
            var newContributions = [Contribution]()
            for child in children {
                if let value = child.value as? [String : Any] {
                    newContributions.append(Contribution(dictionary: value))
                }
            }
            
            completion(newContributions, nil)
        }) { (err) in
           completion(nil, err)
        }
    }
    
    func addContribution(withUID uid: String, contribution: Contribution, completion: @escaping ((Error?) -> ())) {
        var dictionaryValues = ["firm" : contribution.firm, "first" : contribution.firstName, "last" : contribution.lastName, "title" : contribution.title, "status" : contribution.status, "created_at" : contribution.createdAt.timeIntervalSince1970, "updated_at" : contribution.updatedAt.timeIntervalSince1970] as [String : Any]
        if let email = contribution.email {
            dictionaryValues["email"] = email
        }
        
        if let profileImage = contribution.profileImageUrl {
            dictionaryValues["profile_image_url"] = profileImage
        }
        
        self.reference().child("contributions").child(uid).childByAutoId().updateChildValues(dictionaryValues, withCompletionBlock: { (err, ref) in
            if let err = err {
                completion(err)
                return
            }
            completion(nil)
        })
    }
    
    func addPoint(withUID uid: String, point: Point, completion: @escaping (Error?) -> ()) {
        var dictionaryValues : [String : Any] = ["value" : point.value, "created_at" : point.createdAt.timeIntervalSince1970]
        if let activity = point.activity {
            dictionaryValues["activity"] = activity.name
        }
        
        if let notes = point.notes {
            dictionaryValues["notes"] = notes
        }
        
        self.reference().child("points").child(uid).childByAutoId().updateChildValues(dictionaryValues, withCompletionBlock: { (err, ref) in
            if let err = err {
                completion(err)
                return
            }
            self.runPointTransaction(withUID: uid, point: point)
            completion(nil)
        })
    }
    
    func canPurchaseInvestor(uid: String, completion: @escaping (Bool) -> ()) {
        self.fetchUser(withUID: uid) { user in
            guard let points = user.points else {
                completion(false)
                return
            }
            
            completion(points >= 25.0) //investor costs 25.0 points
        }
    }
    
    func hasPurchasedInvestor(uid: String, investorId: String, completion: @escaping (Bool) -> ()) {
        Database.database().reference().child("transactions").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            guard let children = snapshot.children.allObjects as? [DataSnapshot] else {
                completion(false)
                return
            }
            
            var found = false
            children.forEach { child in
                if let value = child.value as? [String : Any] {
                    let transaction = Transaction(data: value)
                    if transaction.itemId == investorId {
                        found = true//found ivnestor
                        return
                    }
                }
            }
            
            completion(found)
        }) { (err) in
            print("Failed to fetch user from database:", err)
        }
    }
    
    func purchaseInvestorContact(uid: String, investorId: String, completion: @escaping (Transaction?, Error?) -> ()) {
        canPurchaseInvestor(uid: uid) { canPurchase in
            guard canPurchase else {
                completion(nil, nil)
                return
            }
            
            let dictionaryValues : [String : Any] = ["uid" : uid, "point_cost" : 25.0, "updated_at" : Date().timeIntervalSinceNow, "created_at" : Date().timeIntervalSince1970, "item_id" : investorId]
            self.reference().child("transactions").child(uid).childByAutoId().updateChildValues(dictionaryValues, withCompletionBlock: { (err, ref) in
                if let err = err {
                    completion(nil, err)
                    return
                }
                
                let point = Point(data: ["value" : -25.0, "activity" : LXConstants.PURCHASE_INVESTOR_CONTACT, "notes" : "Referred by User", "created_at" : Date().timeIntervalSinceNow])
                self.runPointTransaction(withUID: uid, point: point)
                
                completion(Transaction(data: dictionaryValues), nil)
            })
        }
    }

    func fetchUserPoints(withUID uid: String, completion: @escaping ([Point]) -> ()) {
        Database.database().reference().child("points").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            guard let children = snapshot.children.allObjects as? [DataSnapshot] else {
                completion([])
                return
            }
            
            var newPoints = [Point]()
            for child in children {
                if var value = child.value as? [String : Any] {
                   newPoints.append(Point(data: value))
                }
            }
            
            completion(newPoints)
        }) { (err) in
            print("Failed to fetch user from database:", err)
        }
    }
    
    private func runPointTransaction(withUID uid: String, point: Point) {
        let userRef = reference().child("users").child(uid)

        userRef.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            if var user = currentData.value as? [String : AnyObject] {
                let pointsCount : Double = user["points"] as? Double ?? 0.0
                let totalPoints = pointsCount + point.value
                user["points"] = NSNumber(value: totalPoints) as AnyObject

                // Set value and report transaction success
                currentData.value = user

                return TransactionResult.success(withValue: currentData)
            }
            return TransactionResult.success(withValue: currentData)
        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
    //MARK: Users
    
    func removeSpecialCharsFromString(text: String) -> String {
        let okayChars = Set("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890+-=().!_")
        return text.filter {okayChars.contains($0) }
    }
    
    func createInvestorLink(withInvestor investorKey: String,completion: ((String) -> ())?) {
        guard let link = URL(string: "https://linkx.page.link/?investor=\(investorKey)") else { return }
        
        let linkBuilder = DynamicLinkComponents(link: link, domainURIPrefix: "https://linkx.page.link")
        
        linkBuilder?.iOSParameters = DynamicLinkIOSParameters(bundleID: "com.ios.codesigned.LinkX")
        linkBuilder?.iOSParameters?.minimumAppVersion = "1.0"
        linkBuilder?.iOSParameters?.appStoreID = "1457507501"
        
        linkBuilder?.shorten() { url, warnings, error in
            if let error = error {
                print("Failed to create investor link:", error)
                return
            }
            
            guard let urlStr = url?.absoluteString else {
                print("Failed to create investor link:")
                return
            }
            
            print("The short URL is: \(url)")
            
            var dictionaryValues: [String : Any] = ["public_url" : urlStr]

            Database.database().reference().child("investors").child(investorKey).updateChildValues(dictionaryValues, withCompletionBlock: { (err, ref) in
                if let err = err {
                    print("Failed to upload user to database:", err)
                    return
                }
                
                completion?(urlStr)
            })
        }
    }
    
    func createInviteCode(withUser uid: String, firstName: String, lastName: String, completion: ((String) -> ())?) {
        let code = firstName.replacingOccurrences(of: " ", with: "") + String(lastName.first ?? "X")
        //random code between 1-900 i.e. rodneyg391
        let random = (Int.random(in: 1..<25) * Int.random(in: 1..<25)) + Int.random(in: 0..<100)
        let inviteCode = removeSpecialCharsFromString(text: "\(code)\(random)").lowercased()
        var dictionaryValues: [String : Any] = ["invite_code" : inviteCode]
        
        guard let link = URL(string: "https://linkx.page.link/?referredBy=\(inviteCode)") else { return }
        
        let linkBuilder = DynamicLinkComponents(link: link, domainURIPrefix: "https://linkx.page.link")
        
        linkBuilder?.iOSParameters = DynamicLinkIOSParameters(bundleID: "com.ios.codesigned.LinkX")
        linkBuilder?.iOSParameters?.minimumAppVersion = "1.0"
        linkBuilder?.iOSParameters?.appStoreID = "1457507501"
        
        linkBuilder?.shorten() { url, warnings, error in
            if let error = error {
                print("Failed to upload user to database:", error)
                return
            }
            
            print("The short URL is: \(url)")
            dictionaryValues["invite_code_url"] = url?.absoluteString
            
            Database.database().reference().child("users").child(uid).updateChildValues(dictionaryValues, withCompletionBlock: { (err, ref) in
                if let err = err {
                    print("Failed to upload user to database:", err)
                    return
                }
                
                completion?(inviteCode)
            })
        }
    }
    
    func fetchUserByInvite(code: String, completion: @escaping (String) -> ()) {
        Database.database().reference().child("users").queryOrdered(byChild: "invite_code").queryEqual(toValue: code.lowercased()).observeSingleEvent(of: .value, with: { (snapshot) in
            guard let value = snapshot.value as? [String : Any], let first = value.keys.first else { return }

            completion(first)
        }) { (err) in
            print("Failed to fetch user from database:", err)
        }
    }
    
    func fetchInvestor(withId investorKey: String, completion: @escaping (Investor) -> ()) {
        Database.database().reference().child("investors").child(investorKey).observeSingleEvent(of: .value, with: { (snapshot) in
            guard var userDictionary = snapshot.value as? [String: Any] else { return }
            userDictionary["key"] = snapshot.key
            let investor = Investor(data: userDictionary)
            completion(investor)
        }) { (err) in
            print("Failed to fetch user from database:", err)
        }
    }
    
    func fetchUser(withUID uid: String, completion: @escaping (User) -> ()) {
        Database.database().reference().child("users").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            guard let userDictionary = snapshot.value as? [String: Any] else { return }
            let user = User(uid: uid, dictionary: userDictionary)
            completion(user)
        }) { (err) in
            print("Failed to fetch user from database:", err)
        }
    }
}
