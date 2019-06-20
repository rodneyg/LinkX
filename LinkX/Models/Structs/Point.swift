
//
//  Point.swift
//  LinkX
//
//  Created by Rodney Gainous Jr on 6/20/19.
//  Copyright © 2019 CodeSigned. All rights reserved.
//

import Foundation

public struct Point {
    public var id: String
    public var value: Double
    public var activity: Activity?
    public var createdAt: String
    
    init(data: [String : Any]) {
        self.id = (data["id"] as? String) ?? ""
        self.value = (data["value"] as? Double) ?? 0.0
        self.createdAt = (data["created_at"] as? String) ?? ""
        
        if let activityData = data["activity"] as? [String : String] {
            self.activity = Activity(data: activityData)
        } else {
            self.activity = nil
        }
    }
}
