//
//  Post.swift
//  LinkX
//
//  Created by Rodney Gainous Jr on 7/19/19.
//  Copyright © 2019 CodeSigned. All rights reserved.
//

import Foundation

public struct Post {
    
    var user: User?
    
    var ref: String?
    var id: String?
    var image: String?
    var icon: String?
    var url: String?
    var canonicalUrl: String?
    var title: String?
    var finalUrl: String?
    var uid: String?
    var publicUrl: String?
    var createdAt: Double?
    
    var claps: Int = 0
    var shocked: Int = 0
    var skeptical: Int = 0
    var views: Int = 2
    
    var clappedByCurrentUser = false
    var shockedByCurrentUser = false
    var skepticalByCurrentUser = false

    init(data: [String : Any]) {
        self.init(user: nil, data: data)
    }
    
    init(user: User?, data: [String : Any]) {
        self.user = user
        self.id = data["id"] as? String
        self.image = data["image"] as? String
        self.icon = data["icon"] as? String
        self.url = data["url"] as? String
        self.canonicalUrl = data["canonical_url"] as? String
        self.title = data["title"] as? String
        self.finalUrl = data["final_url"] as? String
        self.views = (data["views"] as? Int) ?? 2
        self.publicUrl = data["public_url"] as? String
        self.uid = data["uid"] as? String
        self.createdAt = data["created_at"] as? Double
    }
}
