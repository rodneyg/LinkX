//
//  Contribution.swift
//  LinkX
//
//  Created by Rodney Gainous Jr on 6/25/19.
//  Copyright © 2019 CodeSigned. All rights reserved.
//

import Foundation

struct Contribution {
    var firstName: String
    var lastName: String
    var firm: String
    var title: String
    var status: String
    var email: String?
    var type: String //Investor, Fund
    var reviewerId: String
    var createdAt: Date
    var updatedAt: Date
    var profileImageUrl: String?
    
    init(dictionary: [String: Any]) {
        self.firstName = dictionary["first"] as? String ?? ""
        self.lastName = dictionary["last"] as? String ?? ""
        self.title = dictionary["title"] as? String ?? ""
        self.firm = dictionary["firm"] as? String ?? ""
        self.status = dictionary["status"] as? String ?? ""
        self.reviewerId = dictionary["reviewer_id"] as? String ?? ""
        self.type = dictionary["type"] as? String ?? ""
        self.email = dictionary["contact_method"] as? String
        self.profileImageUrl = dictionary["profile_image_url"] as? String
        
        let createdAtSeconds = (dictionary["created_at"]  as? Double ?? 0)
        self.createdAt = Date(timeIntervalSince1970: createdAtSeconds)
        
        let updatedAtSconds = (dictionary["updated_at"]  as? Double ?? 0)
        self.updatedAt = Date(timeIntervalSince1970: updatedAtSconds)
    }
}
