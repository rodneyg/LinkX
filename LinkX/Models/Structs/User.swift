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
    let firstName: String
    let lastName: String
    let profileImageUrl: String?
    let inviteCode: String?
    let inviteCodeUrl: String?
    let headline: String?
    let title: String?
    let company: String?
    let investorId: String?
    let lastRewardedAt: Double?
    let points: Double?
    
    init(uid: String, dictionary: [String: Any]) {
        self.uid = uid
        self.username = dictionary["username"] as? String ?? ""
        self.firstName = dictionary["first_name"] as? String ?? ""
        self.lastName = dictionary["last_name"] as? String ?? ""
        self.profileImageUrl = dictionary["profile_image_url"] as? String ?? nil
        self.inviteCode = dictionary["invite_code"] as? String ?? nil
        self.inviteCodeUrl = dictionary["invite_code_url"] as? String ?? nil
        self.headline = dictionary["headline"] as? String ?? nil
        self.title = dictionary["title"] as? String ?? nil
        self.company = dictionary["company"] as? String ?? nil
        self.lastRewardedAt = dictionary["last_rewarded_at"] as? Double ?? nil
        self.investorId = dictionary["investor_id"] as? String ?? ""
        self.points = dictionary["points"] as? Double ?? 0.0
    }
}
