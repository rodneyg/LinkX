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
        Auth.auth().createUser(withEmail: email, password: password, completion: { (user, err) in
            if let err = err {
                print("Failed to create user:", err)
                completion(err)
                return
            }
            guard let uid = user?.user.uid else { return }
            if let image = image {
                Storage.storage().uploadUserProfileImage(image: image, completion: { (profileImageUrl) in
                    self.uploadUser(withUID: uid, firstName: firstName, lastName: lastName, points: 150.0, profileImageUrl: profileImageUrl) {
                        completion(nil)
                    }
                })
            } else {
                self.uploadUser(withUID: uid, firstName: firstName, lastName: lastName, points: 150.0) {
                    completion(nil)
                }
            }
        })
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
        
        let values = [uid : dictionaryValues]
        Database.database().reference().child("users").updateChildValues(values, withCompletionBlock: { (err, ref) in
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
            completion(nil)
        })
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
    
    func addPoint(withUID uid: String, point: Point) {
//        let userRef = reference().child("users").child(uid)
//
//        userRef.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
//            if var user = currentData.value as? [String : AnyObject], let uid = Auth.auth().currentUser?.uid {
//                var points: Dictionary<String, Bool>
//                points = user["points"] as? [String : Bool] ?? [:]
//                var pointsCount = user["pointCount"] as? Int ?? 0
//                if let _ = points[uid] {
//                    // Unstar the post and remove self from stars
//                    pointsCount -= 1
//                    points.removeValue(forKey: uid)
//                } else {
//                    // Star the post and add self to stars
//                    pointsCount += 1
//                    points[uid] = true
//                }
//                points["pointCount"] = pointsCount as AnyObject?
//                points["points"] = point as AnyObject?
//
//                // Set value and report transaction success
//                currentData.value = point
//
//                return TransactionResult.success(withValue: currentData)
//            }
//            return TransactionResult.success(withValue: currentData)
//        }) { (error, committed, snapshot) in
//            if let error = error {
//                print(error.localizedDescription)
//            }
//        }
    }
    
    //MARK: Users
    
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
