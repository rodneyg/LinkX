//
//  User.swift
//  LinkX
//
//  Created by Rodney Gainous Jr on 5/13/19.
//  Copyright © 2019 CodeSigned. All rights reserved.
//

import Foundation

struct User {
    
    let uid: String
    let username: String
    let profileImageUrl: String?
    let headline: String?
    let title: String?
    let company: String?
    let investorId: String?
    
    init(uid: String, dictionary: [String: Any]) {
        self.uid = uid
        self.username = dictionary["username"] as? String ?? ""
        self.profileImageUrl = dictionary["profileImageUrl"] as? String ?? nil
        self.headline = dictionary["headline"] as? String ?? nil
        self.title = dictionary["title"] as? String ?? nil
        self.company = dictionary["company"] as? String ?? nil
        self.investorId = dictionary["investorId"] as? String ?? ""
    }
}
