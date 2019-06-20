//
//  Review.swift
//  LinkX
//
//  Created by Rodney Gainous Jr on 6/19/19.
//  Copyright © 2019 CodeSigned. All rights reserved.
//

import Foundation

struct Review {
    
    let updatedAt: Date?
    let createdAt: Date?
    let reviewerId: String?
    let value: String?
    let recipientId: String?
    let id: String?
    
    init(dictionary: [String: Any]) {
        self.createdAt = dictionary["updated_at"] as? Date ?? nil
        self.updatedAt = dictionary["updated_at"] as? Date ?? nil
        self.reviewerId = dictionary["reviewer_id"] as? String ?? nil
        self.value = dictionary["value"] as? String ?? nil
        self.recipientId = dictionary["recipient_id"] as? String ?? ""
        self.id = dictionary["id"] as? String ?? ""
    }
}
