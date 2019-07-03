//
//  Activity.swift
//  LinkX
//
//  Created by Rodney Gainous Jr on 6/20/19.
//  Copyright © 2019 CodeSigned. All rights reserved.
//

import Foundation

public struct Activity {
    public var id: String?
    public var name: String
    public var description: String?
    public var points: Double?
    
    init(data: [String : Any]) {
        self.id = (data["id"] as? String) ?? ""
        self.name = (data["name"] as? String) ?? ""
        self.description = (data["description"] as? String)
        self.points = (data["points"] as? Double) ?? 0.0
    }
}

