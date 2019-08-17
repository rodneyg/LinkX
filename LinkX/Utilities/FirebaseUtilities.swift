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
    
    fileprivate func uploadPostImage(image: UIImage, filename: String, completion: @escaping (String) -> ()) {
        guard let uploadData = image.jpegData(compressionQuality: 1) else { return } //changed from 0.5
        
        let storageRef = Storage.storage().reference().child("post_images").child(filename)
        storageRef.putData(uploadData, metadata: nil, completion: { (_, err) in
            if let err = err {
                print("Failed to upload post image:", err)
                return
            }
            
            storageRef.downloadURL(completion: { (downloadURL, err) in
                if let err = err {
                    print("Failed to obtain download url for post image:", err)
                    return
                }
                guard let postImageUrl = downloadURL?.absoluteString else { return }
                completion(postImageUrl)
            })
        })
    }
    
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
    
    func addFunds() {
        if let path = Bundle.main.path(forResource: "funds", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                if let jsonResult = jsonResult as? [Dictionary<String, AnyObject>] {
                    for json in jsonResult {
                        let name = json["Name"]
                        let city = json["City"]
                        let state = json["State"]
                        let site = json["Site"]
                        let stage = json["Stage"]
                        let contactMethod = json["Contact Method"]
                        var sectors = [String]()
                        if let sectorData = json["Sectors"] as? String {
                            sectorData.split(separator: ",").forEach { substring in
                                sectors.append(String(substring))
                            }
                        }
                        
                        let dictionaryValues = ["name" : name ?? "", "city" : city ?? "", "state" : state ?? "", "site" : site ?? "",
                                                "stage" : stage ?? "", "contact" : contactMethod ?? "", "sectors" : sectors] as [String : Any]
                        self.reference().child("funds").childByAutoId().updateChildValues(dictionaryValues, withCompletionBlock: { (err, ref) in
                            if let error = err {
                                print("error: " + error.localizedDescription)
                                return
                            }
                            print("added: \(String(describing: ref.key)): \(dictionaryValues)")
                        })
                    }
                }
            } catch {
                // handle error
            }
        }
    }
    
    func canPurchaseInvestor(uid: String, completion: @escaping (Bool) -> ()) {
        self.canPurchase(uid: uid, points: 25.0, completion: completion)
    }
    
    func canPurchaseFund(uid: String, completion: @escaping (Bool) -> ()) {
        self.canPurchase(uid: uid, points: 15.0, completion: completion)
    }
    
    func canPurchase(uid: String, points: Double, completion: @escaping (Bool) -> ()) {
        self.fetchUser(withUID: uid) { user in
            guard let points = user.points else {
                completion(false)
                return
            }
            
            completion(points >= points) //funds costs 15.0 points
        }
    }
    
    func hasPurchasedFund(uid: String, fundId: String, completion: @escaping (Bool) -> ()) {
        self.hasPurchasedItem(uid: uid, itemId: fundId, completion: completion)
    }
    
    func hasPurchasedInvestor(uid: String, investorId: String, completion: @escaping (Bool) -> ()) {
        self.hasPurchasedItem(uid: uid, itemId: investorId, completion: completion)
    }
    
    func hasPurchasedItem(uid: String, itemId: String, completion: @escaping (Bool) -> ()) {
        Database.database().reference().child("transactions").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            guard let children = snapshot.children.allObjects as? [DataSnapshot] else {
                completion(false)
                return
            }
            
            var found = false
            children.forEach { child in
                if let value = child.value as? [String : Any] {
                    let transaction = Transaction(data: value)
                    if !itemId.isEmpty && transaction.itemId == itemId {
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
        self.purchase(uid: uid, itemId: investorId, points: 25.0, completion: completion)
    }
    
    func purchaseFundContact(uid: String, fundId: String, completion: @escaping (Transaction?, Error?) -> ()) {
        self.purchase(uid: uid, itemId: fundId, points: 25.0, completion: completion)
    }
    
    func purchase(uid: String, itemId: String, points: Double, completion: @escaping (Transaction?, Error?) -> ()) {
        canPurchaseInvestor(uid: uid) { canPurchase in
            let moneyMonday: Bool = (Date().dayNumberOfWeek() == 1)
            guard canPurchase || moneyMonday else {
                completion(nil, nil)
                return
            }
            
            let dictionaryValues : [String : Any] = ["uid" : uid, "point_cost" : moneyMonday ? 0 : points, "updated_at" : Date().timeIntervalSinceNow, "created_at" : Date().timeIntervalSince1970, "item_id" : itemId]
            self.reference().child("transactions").child(uid).childByAutoId().updateChildValues(dictionaryValues, withCompletionBlock: { (err, ref) in
                if let err = err {
                    completion(nil, err)
                    return
                }
                
                let point = Point(data: ["value" : -points, "activity" : LXConstants.PURCHASE_INVESTOR_CONTACT, "notes" : "Referred by User", "created_at" : Date().timeIntervalSinceNow])
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
    
    public func runViewTransaction(post: Post) {
        guard let postId = post.id, let uid = post.uid else { return }
        
        let postRef = Database.database().reference().child("posts").child(uid).child(postId)
        
        postRef.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            if var postData = currentData.value as? [String : AnyObject] {
                var viewCount : Int? = postData["views"] as? Int

                if viewCount == nil {
                    viewCount = 1
                } else {
                    viewCount = viewCount! + 1
                }
                
                postData["views"] = viewCount as? AnyObject
                currentData.value = postData
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
    
    func createFundLink(withInvestor fundKey: String,completion: ((String) -> ())?) {
        guard let link = URL(string: "https://linkx.page.link/?fund=\(fundKey)") else { return }
        
        let linkBuilder = DynamicLinkComponents(link: link, domainURIPrefix: "https://linkx.page.link")
        
        linkBuilder?.iOSParameters = DynamicLinkIOSParameters(bundleID: "com.ios.codesigned.LinkX")
        linkBuilder?.iOSParameters?.minimumAppVersion = "1.0"
        linkBuilder?.iOSParameters?.appStoreID = "1457507501"
        
        linkBuilder?.shorten() { url, warnings, error in
            if let error = error {
                print("Failed to create fund link:", error)
                return
            }
            
            guard let urlStr = url?.absoluteString else {
                print("Failed to create fund link:")
                return
            }
            
            print("The short URL is: \(url)")
            
            var dictionaryValues: [String : Any] = ["public_url" : urlStr]
            
            Database.database().reference().child("funds").child(fundKey).updateChildValues(dictionaryValues, withCompletionBlock: { (err, ref) in
                if let err = err {
                    print("Failed to create fund link:", err)
                    return
                }
                
                completion?(urlStr)
            })
        }
    }
    
    func createPostLink(withPost post: Post, postId: String, uid: String, completion: ((String) -> ())?) {
        guard let pUrl = post.url, let link = URL(string: "https://linkx.page.link/?post=\(postId)") else { return }
        
        let linkBuilder = DynamicLinkComponents(link: link, domainURIPrefix: "https://linkx.page.link")
        
        linkBuilder?.iOSParameters = DynamicLinkIOSParameters(bundleID: "com.ios.codesigned.LinkX")
        linkBuilder?.iOSParameters?.minimumAppVersion = "1.0"
        linkBuilder?.iOSParameters?.appStoreID = "1457507501"
        linkBuilder?.iOSParameters?.fallbackURL = URL(string: pUrl)
        
        linkBuilder?.socialMetaTagParameters = DynamicLinkSocialMetaTagParameters()
        linkBuilder?.socialMetaTagParameters?.descriptionText = "LinkX News"
        linkBuilder?.socialMetaTagParameters?.descriptionText = post.title
        linkBuilder?.socialMetaTagParameters?.imageURL = URL(string: post.image ?? "")
        
        linkBuilder?.otherPlatformParameters?.fallbackUrl = URL(string: pUrl)
        
        linkBuilder?.shorten() { url, warnings, error in
            if let error = error {
                print("Failed to create post link:", error)
                return
            }
            
            guard let urlStr = url?.absoluteString else {
                print("Failed to create post link:")
                return
            }
            
            print("The short URL is: \(url)")
            
            let dictionaryValues: [String : Any] = ["public_url" : urlStr]
            
            Database.database().reference().child("posts").child(uid).child(postId).updateChildValues(dictionaryValues, withCompletionBlock: { (err, ref) in
                if let err = err {
                    print("Failed to upload user to database:", err)
                    return
                }
                
                completion?(urlStr)
            })
        }
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
    
    func createPostRef(withPost postId: String, uid: String, completion: @escaping (Error?) -> ()) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let userPostRef = Database.database().reference().child("all_posts").childByAutoId()
        
        let values = ["id" : postId, "created_at" : Date().timeIntervalSince1970, "uid" : uid] as [String : Any]
        
        userPostRef.updateChildValues(values) { (err, ref) in
            if let err = err {
                print("Failed to save post to database", err)
                completion(err)
                return
            }
        }
    }
    
    func createPost(withPost post: Post, completion: @escaping (Error?) -> ()) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let userPostRef = Database.database().reference().child("posts").child(uid).childByAutoId()
        
        guard let postId = userPostRef.key else { return }
        
        let values = ["image" : post.image ?? "", "icon" : post.icon ?? "", "url" : post.url ?? "", "canonical_url" : post.canonicalUrl ?? "", "title" : post.title ?? "",
                      "final_url" : post.finalUrl ?? "", "uid" : uid, "views" : 1, "id" : postId, "created_at" : Date().timeIntervalSince1970] as [String : Any]
        
        userPostRef.updateChildValues(values) { (err, ref) in
            if let err = err {
                print("Failed to save post to database", err)
                completion(err)
                return
            }
            
            self.createPostRef(withPost: postId, uid: uid, completion: completion)
            
            self.createPostLink(withPost: post, postId: postId, uid: uid, completion: { link in
                completion(nil)
            })
        }
    }
    
    func fetchAllPostIDsFromToday(completion: @escaping ([String]) -> (), withCancel cancel: ((Error) -> ())? = nil) {
        guard let currentLoggedInUser = Auth.auth().currentUser?.uid else { return }
        
        let ref = Database.database().reference().child("all_posts").queryOrdered(byChild: "created_at").queryStarting(atValue: Date().startOfDay.timeIntervalSince1970).queryEnding(atValue: Date().tomorrow!.timeIntervalSince1970)
        
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let dictionaries = snapshot.value as? [String: Any] else {
                completion([])
                return
            }
            
            var posts = [String]()
            
            dictionaries.forEach({ (arg) in
                let (postId, value) = arg
                guard let dict = value as? [String : Any], let id = dict["id"] as? String,
                    let uid = dict["uid"] as? String else { return }
                
                posts.append(id)
                
                if posts.count == dictionaries.count {
                    completion(posts)
                }
            })
        }) { (err) in
            print("Failed to fetch posts:", err)
            cancel?(err)
        }
    }
    
    func fetchAllPostsFromPastWeek(completion: @escaping (Post) -> (), withCancel cancel: ((Error) -> ())? = nil) {
        guard let currentLoggedInUser = Auth.auth().currentUser?.uid else { return }
        
        let ref = Database.database().reference().child("all_posts").queryOrdered(byChild: "created_at").queryStarting(atValue: Date().lastWeek!.timeIntervalSince1970).queryEnding(atValue: Date().tomorrow!.timeIntervalSince1970)
        
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let dictionaries = snapshot.value as? [String: Any] else {
                return
            }
            
            dictionaries.forEach({ (arg) in
                let (postId, value) = arg
                guard let dict = value as? [String : Any], let id = dict["id"] as? String,
                    let uid = dict["uid"] as? String else { return }
                
                Database.database().fetchPost(withUID: uid, postId: id, completion: { (post) in
                    //posts.append(post)
                    completion(post)
//
//                    if posts.count == dictionaries.count {
//                        completion(posts)
//                    }
                })
            })
        }) { (err) in
            print("Failed to fetch posts:", err)
            cancel?(err)
        }
    }
    
    func fetchPost(postId: String, completion: @escaping (Post) -> ()) {
        let ref = Database.database().reference().child("all_posts")
        
        ref.queryOrdered(byChild: "id").queryEqual(toValue: postId)
            .observeSingleEvent(of: .value, with: { snapshot in
                guard let data = snapshot.children.allObjects.first as? DataSnapshot else { return }
                
                guard let postRefDictionary = data.value as? [String : Any] else { return }
                
                guard let id = postRefDictionary["id"] as? String,
                    let uid = postRefDictionary["uid"] as? String else { return }
                
                Database.database().fetchPost(withUID: uid, postId: id, completion: { (post) in
                    completion(post)
                })
            })
    }
    
    func fetchPost(withUID uid: String, postId: String, completion: @escaping (Post) -> (), withCancel cancel: ((Error) -> ())? = nil) {
        guard let currentLoggedInUser = Auth.auth().currentUser?.uid else { return }
        
        let ref = Database.database().reference().child("posts").child(uid).child(postId)
        
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard let postDictionary = snapshot.value as? [String: Any] else { return }
            
            Database.database().fetchUser(withUID: uid, completion: { (user) in
                var post = Post(user: user, data: postDictionary)
                post.id = postId
                
                //check skeptical and shocked
                //create reactions object to lower the amount of calls
                //you can do up to three reactions total per post
                //create reaction animation
                // reactions : { "claps" : 1, "skeptical" : 2, "shocked" : 2 }
                Database.database().reference().child("claps").child(postId).child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
                    if let value = snapshot.value as? Int, value == 1 {
                        post.clappedByCurrentUser = true
                    } else {
                        post.clappedByCurrentUser = false
                    }
                    
                    Database.database().numberOfClapsForPost(withPostId: postId, completion: { (count) in
                        post.claps = count
                        completion(post)
                    })
                }, withCancel: { (err) in
                    print("Failed to fetch like info for post:", err)
                    cancel?(err)
                })
            })
        })
    }
    
    func fetchAllPosts(withUID uid: String, completion: @escaping ([Post]) -> (), withCancel cancel: ((Error) -> ())?) {
        let ref = Database.database().reference().child("posts").child(uid)
        
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let dictionaries = snapshot.value as? [String: Any] else {
                completion([])
                return
            }
            
            var posts = [Post]()
            
            dictionaries.forEach({ (arg) in
                let (postId, value) = arg
                Database.database().fetchPost(withUID: uid, postId: postId, completion: { (post) in
                    posts.append(post)
                    
                    if posts.count == dictionaries.count {
                        completion(posts)
                    }
                })
            })
        }) { (err) in
            print("Failed to fetch posts:", err)
            cancel?(err)
        }
    }
    
    func deletePost(withUID uid: String, postId: String, completion: ((Error?) -> ())? = nil) {
        Database.database().reference().child("posts").child(uid).child(postId).removeValue { (err, _) in
            if let err = err {
                print("Failed to delete post:", err)
                completion?(err)
                return
            }
            
            self.deleteComments(postId: postId)
            self.deleteReactions(postId: postId)
        }
    }
    
    func deleteComments(postId: String, completion: ((Error?) -> ())? = nil) {
        Database.database().reference().child("comments").child(postId).removeValue(completionBlock: { (err, _) in
            if let err = err {
                print("Failed to delete comments on post:", err)
                completion?(err)
                return
            }
            
            completion?(nil)
        })
    }
    
    func deleteReactions(postId: String, completion: ((Error?) -> ())? = nil) {
        self.deleteReaction(reaction: "claps", postId: postId)
        self.deleteReaction(reaction: "skeptical", postId: postId)
        self.deleteReaction(reaction: "shocked", postId: postId)
    }
    
    //claps // skeptical // shocked
    func deleteReaction(reaction: String, postId: String, completion: ((Error?) -> ())? = nil) {
        Database.database().reference().child(reaction).child(postId).removeValue(completionBlock: { (err, _) in
            if let err = err {
                print("Failed to delete likes on post:", err)
                completion?(err)
                return
            }
            
            Storage.storage().reference().child("post_images").child(postId).delete(completion: { (err) in
                if let err = err {
                    print("Failed to delete post image from storage:", err)
                    completion?(err)
                    return
                }
            })
            
            completion?(nil)
        })
    }
    
    func isPostReported(withId postId: String, completion: @escaping (Bool) -> (), withCancel cancel: ((Error) -> ())?) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        
        Database.database().reference().child("reports").child(currentLoggedInUserId).child("posts").observeSingleEvent(of: .value, with: { (snapshot) in
            if let isBlocked = snapshot.value as? Int, isBlocked == 1 {
                completion(true)
            } else {
                completion(false)
            }
            
        }) { (err) in
            print("Failed to check if following:", err)
            cancel?(err)
        }
    }
    
    func reportPost(withId postId: String, postCreatorId: String, reason: String, completion: @escaping (Error?) -> ()) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let values = ["reason": reason, "creationDate": Date().timeIntervalSince1970, "uid": uid, "postCreatorId" : postCreatorId] as [String: Any]
        
        let commentsRef = Database.database().reference().child("reports").child(uid).child("posts").child(postId).childByAutoId()
        commentsRef.updateChildValues(values) { (err, _) in
            if let err = err {
                print("Failed to add comment:", err)
                completion(err)
                return
            }
            completion(nil)
        }
    }
    
    //MARK: Utilities
    
    func numberOfPostsForUser(withUID uid: String, completion: @escaping (Int) -> ()) {
        Database.database().reference().child("posts").child(uid).observeSingleEvent(of: .value) { (snapshot) in
            if let dictionaries = snapshot.value as? [String: Any] {
                completion(dictionaries.count)
            } else {
                completion(0)
            }
        }
    }
    
    func numberOfClapsForPost(withPostId postId: String, completion: @escaping (Int) -> ()) {
        self.numberOfForPost(withName: "claps", postId: postId, completion: completion)
    }
    
    func numberOfSkepticalForPost(withPostId postId: String, completion: @escaping (Int) -> ()) {
        self.numberOfForPost(withName: "skeptical", postId: postId, completion: completion)
    }
    
    func numberOfShockedForPost(withPostId postId: String, completion: @escaping (Int) -> ()) {
        self.numberOfForPost(withName: "shock", postId: postId, completion: completion)
    }
    
    func numberOfForPost(withName name: String, postId: String, completion: @escaping (Int) -> ()) {
        Database.database().reference().child(name).child(postId).observeSingleEvent(of: .value) { (snapshot) in
            if let dictionaries = snapshot.value as? [String: Any] {
                completion(dictionaries.count)
            } else {
                completion(0)
            }
        }
    }
}
