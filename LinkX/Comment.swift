//
//  Comment.swift
//  LinkX
//
//  Created by Rodney Gainous Jr on 5/13/19.
//  Copyright © 2019 CodeSigned. All rights reserved.
//

import Foundation

public struct Comment {
    public var id: String
    public var createdAt: Date
    public var comment: String
    public var uid: String
    
    init(data: [String : Any]) {
        self.id = (data["id"] as? String) ?? ""
        
        let secondsFrom1970 = (data["id"]  as? Double ?? 0)
        self.createdAt = Date(timeIntervalSince1970: secondsFrom1970)
        
        self.comment = (data["comment"] as? String) ?? ""
        self.uid = (data["uid"] as? String) ?? ""
    }
}
