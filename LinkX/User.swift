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
    let investor: Bool?
    
    init(uid: String, dictionary: [String: Any]) {
        self.uid = uid
        self.username = dictionary["username"] as? String ?? ""
        self.profileImageUrl = dictionary["profileImageUrl"] as? String ?? nil
        self.investor = dictionary["investor"] as? Bool ?? nil
    }
}
