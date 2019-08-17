//
//  Stage.swift
//  LinkX
//
//  Created by Rodney Gainous Jr on 7/14/19.
//  Copyright © 2019 CodeSigned. All rights reserved.
//

import Foundation

public struct Stage {
    public var id: String?
    public var name: String
    
    init(data: [String : Any]) {
        self.id = (data["id"] as? String) ?? ""
        self.name = (data["name"] as? String) ?? ""
    }
}
