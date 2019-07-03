//
//  Transaction.swift
//  LinkX
//
//  Created by Rodney Gainous Jr on 7/2/19.
//  Copyright © 2019 CodeSigned. All rights reserved.
//

import Foundation

public struct Transaction {
    public var id: String?
    public var createdAt: Double?
    public var updatedAt: Double?
    public var notes: String?
    public var pointCost: Double?
    public var itemId: String?
    public var uid: String?
    
    init(data: [String : Any]) {
        self.id = (data["id"] as? String) ?? ""
        
        self.createdAt = (data["created_at"]  as? Double ?? 0.0)
        self.updatedAt = (data["updated_at"]  as? Double ?? 0.0)
        self.pointCost = (data["point_cost"] as? Double ?? 0.0)
        self.notes = (data["notes"] as? String) ?? ""
        self.itemId = (data["item_id"] as? String) ?? ""
        self.uid = (data["uid"] as? String) ?? ""
    }
}
