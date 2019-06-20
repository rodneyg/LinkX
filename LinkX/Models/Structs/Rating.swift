//
//  Rating.swift
//  LinkX
//
//  Created by Rodney Gainous Jr on 6/19/19.
//  Copyright © 2019 CodeSigned. All rights reserved.
//

import Foundation

struct Rating {
    
    let updatedAt: Date?
    let createdAt: Date?
    let reviewerId: String?
    let value: Double?
    let recipientId: String?
    let id: String?
    
    init(dictionary: [String: Any]) {
        self.createdAt = dictionary["updated_at"] as? Date ?? nil
        self.updatedAt = dictionary["updated_at"] as? Date ?? nil
        self.reviewerId = dictionary["reviewer_id"] as? String ?? nil
        self.value = dictionary["value"] as? Double ?? 0.0
        self.recipientId = dictionary["recipient_id"] as? String ?? ""
        self.id = dictionary["id"] as? String ?? ""
    }
}
